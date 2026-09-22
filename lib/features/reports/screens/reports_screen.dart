import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/sales_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../sales/screens/receipt_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalsAsync = ref.watch(salesTotalsProvider);
    final recentAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Advanced Analytics', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD6A51D),
          labelColor: const Color(0xFFD6A51D),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Daily Trend'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard
          totalsAsync.when(
            data: (totals) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCard(
                  title: "Today's Revenue",
                  amount: totals.todayTotal,
                  profit: totals.todayProfit,
                  count: totals.todayCount,
                  color: Colors.blueAccent,
                  icon: Icons.today,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'This Week',
                  amount: totals.weekTotal,
                  profit: totals.weekProfit,
                  color: Colors.greenAccent,
                  icon: Icons.date_range,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'This Month',
                  amount: totals.monthTotal,
                  profit: totals.monthProfit,
                  count: totals.monthCount,
                  color: Colors.purpleAccent,
                  icon: Icons.calendar_month,
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D))),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),

          // Daily Trend
          recentAsync.when(
            data: (sales) {
              final Map<int, double> dailyTotals = {};
              final now = DateTime.now();
              for (int i = 6; i >= 0; i--) {
                dailyTotals[now.subtract(Duration(days: i)).day] = 0;
              }
              for (final s in sales) {
                if (s.createdAt.isAfter(now.subtract(const Duration(days: 7)))) {
                  dailyTotals[s.createdAt.day] = (dailyTotals[s.createdAt.day] ?? 0) + (s.totalAmount / 100);
                }
              }
              final spots = dailyTotals.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('7-Day Revenue Trend', style: TextStyle(color: Color(0xFF1A237E), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                            ),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: const Color(0xFFD6A51D),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFFD6A51D).withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D))),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),

          // History
          recentAsync.when(
            data: (sales) {
              if (sales.isEmpty) return const Center(child: Text('No sales history', style: TextStyle(color: Colors.grey)));
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: sales.length,
                itemBuilder: (ctx, i) {
                  final s = sales[i];
                  final time = '${s.createdAt.hour.toString().padLeft(2, '0')}:${s.createdAt.minute.toString().padLeft(2, '0')}';
                  final date = '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}';
                  final changeCents = s.paymentMethod == 'cash' && s.receivedAmount > s.totalAmount
                      ? s.receivedAmount - s.totalAmount
                      : 0;
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () async {
                        showDialog(
                          context: ctx,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D))),
                        );
                        final items = await ref.read(salesRepositoryProvider).getSaleItems(s.id);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => ReceiptScreen(
                                saleId: s.id,
                                items: items,
                                totalCents: s.totalAmount,
                                receivedAmountCents: s.receivedAmount,
                                paymentMethod: s.paymentMethod,
                                customerName: null,
                                cardDigits: null,
                                rewardPointsEarned: s.rewardPointsEarned,
                                rewardPointsRedeemed: s.rewardPointsRedeemed,
                              ),
                            ),
                          );
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor: s.paymentMethod == 'cash'
                            ? Colors.green.withOpacity(0.15)
                            : s.paymentMethod == 'card'
                                ? Colors.blue.withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                        child: Icon(
                          s.paymentMethod == 'cash' ? Icons.money : s.paymentMethod == 'card' ? Icons.credit_card : Icons.pending,
                          color: s.paymentMethod == 'cash' ? Colors.green : s.paymentMethod == 'card' ? Colors.blue : Colors.orange,
                          size: 18,
                        ),
                      ),
                      title: Text('Rs ${(s.totalAmount / 100).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$date at $time • ${s.paymentMethod.toUpperCase()}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          if (changeCents > 0)
                            Text('Change: Rs ${(changeCents / 100).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 11)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (s.rewardPointsEarned > 0) Text('+${s.rewardPointsEarned} pts', style: const TextStyle(color: Colors.green, fontSize: 10)),
                          if (s.rewardPointsRedeemed > 0) Text('-${s.rewardPointsRedeemed} pts', style: const TextStyle(color: Colors.red, fontSize: 10)),
                          const Icon(Icons.receipt_long, color: Color(0xFF1A237E), size: 16),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D))),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int amount;
  final int profit;
  final int? count;
  final Color color;
  final IconData icon;

  const _StatCard({required this.title, required this.amount, required this.profit, this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${(amount / 100).toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF1A237E), fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text('Profit: Rs ${(profit / 100).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (count != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('$count transactions', style: const TextStyle(color: Colors.black38, fontSize: 11)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
