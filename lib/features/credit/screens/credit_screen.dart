import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/customer_provider.dart';

class CreditScreen extends ConsumerWidget {
  const CreditScreen({super.key});

  void _showPaymentDialog(BuildContext context, WidgetRef ref, String customerId, String name, int maxAmount) {
    final amountController = TextEditingController(text: (maxAmount / 100).toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Record Payment: $name', style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Amount (Rs)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6A51D),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final amount = ((double.tryParse(amountController.text) ?? 0) * 100).toInt();
              if (amount > 0) {
                await ref.read(customerRepositoryProvider).recordPayment(
                  customerId: customerId,
                  amountCents: amount,
                  paymentMethod: 'cash',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Settle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditAsync = ref.watch(creditCustomersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Credit & Ledger', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: creditAsync.when(
        data: (creditList) {
          if (creditList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No outstanding credit!', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: creditList.length,
            itemBuilder: (context, index) {
              final item = creditList[index];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD6A51D),
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  title: Text(item.customer.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  subtitle: Text(item.customer.phone ?? 'No phone', style: const TextStyle(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Pending', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(
                            'Rs ${(item.balanceCents / 100).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6A51D),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => _showPaymentDialog(context, ref, item.customer.id, item.customer.name, item.balanceCents),
                        child: const Text('Pay'),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D))),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
