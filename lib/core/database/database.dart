import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  LocalBusinesses,
  LocalProducts,
  LocalCustomers,
  LocalSales,
  LocalSaleItems,
  LocalCustomerLedgerEntries,
  LocalCustomerPayments,
  LocalExpenses,
  LocalSuppliers,
  LocalSyncOperations,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          await m.addColumn(localProducts, localProducts.supplierName);
          await m.addColumn(localProducts, localProducts.supplierContact);
        }
        if (from < 2) {
          // Add rewardPoints to LocalCustomers
          await m.addColumn(localCustomers, localCustomers.rewardPoints);
          
          // Add reward point columns to LocalSales
          await m.addColumn(localSales, localSales.rewardPointsEarned);
          await m.addColumn(localSales, localSales.rewardPointsRedeemed);
          
          // Add buyingPriceAtSale to LocalSaleItems for profit tracking
          await m.addColumn(localSaleItems, localSaleItems.buyingPriceAtSale);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mage_business_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
