import 'package:drift/drift.dart';

mixin SyncableTable on Table {
  TextColumn get id => text()(); // UUID
  TextColumn get businessId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending, synced, failed
}

class LocalBusinesses extends Table with SyncableTable {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get phoneNumber => text()();
  TextColumn get address => text().nullable()();
  TextColumn get townCity => text().nullable()();
  TextColumn get defaultCurrency => text().withDefault(const Constant('LKR'))();
  BoolColumn get allowNegativeStock => boolean().withDefault(const Constant(false))();
}

class LocalProducts extends Table with SyncableTable {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get buyingPrice => integer()(); // stored in cents
  IntColumn get sellingPrice => integer()(); // stored in cents
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
  IntColumn get reorderLevel => integer().withDefault(const Constant(0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get supplierName => text().nullable()();
  TextColumn get supplierContact => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class LocalCustomers extends Table with SyncableTable {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get rewardPoints => integer().withDefault(const Constant(0))(); // New Loyalty Points column
}

class LocalSales extends Table with SyncableTable {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get customerId => text().nullable()();
  IntColumn get totalAmount => integer()(); // stored in cents (Final amount after discount)
  IntColumn get discount => integer().withDefault(const Constant(0))(); // Normal discount
  IntColumn get receivedAmount => integer()(); // stored in cents
  TextColumn get paymentMethod => text()(); // cash, card, credit
  TextColumn get status => text().withDefault(const Constant('completed'))();
  
  // Loyalty Points for this transaction
  IntColumn get rewardPointsEarned => integer().withDefault(const Constant(0))();
  IntColumn get rewardPointsRedeemed => integer().withDefault(const Constant(0))();
}

class LocalSaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()(); // stored in cents
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()(); // stored in cents
  
  // Storing buyingPrice at the time of sale to accurately calculate profit later even if product price changes
  IntColumn get buyingPriceAtSale => integer().withDefault(const Constant(0))(); 
  
  @override
  Set<Column> get primaryKey => {id};
}

class LocalCustomerLedgerEntries extends Table with SyncableTable {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get customerId => text()();
  TextColumn get saleId => text().nullable()();
  TextColumn get paymentId => text().nullable()();
  IntColumn get amount => integer()(); // positive for credit, negative for payment
  TextColumn get entryType => text()(); // sale, payment, adjustment
}

class LocalCustomerPayments extends Table with SyncableTable {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get customerId => text()();
  IntColumn get amount => integer()(); // stored in cents
  TextColumn get paymentMethod => text()();
  TextColumn get note => text().nullable()();
}

class LocalExpenses extends Table with SyncableTable {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get title => text()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get amount => integer()(); // stored in cents
  TextColumn get paymentMethod => text()();
  TextColumn get note => text().nullable()();
}

class LocalSuppliers extends Table with SyncableTable {
  @override
  Set<Column> get primaryKey => {id};
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
}

class LocalSyncOperations extends Table {
  TextColumn get id => text()();
  TextColumn get targetTable => text()();
  TextColumn get operation => text()(); // insert, update, delete
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON representation
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}
