import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

const _uuid = Uuid();

/// Generates a unique 12-digit barcode number
String generateBarcodeNumber() {
  final ts = DateTime.now().millisecondsSinceEpoch % 1000000; // 6 digits from time
  final rand = (DateTime.now().microsecond * 17 + ts) % 1000000; // 6 digits random
  return '${ts.toString().padLeft(6, '0')}${rand.toString().padLeft(6, '0')}';
}

// ── Watch all products ──────────────────────────────────────────────────────
final productsProvider = StreamProvider<List<LocalProduct>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.localProducts)
        ..where((p) => p.isActive.equals(true))
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();
});

// ── Search products by name or barcode ─────────────────────────────────────
final productSearchProvider =
    StreamProvider.family<List<LocalProduct>, String>((ref, query) {
  final db = ref.watch(databaseProvider);
  if (query.isEmpty) {
    return (db.select(db.localProducts)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }
  return (db.select(db.localProducts)
        ..where((p) =>
            p.isActive.equals(true) &
            (p.name.lower().like('%${query.toLowerCase()}%') |
                p.barcode.lower().like('%${query.toLowerCase()}%'))))
      .watch();
});

// ── Find product by barcode (single lookup) ────────────────────────────────
Future<LocalProduct?> findProductByBarcode(
    AppDatabase db, String barcode) async {
  return (db.select(db.localProducts)
        ..where((p) => p.barcode.equals(barcode) & p.isActive.equals(true))
        ..limit(1))
      .getSingleOrNull();
}

// ── CRUD ───────────────────────────────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepository(db);
});

class ProductRepository {
  final AppDatabase _db;
  ProductRepository(this._db);

  Future<String> addProduct({
    required String name,
    String? categoryId,
    String? supplierName,
    String? supplierContact,
    required int buyingPrice,
    required int sellingPrice,
    required int initialStock,
    String? customBarcode,
    String? sku,
  }) async {
    final id = _uuid.v4();
    final barcode = customBarcode ?? generateBarcodeNumber();

    await _db.into(_db.localProducts).insert(LocalProductsCompanion.insert(
          id: id,
          name: name,
          barcode: Value(barcode),
          categoryId: Value(categoryId),
          sku: Value(sku),
          supplierName: Value(supplierName),
          supplierContact: Value(supplierContact),
          buyingPrice: buyingPrice,
          sellingPrice: sellingPrice,
          currentStock: Value(initialStock),
        ));

    // Queue for cloud sync
    await _queueSync('products', 'insert', id, {
      'id': id,
      'name': name,
      'barcode': barcode,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'current_stock': initialStock,
      'is_active': true,
    });

    return id;
  }

  Future<void> updateStock(String productId, int newStock) async {
    await (_db.update(_db.localProducts)
          ..where((p) => p.id.equals(productId)))
        .write(LocalProductsCompanion(
            currentStock: Value(newStock),
            updatedAt: Value(DateTime.now())));
  }

  Future<void> decreaseStock(String productId, int quantity) async {
    final product = await (_db.select(_db.localProducts)
          ..where((p) => p.id.equals(productId)))
        .getSingle();
    final newStock = product.currentStock - quantity;
    if (newStock >= 0) {
      await updateStock(productId, newStock);
    }
  }

  Future<void> deleteProduct(String productId) async {
    await (_db.update(_db.localProducts)
          ..where((p) => p.id.equals(productId)))
        .write(LocalProductsCompanion(isActive: const Value(false)));
  }

  Future<void> _queueSync(
      String table, String operation, String entityId, Map payload) async {
    await _db.into(_db.localSyncOperations).insert(
        LocalSyncOperationsCompanion.insert(
          id: _uuid.v4(),
          targetTable: table,
          operation: operation,
          entityId: entityId,
          payload: payload.toString(),
        ));
  }
}


