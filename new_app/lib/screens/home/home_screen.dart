import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/category_model.dart';
import '../../models/currency_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/sparkline_chart.dart';
import '../expenses/add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _greetController;
  late Animation<double> _greetFade;
  late Animation<Offset> _greetSlide;

  @override
  void initState() {
    super.initState();
    _greetController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _greetFade = CurvedAnimation(parent: _greetController, curve: Curves.easeOut);
    _greetSlide = Tween<Offset>(begin: const Offset(-0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _greetController, curve: Curves.easeOutCubic));
    _greetController.forward();
  }

  @override
  void dispose() { _greetController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: Consumer2<AuthProvider, ExpenseProvider>(
        builder: (context, auth, expenses, _) {
          final user = auth.currentUser;
          if (user == null) return const SizedBox.shrink();
          final currency = user.currency;
          final budget = user.monthlyBudget;
          final spent = expenses.monthlyTotal;
          final income = expenses.monthlyIncomeTotal;
          final remaining = (budget - spent).clamp(0.0, double.infinity);
          final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
          final trend = expenses.spendingTrend;
          final momChange = expenses.monthOverMonthChange;

          Color ringColor;
          String statusEmoji;
          if (progress < 0.5) { ringColor = AppTheme.accentGreen; statusEmoji = '🎯'; }
          else if (progress < 0.8) { ringColor = AppTheme.accentOrange; statusEmoji = '⚠️'; }
          else { ringColor = AppTheme.errorRed; statusEmoji = '❗'; }

          return Column(
            children: [
              // Fixed header - stays at top
              _buildHeader(context, user.displayName, user.avatarEmoji, user.profilePhotoPath, currency, isDark),
              // Scrollable content below
              Expanded(
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildIncomeExpenseSummary(context, currency, spent, income, isDark)),
                    SliverToBoxAdapter(child: _buildBudgetRing(context, currency, spent, budget, remaining, progress, ringColor, statusEmoji, isDark)),
                    SliverToBoxAdapter(child: _buildSparklineSection(context, expenses, currency, momChange, trend, isDark)),
                    SliverToBoxAdapter(child: _buildSmartInsight(context, trend, remaining, budget, currency, isDark)),
                    SliverToBoxAdapter(child: _buildQuickActions(context, isDark)),
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text('Recent Transactions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkText : AppTheme.textPrimary)),
                    )),
                    if (expenses.todayExpenses.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyState(isDark))
                    else
                      SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                        final expense = expenses.todayExpenses[index];
                        final cat = AppCategories.getByName(expense.category);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: _buildTransactionTile(context, cat, expense.title, expense.category,
                            Formatters.currency(expense.amount, currency), Formatters.time(expense.date), expense.isIncome, isDark),
                        );
                      }, childCount: expenses.todayExpenses.length > 5 ? 5 : expenses.todayExpenses.length)),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String? emoji, String? profilePhotoPath, String currency, bool isDark) {
    final currencyInfo = AppCurrencies.getByCode(currency);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: FadeTransition(
            opacity: _greetFade,
            child: SlideTransition(
              position: _greetSlide,
              child: Row(children: [
                // Profile photo or emoji avatar
                _buildAvatar(name, emoji, profilePhotoPath),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(Formatters.greeting(), style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 2),
                  Text('$name 👋', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(currencyInfo.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(currency, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? emoji, String? profilePhotoPath) {
    if (profilePhotoPath != null && File(profilePhotoPath).existsSync()) {
      return Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          image: DecorationImage(image: FileImage(File(profilePhotoPath)), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: 54, height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Center(child: Text(emoji ?? (name.isNotEmpty ? name[0].toUpperCase() : '?'),
        style: GoogleFonts.inter(fontSize: emoji != null ? 26 : 24, fontWeight: FontWeight.w700, color: Colors.white))),
    );
  }

  Widget _buildIncomeExpenseSummary(BuildContext ctx, String currency, double expense, double income, bool isDark) {
    final net = income - expense;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(children: [
        Expanded(child: _summaryCard('Income', Formatters.currencyCompact(income, currency), Icons.arrow_downward_rounded, AppTheme.accentGreen, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Expense', Formatters.currencyCompact(expense, currency), Icons.arrow_upward_rounded, AppTheme.errorRed, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Balance', Formatters.currencyCompact(net.abs(), currency), Icons.account_balance_rounded, 
          net >= 0 ? AppTheme.accentGreen : AppTheme.errorRed, isDark, prefix: net >= 0 ? '+' : '-')),
      ]),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color, bool isDark, {String prefix = ''}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text('$prefix$value', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkText : AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildBudgetRing(BuildContext ctx, String currency, double spent, double budget, double remaining, double progress, Color ringColor, String emoji, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: isDark ? AppTheme.neumorphicDecoration(isDark: true) : AppTheme.glassDecoration(),
        child: Row(children: [
          AnimatedProgressRing(
            progress: progress,
            size: 130,
            strokeWidth: 14,
            progressColor: ringColor,
            gradient: LinearGradient(colors: [ringColor, ringColor.withValues(alpha: 0.6)]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 2),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkText : AppTheme.textPrimary)),
              Text('used', style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
            ]),
          ),
          const SizedBox(width: 24),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _miniStat('Budget', Formatters.currencyCompact(budget, currency), AppTheme.accentBlue, isDark),
            const SizedBox(height: 14),
            _miniStat('Spent', Formatters.currencyCompact(spent, currency), AppTheme.accentPurple, isDark),
            const SizedBox(height: 14),
            _miniStat('Remaining', Formatters.currencyCompact(remaining, currency), AppTheme.accentGreen, isDark),
          ])),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, bool isDark) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkText : AppTheme.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }

  Widget _buildSparklineSection(BuildContext ctx, ExpenseProvider exp, String currency, double mom, Map<String, dynamic> trend, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: isDark ? AppTheme.neumorphicDecoration(isDark: true) : AppTheme.glassDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('7-Day Spending', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkText : AppTheme.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: mom > 0 ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(mom > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: mom > 0 ? AppTheme.errorRed : AppTheme.accentGreen),
                const SizedBox(width: 4),
                Flexible(child: Text('${mom > 0 ? '+' : ''}${mom.toStringAsFixed(0)}% vs last mo', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: mom > 0 ? AppTheme.errorRed : AppTheme.accentGreen),
                  overflow: TextOverflow.ellipsis, maxLines: 1)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          SparklineChart(data: exp.sparklineData, height: 70, lineColor: AppTheme.accentPurple, fillColor: AppTheme.accentPurple.withValues(alpha: 0.15)),
        ]),
      ),
    );
  }

  Widget _buildSmartInsight(BuildContext ctx, Map<String, dynamic> trend, double remaining, double budget, String currency, bool isDark) {
    final direction = trend['direction'] as String;
    final daysLeft = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day;
    final dailyBudget = daysLeft > 0 ? remaining / daysLeft : 0.0;
    String msg; IconData icon; Color color;
    if (direction == 'increasing') { msg = 'Spending is trending up. Try to limit to ${Formatters.currency(dailyBudget, currency)}/day'; icon = Icons.trending_up_rounded; color = AppTheme.accentOrange; }
    else if (direction == 'decreasing') { msg = 'Great job! Spending is going down 🎉'; icon = Icons.trending_down_rounded; color = AppTheme.accentGreen; }
    else { msg = 'You can spend ${Formatters.currency(dailyBudget, currency)}/day for the rest of the month'; icon = Icons.lightbulb_rounded; color = AppTheme.accentBlue; }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkText : AppTheme.textPrimary, height: 1.4))),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(children: [
        Expanded(child: _actionChip(context, 'Add Expense', Icons.remove_rounded, AppTheme.cardGradient,
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())))),
        const SizedBox(width: 12),
        Expanded(child: _actionChip(context, 'Add Income', Icons.add_rounded, AppTheme.greenGradient,
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen(isIncome: true))))),
      ]),
    );
  }

  Widget _actionChip(BuildContext ctx, String label, IconData icon, LinearGradient grad, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: grad.colors.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8),
          Flexible(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            overflow: TextOverflow.ellipsis, maxLines: 1)),
        ]),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext ctx, ExpenseCategory cat, String title, String category, String amount, String time, bool isIncome, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 22)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(category, style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
        ])),
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.35),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text('${isIncome ? '+' : '-'} $amount', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isIncome ? AppTheme.accentGreen : AppTheme.errorRed))),
              const SizedBox(height: 3),
              Text(time, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.accentPurple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24)),
          child: const Center(child: Text('💸', style: TextStyle(fontSize: 36)))),
        const SizedBox(height: 16),
        Text('No transactions today', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Text('Tap + to add your first transaction', style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
      ]),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.cardGradient,
        boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]),
      child: FloatingActionButton(
        onPressed: () { HapticFeedback.mediumImpact(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())); },
        backgroundColor: Colors.transparent, elevation: 0, child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

}
