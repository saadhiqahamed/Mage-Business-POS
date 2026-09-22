import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/providers/shift_provider.dart';
import '../../../core/providers/shift_totals_provider.dart';
import '../../../core/providers/expense_provider.dart';
import '../../../core/services/z_report_pdf_service.dart';

class CashDrawerScreen extends ConsumerWidget {
  const CashDrawerScreen({super.key});

  void _showStartShiftDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Start Shift', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the starting cash in the drawer:'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Starting Balance (Rs)', prefixIcon: Icon(Icons.money)),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6A51D), foregroundColor: Colors.black),
            onPressed: () {
              final amount = ((double.tryParse(amountController.text) ?? 0) * 100).toInt();
              ref.read(shiftProvider.notifier).startShift(amount);
              Navigator.pop(context);
            },
            child: const Text('Open Drawer'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Add Expense', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Expense Reason (e.g. Tea)'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (Rs)', prefixIcon: Icon(Icons.money_off)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = ((double.tryParse(amountController.text) ?? 0) * 100).toInt();
              if (titleController.text.isNotEmpty && amount > 0) {
                await ref.read(expenseRepositoryProvider).addExpense(
                  title: titleController.text,
                  amountCents: amount,
                  paymentMethod: 'cash',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(shiftExpensesProvider); // Refresh expenses
                }
              }
            },
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }

  Future<void> _endShift(BuildContext context, WidgetRef ref, ShiftState shift, ShiftTotals totals, int expenses) async {
    final shiftEnd = DateTime.now();
    final pdfFile = await ZReportPdfService.generateZReport(
      shiftStart: shift.shiftStartTime!,
      shiftEnd: shiftEnd,
      startingCashCents: shift.startingCashCents,
      totalSalesCents: totals.totalSalesCents,
      cashSalesCents: totals.cashSalesCents,
      totalCostCents: totals.totalCostCents,
      expensesCents: expenses,
      creditReceivedCents: totals.creditReceivedCents,
    );

    if (context.mounted) {
      await ref.read(shiftProvider.notifier).endShift();
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Shift Ended', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
          content: const Text('Z-Report generated successfully! You can now print or share it.'),
          actions: [
            TextButton(
              onPressed: () async {
                final bytes = await pdfFile.readAsBytes();
                await Printing.layoutPdf(onLayout: (_) async => bytes);
              },
              child: const Text('Print Report'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ZReportPdfService.shareReport(pdfFile);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6A51D), foregroundColor: Colors.black),
              child: const Text('Share PDF'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftProvider);

    if (shift.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (!shift.isShiftActive) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        appBar: AppBar(title: const Text('Cash Drawer', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Drawer is closed.', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showStartShiftDialog(context, ref),
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Start Shift (Enter Balance)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6A51D),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              )
            ],
          ),
        ),
      );
    }

    // Shift is active
    final totalsAsync = ref.watch(shiftTotalsProvider);
    final expensesAsync = ref.watch(shiftExpensesProvider(shift.shiftStartTime!));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Cash Drawer (Active Shift)', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: totalsAsync.when(
        data: (totals) => expensesAsync.when(
          data: (expenses) {
            final expectedCash = shift.startingCashCents + totals.cashSalesCents + totals.creditReceivedCents - expenses;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Expected Cash in Drawer', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          'Rs ${(expectedCash / 100).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _RowItem('Starting Balance', shift.startingCashCents),
                _RowItem('(+) Cash Sales', totals.cashSalesCents, color: Colors.green),
                _RowItem('(+) Credit Received', totals.creditReceivedCents, color: Colors.green),
                _RowItem('(-) Expenses', expenses, color: Colors.red),
                const Divider(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _showAddExpenseDialog(context, ref),
                  icon: const Icon(Icons.money_off),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _endShift(context, ref, shift, totals, expenses),
                  icon: const Icon(Icons.print),
                  label: const Text('End Shift & Print Z-Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6A51D),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color? color;

  const _RowItem(this.label, this.amount, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF1A237E))),
          Text(
            'Rs ${(amount / 100).toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF1A237E)),
          ),
        ],
      ),
    );
  }
}
