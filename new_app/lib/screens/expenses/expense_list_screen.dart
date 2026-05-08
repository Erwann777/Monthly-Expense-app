import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});
  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _filterCategory = 'All';
  String _filterType = 'All'; // 'All', 'expense', 'income'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _filterItems(List<ExpenseModel> items) {
    var filtered = items;

    // Filter by type
    if (_filterType == 'expense') {
      filtered = filtered.where((e) => e.isExpense).toList();
    } else if (_filterType == 'income') {
      filtered = filtered.where((e) => e.isIncome).toList();
    }

    // Filter by category
    if (_filterCategory != 'All') {
      filtered = filtered.where((e) => e.category == _filterCategory).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) =>
        e.title.toLowerCase().contains(query) ||
        e.category.toLowerCase().contains(query) ||
        (e.note?.toLowerCase().contains(query) ?? false) ||
        e.amount.toStringAsFixed(2).contains(query)
      ).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: SafeArea(child: Column(children: [
        _buildHeader(isDark),
        _buildSearchBar(isDark),
        _buildTypeFilter(isDark),
        _buildCategoryFilter(isDark),
        Expanded(child: _buildExpenseList(isDark)),
      ])),
      floatingActionButton: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.cardGradient,
          boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]),
        child: FloatingActionButton(
          onPressed: () { HapticFeedback.mediumImpact(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())); },
          backgroundColor: Colors.transparent, elevation: 0, child: const Icon(Icons.add_rounded, size: 30)),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Transactions', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.darkText : AppTheme.textPrimary, letterSpacing: -0.5)),
        Consumer<ExpenseProvider>(builder: (_, exp, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: AppTheme.accentPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
          child: Text('${exp.monthlyExpenses.length} items', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentPurple)),
        )),
      ]),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10)],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppTheme.darkText : AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
            prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(children: [
        _typeChip('All', 'All', AppTheme.accentPurple, isDark),
        const SizedBox(width: 8),
        _typeChip('expense', 'Expenses', AppTheme.errorRed, isDark),
        const SizedBox(width: 8),
        _typeChip('income', 'Income', AppTheme.accentGreen, isDark),
      ]),
    );
  }

  Widget _typeChip(String type, String label, Color color, bool isDark) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _filterType = type); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? AppTheme.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? AppTheme.darkDivider : AppTheme.divider)),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary))),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    final expCats = AppCategories.categories.map((c) => c.name).toList();
    final incCats = AppCategories.incomeCategories.map((c) => c.name).toList();
    List<String> all;
    if (_filterType == 'income') {
      all = ['All', ...incCats];
    } else if (_filterType == 'expense') {
      all = ['All', ...expCats];
    } else {
      all = ['All', ...expCats, ...incCats];
    }

    return SizedBox(height: 44, child: ListView.builder(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: all.length,
      itemBuilder: (context, index) {
        final cat = all[index]; final isSelected = _filterCategory == cat;
        final catInfo = cat == 'All' ? null : AppCategories.getByName(cat);
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _filterCategory = cat); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? (catInfo?.color ?? AppTheme.accentPurple) : (isDark ? AppTheme.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: isSelected ? Colors.transparent : (isDark ? AppTheme.darkDivider : AppTheme.divider)),
              boxShadow: isSelected ? [BoxShadow(color: (catInfo?.color ?? AppTheme.accentPurple).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (catInfo != null) ...[Text(catInfo.emoji, style: const TextStyle(fontSize: 14)), const SizedBox(width: 6)],
              Text(cat == 'All' ? 'All' : cat, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary))),
            ]),
          ),
        );
      },
    ));
  }

  Widget _buildExpenseList(bool isDark) {
    return Consumer2<ExpenseProvider, AuthProvider>(builder: (context, exp, auth, _) {
      final currency = auth.currentUser?.currency ?? 'USD';
      final items = _filterItems(exp.monthlyExpenses);

      if (items.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.accentPurple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24)),
            child: const Center(child: Text('🔍', style: TextStyle(fontSize: 36)))),
          const SizedBox(height: 16),
          Text('No transactions found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text(_searchQuery.isNotEmpty ? 'Try a different search term' : (_filterCategory == 'All' ? 'Add your first transaction' : 'No items in this category'),
            style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
        ]));
      }

      return ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), itemCount: items.length,
        itemBuilder: (context, index) {
          final expense = items[index]; final cat = AppCategories.getByName(expense.category);
          return Dismissible(
            key: Key('expense_${expense.id}'), direction: DismissDirection.endToStart,
            background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppTheme.errorRed, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28)),
            confirmDismiss: (d) async => await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
              title: Text('Delete ${expense.isIncome ? 'Income' : 'Expense'}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              content: Text('Delete "${expense.title}"?', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed), child: const Text('Delete'))],
            )),
            onDismissed: (_) { exp.deleteExpense(expense.id!);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${expense.title} deleted'), backgroundColor: AppTheme.errorRed)); },
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: expense, isIncome: expense.isIncome))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 2))]),
                child: Row(children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 24)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(expense.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (expense.isIncome)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.accentGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                          child: Text('Income', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.accentGreen)),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Flexible(child: Text(expense.category, style: GoogleFonts.inter(fontSize: 12, color: cat.color, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis, maxLines: 1)),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
                      const SizedBox(width: 8),
                      Text(Formatters.dateRelative(expense.date), style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
                    ]),
                  ])),
                  Flexible(
                    flex: 0,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
                      child: Text('${expense.isIncome ? '+' : '-'} ${Formatters.currency(expense.amount, currency)}',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: expense.isIncome ? AppTheme.accentGreen : AppTheme.errorRed),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      );
    });
  }
}
