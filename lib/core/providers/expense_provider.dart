import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import 'package:drift/drift.dart';

const _uuid = Uuid();

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepository(db);
});

class ExpenseRepository {
  final AppDatabase _db;
  ExpenseRepository(this._db);

  Future<String> addExpense({
    required String title,
    required int amountCents,
    String paymentMethod = 'cash',
    String? note,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.localExpenses).insert(
      LocalExpensesCompanion.insert(
        id: id,
        title: title,
        amount: amountCents,
        paymentMethod: paymentMethod,
        note: Value(note),
      ),
    );
    return id;
  }
}

// Provider to get total expenses for the current shift
final shiftExpensesProvider = StreamProvider.family<int, DateTime>((ref, shiftStart) {
  final db = ref.watch(databaseProvider);
  
  return db.customSelect(
    'SELECT 1',
    readsFrom: {db.localExpenses},
  ).watch().asyncMap((_) async {
    final rows = await (db.select(db.localExpenses)
          ..where((e) => e.createdAt.isBiggerOrEqualValue(shiftStart))
          ..where((e) => e.paymentMethod.equals('cash')))
        .get();
    return rows.fold<int>(0, (sum, e) => sum + e.amount);
  });
});
