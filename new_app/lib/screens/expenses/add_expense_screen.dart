import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../../models/currency_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense;
  final bool isIncome;
  const AddExpenseScreen({super.key, this.expense, this.isIncome = false});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _selectedCategory;
  late bool _isIncome;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.isIncome;
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    if (isEditing) {
      final e = widget.expense!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(2);
      _noteController.text = e.note ?? '';
      _selectedCategory = e.category;
      _selectedDate = e.date;
      _selectedTime = TimeOfDay.fromDateTime(e.date);
      _isIncome = e.isIncome;
    } else {
      _selectedCategory = _isIncome
          ? AppCategories.incomeCategories.first.name
          : AppCategories.categories.first.name;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<ExpenseCategory> get _currentCategories =>
      _isIncome ? AppCategories.incomeCategories : AppCategories.categories;

  void _switchType(bool income) {
    setState(() {
      _isIncome = income;
      _selectedCategory = _currentCategories.first.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthProvider>();
    final expProvider = context.read<ExpenseProvider>();
    final userId = auth.currentUser!.id!;
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);

    final expense = ExpenseModel(
      id: widget.expense?.id,
      userId: userId,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      type: _isIncome ? 'income' : 'expense',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: date,
      walletId: widget.expense?.walletId,
      receiptPath: widget.expense?.receiptPath,
      isHidden: widget.expense?.isHidden ?? false,
    );

    bool success;
    if (isEditing) {
      success = await expProvider.updateExpense(expense);
    } else {
      success = await expProvider.addExpense(expense);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditing
            ? '${_isIncome ? 'Income' : 'Expense'} updated! ✅'
            : '${_isIncome ? 'Income' : 'Expense'} added! ✅'),
        backgroundColor: AppTheme.accentGreen,
      ));
    }
  }

  Future<void> _deleteExpense() async {
    if (!isEditing) return;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      title: Text('Delete ${_isIncome ? 'Income' : 'Expense'}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      content: Text('Are you sure you want to delete "${widget.expense!.title}"?', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
          child: const Text('Delete'),
        ),
      ],
    ));
    if (confirmed == true && mounted) {
      final success = await context.read<ExpenseProvider>().deleteExpense(widget.expense!.id!);
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.expense!.title} deleted'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.read<AuthProvider>();
    final currencySymbol = auth.currentUser != null ? AppCurrencies.getByCode(auth.currentUser!.currency).symbol : '\$';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(isEditing ? 'Edit ${_isIncome ? 'Income' : 'Expense'}' : 'Add ${_isIncome ? 'Income' : 'Expense'}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
            child: Icon(Icons.arrow_back_rounded, size: 20, color: isDark ? AppTheme.darkText : AppTheme.textPrimary)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_rounded, size: 20, color: AppTheme.errorRed)),
              onPressed: _deleteExpense,
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Income/Expense toggle
              _buildTypeToggle(isDark),
              const SizedBox(height: 20),
              _buildAmountSection(currencySymbol),
              const SizedBox(height: 28),
              _buildSectionLabel('Title', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController, textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isIncome ? 'e.g. Monthly salary' : 'e.g. Lunch at café',
                  prefixIcon: Icon(Icons.edit_rounded, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('Category', isDark),
              const SizedBox(height: 12),
              _buildCategoryGrid(isDark),
              const SizedBox(height: 24),
              _buildSectionLabel('Date & Time', isDark),
              const SizedBox(height: 12),
              _buildDateTimeRow(context, isDark),
              const SizedBox(height: 24),
              _buildSectionLabel('Note (Optional)', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController, maxLines: 3, textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: 'Add a note...', prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.note_rounded, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted))),
              ),
              const SizedBox(height: 36),
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isIncome ? AppTheme.accentGreen : AppTheme.accentPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    elevation: 4, shadowColor: (_isIncome ? AppTheme.accentGreen : AppTheme.accentPurple).withValues(alpha: 0.4)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(isEditing ? Icons.check_rounded : Icons.add_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(isEditing ? 'Update ${_isIncome ? 'Income' : 'Expense'}' : 'Add ${_isIncome ? 'Income' : 'Expense'}',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => _switchType(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: !_isIncome ? AppTheme.errorRed : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: !_isIncome ? [BoxShadow(color: AppTheme.errorRed.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.arrow_upward_rounded, size: 18, color: !_isIncome ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
              const SizedBox(width: 6),
              Text('Expense', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                color: !_isIncome ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted))),
            ]),
          ),
        )),
        Expanded(child: GestureDetector(
          onTap: () => _switchType(true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _isIncome ? AppTheme.accentGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isIncome ? [BoxShadow(color: AppTheme.accentGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.arrow_downward_rounded, size: 18, color: _isIncome ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted)),
              const SizedBox(width: 6),
              Text('Income', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                color: _isIncome ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted))),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _buildAmountSection(String symbol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: _isIncome ? AppTheme.greenGradient : AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        boxShadow: [BoxShadow(color: (_isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(children: [
        Text('How much?', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(symbol, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(width: 4),
          Flexible(
            child: TextFormField(
              controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
              decoration: InputDecoration(hintText: '0.00',
                hintStyle: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.3)),
                filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                errorStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
              validator: (v) { if (v == null || v.isEmpty) return 'Enter amount'; final val = double.tryParse(v); if (val == null || val <= 0) return 'Invalid'; return null; },
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(text, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.textPrimary));
  }

  Widget _buildCategoryGrid(bool isDark) {
    return Wrap(spacing: 10, runSpacing: 10,
      children: _currentCategories.map((cat) {
        final isSelected = _selectedCategory == cat.name;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = cat.name); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? cat.color.withValues(alpha: 0.15) : (isDark ? AppTheme.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: isSelected ? cat.color : (isDark ? AppTheme.darkDivider : AppTheme.divider), width: isSelected ? 2 : 1),
              boxShadow: isSelected ? [BoxShadow(color: cat.color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(cat.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? cat.color : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary))),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeRow(BuildContext context, bool isDark) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () async { final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (date != null) setState(() => _selectedDate = date); },
        child: Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.divider)),
          child: Row(children: [Icon(Icons.calendar_today_rounded, size: 20, color: _isIncome ? AppTheme.accentGreen : AppTheme.accentPurple), const SizedBox(width: 10),
            Text(Formatters.dateShort(_selectedDate), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.textPrimary))])),
      )),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: () async { final time = await showTimePicker(context: context, initialTime: _selectedTime);
          if (time != null) setState(() => _selectedTime = time); },
        child: Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: isDark ? AppTheme.darkDivider : AppTheme.divider)),
          child: Row(children: [Icon(Icons.access_time_rounded, size: 20, color: _isIncome ? AppTheme.accentGreen : AppTheme.accentPurple), const SizedBox(width: 10),
            Text(_selectedTime.format(context), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText : AppTheme.textPrimary))])),
      )),
    ]);
  }
}
