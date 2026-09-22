import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

const _uuid = Uuid();

// Ã¢â€â‚¬Ã¢â€â‚¬ Recent sales stream Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
final recentSalesProvider = StreamProvider<List<LocalSale>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.localSales)
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
        ..limit(50))
      .watch();
});

// Ã¢â€â‚¬Ã¢â€â‚¬ Sales totals (with Profit Tracking) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
final salesTotalsProvider = FutureProvider<SalesTotals>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();

  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  Future<int> sumSince(DateTime since) async {
    final rows = await (db.select(db.localSales)
          ..where((s) => s.createdAt.isBiggerOrEqualValue(since)))
        .get();
    return rows.fold<int>(0, (sum, s) => sum + s.totalAmount);
  }
  
  // Calculate profit
  Future<int> profitSince(DateTime since) async {
    // We join Sales and SaleItems to find profit: (unitPrice - buyingPriceAtSale) * quantity
    final query = db.select(db.localSaleItems).join([
      innerJoin(db.localSales, db.localSales.id.equalsExp(db.localSaleItems.saleId))
    ])..where(db.localSales.createdAt.isBiggerOrEqualValue(since));
    
    final rows = await query.get();
    int totalProfit = 0;
    for (final row in rows) {
      final item = row.readTable(db.localSaleItems);
      final profit = ((item.unitPrice - item.discount) - item.buyingPriceAtSale) * item.quantity;
      totalProfit += profit;
    }
    return totalProfit;
  }

  Future<int> countSince(DateTime since) async {
    final rows = await (db.select(db.localSales)
          ..where((s) => s.createdAt.isBiggerOrEqualValue(since)))
        .get();
    return rows.length;
  }

  return SalesTotals(
    todayTotal: await sumSince(todayStart),
    weekTotal: await sumSince(weekStart),
    monthTotal: await sumSince(monthStart),
    todayProfit: await profitSince(todayStart),
    weekProfit: await profitSince(weekStart),
    monthProfit: await profitSince(monthStart),
    todayCount: await countSince(todayStart),
    monthCount: await countSince(monthStart),
  );
});

class SalesTotals {
  final int todayTotal;   
  final int weekTotal;    
  final int monthTotal;   
  final int todayProfit;
  final int weekProfit;
  final int monthProfit;
  final int todayCount;
  final int monthCount;

  const SalesTotals({
    required this.todayTotal,
    required this.weekTotal,
    required this.monthTotal,
    required this.todayProfit,
    required this.weekProfit,
    required this.monthProfit,
    required this.todayCount,
    required this.monthCount,
  });
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Sales repository Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SalesRepository(db);
});

class SalesRepository {
  final AppDatabase _db;
  SalesRepository(this._db);

  Future<List<CartItem>> getSaleItems(String saleId) async {
    final rows = await (_db.select(_db.localSaleItems)..where((i) => i.saleId.equals(saleId))).get();
    final items = <CartItem>[];
    for (final row in rows) {
      final product = await (_db.select(_db.localProducts)..where((p) => p.id.equals(row.productId))).getSingleOrNull();
      items.add(CartItem(
        productId: row.productId,
        name: product?.name ?? 'Unknown Product',
        price: row.unitPrice,
        discount: row.discount,
        quantity: row.quantity,
      ));
    }
    return items;
  }

  /// Creates a sale with its line items. Returns the sale ID.
  Future<String> createSale({
    required List<CartItem> cartItems,
    required int receivedAmount,
    required String paymentMethod,
    String? customerId,
    int discount = 0,
    int rewardPointsEarned = 0,
    int rewardPointsRedeemed = 0,
  }) async {
    final saleId = _uuid.v4();
    // Base total minus redeemed points (1 point = Rs 1 = 100 cents)
    int total = cartItems.fold<int>(
        0, (sum, item) => sum + ((item.price - item.discount) * item.quantity));
    total -= (rewardPointsRedeemed * 100);
    if (total < 0) total = 0;

    await _db.transaction(() async {
      await _db.into(_db.localSales).insert(
            LocalSalesCompanion.insert(
              id: saleId,
              totalAmount: total,
              receivedAmount: receivedAmount,
              paymentMethod: paymentMethod,
              customerId: Value(customerId),
              discount: Value(discount),
              rewardPointsEarned: Value(rewardPointsEarned),
              rewardPointsRedeemed: Value(rewardPointsRedeemed),
            ),
          );

      for (final item in cartItems) {
        // Fetch buying price
        final product = await (_db.select(_db.localProducts)..where((p) => p.id.equals(item.productId))).getSingleOrNull();
        final buyingPrice = product?.buyingPrice ?? 0;

        final itemTotal = (item.price - item.discount) * item.quantity;
        await _db.into(_db.localSaleItems).insert(
              LocalSaleItemsCompanion.insert(
                id: _uuid.v4(),
                saleId: saleId,
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: item.price,
                discount: Value(item.discount),
                total: itemTotal,
                buyingPriceAtSale: Value(buyingPrice),
              ),
            );
      }

      // Update Customer Loyalty Points
      if (customerId != null && (rewardPointsEarned > 0 || rewardPointsRedeemed > 0)) {
        final cust = await (_db.select(_db.localCustomers)..where((c) => c.id.equals(customerId))).getSingleOrNull();
        if (cust != null) {
          final newPoints = (cust.rewardPoints) - rewardPointsRedeemed + rewardPointsEarned;
          await (_db.update(_db.localCustomers)..where((c) => c.id.equals(customerId))).write(
            LocalCustomersCompanion(rewardPoints: Value(newPoints > 0 ? newPoints : 0))
          );
        }
      }

      // If credit sale, add ledger entry
      if (paymentMethod == 'credit' && customerId != null) {
        await _db.into(_db.localCustomerLedgerEntries).insert(
              LocalCustomerLedgerEntriesCompanion.insert(
                id: _uuid.v4(),
                customerId: customerId,
                saleId: Value(saleId),
                amount: total,
                entryType: 'sale',
              ),
            );
      }
    });

    return saleId;
  }
}

class CartItem {
  final String productId;
  final String name;
  final int price;       // in cents
  final int discount;    // in cents
  final int quantity;
  final int maxStock;    // 0 = no limit enforced

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.discount = 0,
    this.quantity = 1,
    this.maxStock = 0,
  });
}


