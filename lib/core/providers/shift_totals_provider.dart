import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import 'shift_provider.dart';

class ShiftTotals {
  final int totalSalesCents;
  final int cashSalesCents;
  final int totalCostCents;
  final int creditReceivedCents;

  ShiftTotals({
    required this.totalSalesCents,
    required this.cashSalesCents,
    required this.totalCostCents,
    required this.creditReceivedCents,
  });
}

final shiftTotalsProvider = StreamProvider<ShiftTotals>((ref) {
  final shift = ref.watch(shiftProvider);
  if (!shift.isShiftActive || shift.shiftStartTime == null) {
    return Stream.value(ShiftTotals(totalSalesCents: 0, cashSalesCents: 0, totalCostCents: 0, creditReceivedCents: 0));
  }

  final db = ref.watch(databaseProvider);
  final start = shift.shiftStartTime!;

  // Watch for any changes in sales, items, or payments
  return db.customSelect(
    'SELECT 1',
    readsFrom: {db.localSales, db.localSaleItems, db.localCustomerPayments},
  ).watch().asyncMap((_) async {
    // Sales totals
    final sales = await (db.select(db.localSales)
          ..where((s) => s.createdAt.isBiggerOrEqualValue(start)))
        .get();
    
    int totalSales = 0;
    int cashSales = 0;
    for (var s in sales) {
      totalSales += s.totalAmount;
      if (s.paymentMethod == 'cash') {
        cashSales += s.totalAmount;
      }
    }

    // Cost calculations
    int totalCost = 0;
    final query = db.select(db.localSaleItems).join([
      innerJoin(db.localSales, db.localSales.id.equalsExp(db.localSaleItems.saleId))
    ])..where(db.localSales.createdAt.isBiggerOrEqualValue(start));
    
    final rows = await query.get();
    for (final row in rows) {
      final item = row.readTable(db.localSaleItems);
      totalCost += item.buyingPriceAtSale * item.quantity;
    }

    // Credit payments received
    final payments = await (db.select(db.localCustomerPayments)
          ..where((p) => p.createdAt.isBiggerOrEqualValue(start))
          ..where((p) => p.paymentMethod.equals('cash')))
        .get();
    
    int creditReceived = payments.fold<int>(0, (sum, p) => sum + p.amount);

    return ShiftTotals(
      totalSalesCents: totalSales,
      cashSalesCents: cashSales,
      totalCostCents: totalCost,
      creditReceivedCents: creditReceived,
    );
  });
});
