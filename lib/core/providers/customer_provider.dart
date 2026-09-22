import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

const _uuid = Uuid();

// â”€â”€ Watch all customers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final customersProvider = StreamProvider<List<LocalCustomer>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.localCustomers)
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();
});

// â”€â”€ Customers with outstanding credit balance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final creditCustomersProvider =
    FutureProvider<List<CustomerCredit>>((ref) async {
  final db = ref.watch(databaseProvider);
  final customers = await db.select(db.localCustomers).get();
  final result = <CustomerCredit>[];

  for (final customer in customers) {
    final entries = await (db.select(db.localCustomerLedgerEntries)
          ..where((e) => e.customerId.equals(customer.id)))
        .get();
    final balance = entries.fold<int>(0, (sum, e) => sum + e.amount);
    if (balance > 0) {
      result.add(CustomerCredit(customer: customer, balanceCents: balance));
    }
  }

  result.sort((a, b) => b.balanceCents.compareTo(a.balanceCents));
  return result;
});

class CustomerCredit {
  final LocalCustomer customer;
  final int balanceCents;
  CustomerCredit({required this.customer, required this.balanceCents});
}

// â”€â”€ Customer repository â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerRepository(db);
});

class CustomerRepository {
  final AppDatabase _db;
  CustomerRepository(this._db);

  Future<String> addCustomer({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.localCustomers).insert(
          LocalCustomersCompanion.insert(
            id: id,
            name: name,
            phone: Value(phone),
            address: Value(address),
            notes: Value(notes),
          ),
        );
    return id;
  }

  Future<int> getCustomerBalance(String customerId) async {
    final entries = await (db.select(_db.localCustomerLedgerEntries)
          ..where((e) => e.customerId.equals(customerId)))
        .get();
    return entries.fold<int>(0, (sum, e) => sum + e.amount);
  }

  AppDatabase get db => _db;

  Future<void> recordPayment({
    required String customerId,
    required int amountCents,
    required String paymentMethod,
    String? note,
  }) async {
    final paymentId = _uuid.v4();
    await _db.into(_db.localCustomerPayments).insert(
          LocalCustomerPaymentsCompanion.insert(
            id: paymentId,
            customerId: customerId,
            amount: amountCents,
            paymentMethod: paymentMethod,
            note: Value(note),
          ),
        );

    // Negative ledger entry = payment received (reduces debt)
    await _db.into(_db.localCustomerLedgerEntries).insert(
          LocalCustomerLedgerEntriesCompanion.insert(
            id: _uuid.v4(),
            customerId: customerId,
            paymentId: Value(paymentId),
            amount: -amountCents,
            entryType: 'payment',
          ),
        );
  }
}

