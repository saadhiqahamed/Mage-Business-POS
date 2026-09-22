import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/customer_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Add Customer', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person, color: Color(0xFF1A237E))),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone, color: Color(0xFF1A237E))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6A51D), foregroundColor: Colors.black),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref.read(customerRepositoryProvider).addCustomer(
                  name: nameController.text,
                  phone: phoneController.text.isEmpty ? null : phoneController.text,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final creditAsync = ref.watch(creditCustomersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Customers', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 80, color: Colors.black12),
                  const SizedBox(height: 16),
                  const Text('No customers yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return creditAsync.when(
            data: (creditList) {
              final Map<String, int> pendingBalances = {};
              for (var c in creditList) {
                pendingBalances[c.customer.id] = c.balanceCents;
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final c = customers[index];
                  final pending = pendingBalances[c.id] ?? 0;

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFD6A51D),
                        child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(c.name, style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.phone ?? 'No phone', style: const TextStyle(color: Colors.black54)),
                          if (c.rewardPoints > 0)
                            Text('${c.rewardPoints} reward pts', style: const TextStyle(color: Color(0xFFD6A51D), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: pending > 0
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Credit Due', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text('Rs ${(pending / 100).toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    ),
                  ).animate().fade().slideX();
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D))),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D))),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context, ref),
        backgroundColor: const Color(0xFFD6A51D),
        foregroundColor: Colors.black,
        child: const Icon(Icons.person_add),
      ).animate().scale(),
    );
  }
}
