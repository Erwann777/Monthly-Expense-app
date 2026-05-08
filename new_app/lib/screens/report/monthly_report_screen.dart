import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/category_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_report_generator.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});
  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  int _touchedIndex = -1;
  String _reportView = 'expense';
  String _activePreset = 'This Month';
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRange());
  }

  void _loadRange() {
    context.read<ExpenseProvider>().loadDateRangeExpenses(_rangeStart, _rangeEnd);
  }

  void _setPreset(String label, DateTime start, DateTime end) {
    setState(() { _activePreset = label; _rangeStart = start; _rangeEnd = end; });
    _loadRange();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.accentPurple)), child: child!),
    );
    if (picked != null) _setPreset('Custom', picked.start, picked.end);
  }

  Future<void> _exportPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final auth = context.read<AuthProvider>();
      final exp = context.read<ExpenseProvider>();
      await PdfReportGenerator.generateAndShare(
        userName: auth.currentUser?.displayName ?? 'User',
        currency: auth.currentUser?.currency ?? 'USD',
        startDate: _rangeStart, endDate: _rangeEnd,
        totalExpense: exp.rangeExpenseTotal, totalIncome: exp.rangeIncomeTotal,
        expenseCategoryTotals: exp.rangeCategoryTotals,
        incomeCategoryTotals: exp.rangeIncomeCategoryTotals,
        transactions: exp.rangeExpenses,
        budget: auth.currentUser?.monthlyBudget,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: AppTheme.errorRed));
    }
    if (mounted) setState(() => _isGeneratingPdf = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: SafeArea(child: Column(children: [
        _buildHeader(isDark),
        _buildDatePresets(isDark),
        _buildDateRangeDisplay(isDark),
        Expanded(child: Consumer2<ExpenseProvider, AuthProvider>(
          builder: (context, exp, auth, _) {
            final currency = auth.currentUser?.currency ?? 'USD';
            final budget = auth.currentUser?.monthlyBudget ?? 0;
            return CustomScrollView(physics: const ClampingScrollPhysics(), slivers: [
              SliverToBoxAdapter(child: _buildSummaryCards(exp, currency, budget, isDark)),
              SliverToBoxAdapter(child: _buildViewToggle(isDark)),
              SliverToBoxAdapter(child: _buildChartSection(exp, isDark)),
              SliverToBoxAdapter(child: _buildCategoryBreakdown(exp, currency, isDark)),
              SliverToBoxAdapter(child: _buildTransactionList(exp, currency, isDark)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ]);
          },
        )),
      ])),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Reports', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.darkText : AppTheme.textPrimary, letterSpacing: -0.5)),
        GestureDetector(
          onTap: _isGeneratingPdf ? null : _exportPdf,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(gradient: AppTheme.cardGradient, borderRadius: BorderRadius.circular(100),
              boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _isGeneratingPdf
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(_isGeneratingPdf ? 'Generating...' : 'Export PDF',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ])),
        ),
      ]));
  }

  Widget _buildDatePresets(bool isDark) {
    final now = DateTime.now();
    final presets = <String, List<DateTime>>{
      'Today': [DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day)],
      'This Week': [DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)), DateTime(now.year, now.month, now.day)],
      'This Month': [DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0)],
      'Last 3 Months': [DateTime(now.year, now.month - 2, 1), DateTime(now.year, now.month + 1, 0)],
      'This Year': [DateTime(now.year, 1, 1), DateTime(now.year, 12, 31)],
    };
    return SizedBox(height: 44, child: ListView(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ...presets.entries.map((e) => _presetChip(e.key, e.value[0], e.value[1], isDark)),
        _presetChip('Custom', _rangeStart, _rangeEnd, isDark, isCustom: true),
      ],
    ));
  }

  Widget _presetChip(String label, DateTime start, DateTime end, bool isDark, {bool isCustom = false}) {
    final isActive = _activePreset == label;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); isCustom ? _pickCustomRange() : _setPreset(label, start, end); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentPurple : (isDark ? AppTheme.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? AppTheme.darkDivider : AppTheme.divider)),
          boxShadow: isActive ? [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (isCustom) ...[Icon(Icons.date_range_rounded, size: 14, color: isActive ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)), const SizedBox(width: 4)],
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary))),
        ]),
      ),
    );
  }

  Widget _buildDateRangeDisplay(bool isDark) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: GestureDetector(
        onTap: _pickCustomRange,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10)]),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.accentPurple),
            const SizedBox(width: 10),
            Expanded(child: Text('${Formatters.date(_rangeStart)}  →  ${Formatters.date(_rangeEnd)}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.textPrimary))),
            Icon(Icons.edit_calendar_rounded, size: 18, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
          ])),
      ));
  }

  Widget _buildSummaryCards(ExpenseProvider exp, String currency, double budget, bool isDark) {
    final spent = exp.rangeExpenseTotal;
    final income = exp.rangeIncomeTotal;
    final net = income - spent;
    return Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: AppTheme.cardGradient, borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(children: [
          Text('Net Balance', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text('${net >= 0 ? '+' : ''}${Formatters.currency(net.abs(), currency)}',
            style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _summaryItem('Income', Formatters.currency(income, currency), Icons.arrow_downward_rounded, AppTheme.accentGreen)),
            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
            Expanded(child: _summaryItem('Expense', Formatters.currency(spent, currency), Icons.arrow_upward_rounded, AppTheme.errorRed)),
          ]),
          if (budget > 0) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.savings_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18), const SizedBox(width: 8),
                Flexible(child: Text('Budget: ${Formatters.currency((budget - spent).clamp(0, double.infinity).toDouble(), currency)} left',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  overflow: TextOverflow.ellipsis, maxLines: 1)),
              ])),
          ],
        ])));
  }

  Widget _summaryItem(String label, String value, IconData icon, Color color) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: color), const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
      ]),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown,
        child: Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
    ]);
  }

  Widget _buildViewToggle(bool isDark) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          _toggleBtn('expense', 'Expenses', Icons.arrow_upward_rounded, AppTheme.errorRed, isDark),
          _toggleBtn('income', 'Income', Icons.arrow_downward_rounded, AppTheme.accentGreen, isDark),
        ])));
  }

  Widget _toggleBtn(String val, String label, IconData icon, Color color, bool isDark) {
    final sel = _reportView == val;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _reportView = val),
      child: AnimatedContainer(duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: sel ? color : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: sel ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
            color: sel ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted))),
        ]))));
  }

  Widget _buildChartSection(ExpenseProvider exp, bool isDark) {
    final catTotals = _reportView == 'income' ? exp.rangeIncomeCategoryTotals : exp.rangeCategoryTotals;
    if (catTotals.isEmpty) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Column(children: [
          const Text('📊', style: TextStyle(fontSize: 48)), const SizedBox(height: 12),
          Text('No ${_reportView == 'income' ? 'income' : 'expense'} data for this period',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
        ])));
    }
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_reportView == 'income' ? 'Income' : 'Spending'} by Category',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkText : AppTheme.textPrimary)),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: PieChart(PieChartData(
            sectionsSpace: 3, centerSpaceRadius: 50,
            pieTouchData: PieTouchData(touchCallback: (event, response) {
              setState(() { if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) { _touchedIndex = -1; return; }
                _touchedIndex = response.touchedSection!.touchedSectionIndex; }); }),
            sections: _buildPieSections(catTotals),
          ))),
        ])));
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> catTotals) {
    final total = catTotals.values.fold(0.0, (a, b) => a + b);
    final entries = catTotals.entries.toList();
    return List.generate(entries.length, (i) {
      final entry = entries[i]; final cat = AppCategories.getByName(entry.key);
      final pct = total > 0 ? (entry.value / total * 100) : 0;
      final isTouched = i == _touchedIndex;
      return PieChartSectionData(
        color: cat.color, value: entry.value, title: '${pct.toStringAsFixed(0)}%',
        radius: isTouched ? 35.0 : 28.0,
        titleStyle: GoogleFonts.inter(fontSize: isTouched ? 14.0 : 11.0, fontWeight: FontWeight.w700, color: Colors.white),
        badgeWidget: isTouched ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(8)),
          child: Text(entry.key, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white))) : null,
        badgePositionPercentageOffset: 1.6,
      );
    });
  }

  Widget _buildCategoryBreakdown(ExpenseProvider exp, String currency, bool isDark) {
    final catTotals = _reportView == 'income' ? exp.rangeIncomeCategoryTotals : exp.rangeCategoryTotals;
    if (catTotals.isEmpty) return const SizedBox.shrink();
    final total = catTotals.values.fold(0.0, (a, b) => a + b);
    return Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Category Breakdown', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkText : AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ...catTotals.entries.map((entry) {
            final cat = AppCategories.getByName(entry.key);
            final pct = total > 0 ? entry.value / total : 0.0;
            return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(children: [
              Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 18)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Flexible(child: Text(entry.key, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Flexible(flex: 0, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(Formatters.currency(entry.value, currency), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkText : AppTheme.textPrimary)))),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(value: pct, minHeight: 6,
                      backgroundColor: isDark ? AppTheme.darkDivider : AppTheme.divider.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(cat.color))),
                ])),
              ]),
            ]));
          }),
        ])));
  }

  Widget _buildTransactionList(ExpenseProvider exp, String currency, bool isDark) {
    final items = _reportView == 'income' ? exp.rangeIncomeOnly : exp.rangeExpenseOnly;
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text('${_reportView == 'income' ? 'Income' : 'Expense'} Transactions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkText : AppTheme.textPrimary))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: (_reportView == 'income' ? AppTheme.accentGreen : AppTheme.errorRed).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
              child: Text('${items.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _reportView == 'income' ? AppTheme.accentGreen : AppTheme.errorRed))),
          ]),
          const SizedBox(height: 12),
          ...items.take(15).map((expense) {
            final cat = AppCategories.getByName(expense.category);
            return Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 16)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(expense.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(Formatters.dateRelative(expense.date), style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted), overflow: TextOverflow.ellipsis),
                ])),
                const SizedBox(width: 8),
                Flexible(flex: 0, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text('${expense.isIncome ? '+' : '-'}${Formatters.currency(expense.amount, currency)}',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: expense.isIncome ? AppTheme.accentGreen : AppTheme.errorRed)))),
              ]));
          }),
          if (items.length > 15) Padding(padding: const EdgeInsets.only(top: 4),
            child: Center(child: Text('+ ${items.length - 15} more in PDF export', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.accentPurple, fontWeight: FontWeight.w500)))),
        ])));
  }
}
