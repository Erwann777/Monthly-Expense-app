import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/goals_provider.dart';
import '../home/home_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../report/monthly_report_screen.dart';
import '../settings/settings_screen.dart';
import '../../utils/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _screens = const [HomeScreen(), ExpenseListScreen(), MonthlyReportScreen(), SettingsScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        final uid = auth.currentUser!.id!;
        context.read<ExpenseProvider>()..setUserId(uid)..loadExpenses();
        context.read<GoalsProvider>()..setUserId(uid)..loadGoals();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', isDark),
                _buildNavItem(1, Icons.receipt_long_rounded, 'Expenses', isDark),
                _buildNavItem(2, Icons.bar_chart_rounded, 'Reports', isDark),
                _buildNavItem(3, Icons.settings_rounded, 'Settings', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _currentIndex = index); },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPurple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? AppTheme.accentPurple : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted), size: 24),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ]),
      ),
    );
  }
}
