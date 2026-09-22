import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/sales_provider.dart';
import '../../../core/providers/customer_provider.dart';
import '../../sales/screens/billing_screen.dart';
import '../../credit/screens/credit_screen.dart';
import '../../inventory/screens/stock_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../../core/providers/shift_totals_provider.dart';
import '../../../core/providers/shift_provider.dart';

class _DashboardHome extends ConsumerWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(salesTotalsProvider);
    final creditAsync = ref.watch(creditCustomersProvider);
    final shift = ref.watch(shiftProvider);
    
    int todaySales = 0;
    int weekSales = 0;
    int activeCredit = 0;
    
    totalsAsync.whenData((t) {
      todaySales = t.todayTotal;
      weekSales = t.weekTotal;
    });
    
    creditAsync.whenData((list) {
      activeCredit = list.fold(0, (sum, item) => sum + item.balanceCents);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            // "?"? Top App Bar Area "?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mage Business', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      Text('Welcome back!', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Color(0xFF1A237E)),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // "?"? High-Level Stats Card "?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today\'s Sales', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      'Rs ${(todaySales / 100).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MiniStat(label: 'This Week', amount: weekSales),
                        _MiniStat(label: 'Pending Credit', amount: activeCredit),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
            ),

            const SizedBox(height: 32),

            // "?"? Quick Actions Grid "?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.point_of_sale,
                          label: 'New Sale',
                          sublabel: 'Start billing',
                          color: const Color(0xFFD6A51D),
                          textColor: Colors.black,
                          onTap: () => context.push('/billing'),
                          large: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _ActionTile(
                              icon: Icons.inventory_2_rounded,
                              label: 'Stock',
                              sublabel: 'Manage',
                              color: const Color(0xFF1565C0),
                              onTap: () => context.push('/stock'),
                            ),
                            const SizedBox(height: 12),
                            _ActionTile(
                              icon: Icons.people_alt_rounded,
                              label: 'Customers',
                              sublabel: 'View all',
                              color: const Color(0xFF283593),
                              onTap: () => context.push('/customers'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Credit',
                          sublabel: 'Pending payments',
                          color: const Color(0xFF3949AB),
                          onTap: () => context.push('/credit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.bar_chart_rounded,
                          label: 'Reports',
                          sublabel: 'Analytics',
                          color: const Color(0xFF4527A0),
                          onTap: () => context.push('/reports'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.point_of_sale_rounded,
                          label: 'Cash Drawer',
                          sublabel: 'Shift & Z-Report',
                          color: const Color(0xFF00695C),
                          onTap: () => context.push('/drawer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
            ),

            const SizedBox(height: 28),

            // "?"? Tips Card "?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?"?
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFD6A51D).withOpacity(0.15), const Color(0xFFD6A51D).withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD6A51D).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFD6A51D), size: 36),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Loyalty Program Active', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                          Text('Customers earn 1 pt per Rs 100 spent', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 400.ms),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int amount;

  const _MiniStat({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            'Rs ${(amount / 100).toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool large;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: large ? 128 : 58,
          padding: const EdgeInsets.all(16),
          child: large
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: textColor, size: 32),
                    const SizedBox(height: 8),
                    Text(label, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(sublabel, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)),
                  ],
                )
              : Row(
                  children: [
                    Icon(icon, color: textColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(sublabel, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: textColor.withOpacity(0.5), size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    _DashboardHome(),
    BillingScreen(),
    CreditScreen(),
    StockScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1A237E),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Sales'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Credit'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          ],
        ),
      ),
    );
  }
}
