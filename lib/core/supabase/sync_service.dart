import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import 'supabase_config.dart';

/// Syncs local SQLite data to Supabase when the internet is available.
/// The app works 100% offline — syncing happens in the background.
class SyncService {
  final AppDatabase _db;
  StreamSubscription? _connectivitySub;

  SyncService(this._db);

  void start() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final hasInternet = results.any((r) => r != ConnectivityResult.none);
      if (hasInternet && SupabaseConfig.isConfigured) {
        await _syncPendingOperations();
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  Future<void> _syncPendingOperations() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final supabase = Supabase.instance.client;
      final pending = await _db.select(_db.localSyncOperations).get();

      for (final op in pending) {
        try {
          final payload = jsonDecode(op.payload) as Map<String, dynamic>;
          final table = op.targetTable;

          if (op.operation == 'insert' || op.operation == 'update') {
            await supabase.from(table).upsert(payload);
          } else if (op.operation == 'delete') {
            await supabase.from(table).delete().eq('id', op.entityId);
          }

          // Remove from sync queue on success
          await (_db.delete(_db.localSyncOperations)
                ..where((t) => t.id.equals(op.id)))
              .go();
        } catch (_) {
          // Increment attempt count on failure
          await (_db.update(_db.localSyncOperations)
                ..where((t) => t.id.equals(op.id)))
              .write(LocalSyncOperationsCompanion(
                  attemptCount: Value(op.attemptCount + 1)));
        }
      }
    } catch (_) {
      // Silently fail if Supabase is unreachable
    }
  }

  /// Call this to trigger an immediate sync attempt
  Future<void> syncNow() async {
    final result = await Connectivity().checkConnectivity();
    if (result.any((r) => r != ConnectivityResult.none)) {
      await _syncPendingOperations();
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(db);
  service.start();
  ref.onDispose(() => service.dispose());
  return service;
});
