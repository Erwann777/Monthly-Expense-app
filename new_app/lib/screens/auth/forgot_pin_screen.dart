import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database_helper.dart';
import '../../providers/pin_auth_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

/// Forgot PIN screen with two recovery options:
/// 1. Enter backup code to reset PIN
/// 2. Clear all app data and start fresh
class ForgotPinScreen extends StatefulWidget {
  final VoidCallback onPinReset;

  const ForgotPinScreen({super.key, required this.onPinReset});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen>
    with SingleTickerProviderStateMixin {
  final _backupCodeController = TextEditingController();
  String _newPin = '';
  String _confirmPin = '';
  bool _showNewPinEntry = false;
  bool _isConfirmStep = false;
  String? _error;
  bool _isProcessing = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _backupCodeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _verifyBackupCode() async {
    if (_backupCodeController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your backup code.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final provider = context.read<PinAuthProvider>();
    final isValid =
        await provider.service.verifyBackupCode(_backupCodeController.text);

    if (isValid) {
      setState(() {
        _showNewPinEntry = true;
        _isProcessing = false;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'Invalid backup code. Please try again.';
        _isProcessing = false;
      });
    }
  }

  void _onDigitPressed(int digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _error = null;
      if (!_isConfirmStep) {
        if (_newPin.length < 4) {
          _newPin += digit.toString();
          if (_newPin.length == 4) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _isConfirmStep = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit.toString();
          if (_confirmPin.length == 4) {
            _resetPin();
          }
        }
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      if (!_isConfirmStep) {
        if (_newPin.isNotEmpty) {
          _newPin = _newPin.substring(0, _newPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _resetPin() async {
    if (_newPin != _confirmPin) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() {
        _error = 'PINs don\'t match. Try again.';
        _confirmPin = '';
      });
      return;
    }

    setState(() => _isProcessing = true);

    final provider = context.read<PinAuthProvider>();
    final newBackupCode = await provider.resetPinWithBackup(
      _backupCodeController.text,
      _newPin,
    );

    if (newBackupCode != null && mounted) {
      _showNewBackupCodeDialog(newBackupCode);
    } else if (mounted) {
      setState(() {
        _error = 'Failed to reset PIN. Please try again.';
        _isProcessing = false;
      });
    }
  }

  void _showNewBackupCodeDialog(String backupCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.accentGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('PIN Reset!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your new backup code:',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.accentPurple.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    backupCode,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppTheme.accentPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: backupCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup code copied! 📋'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded,
                            size: 14,
                            color: AppTheme.accentPurple
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text('Tap to copy',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.accentPurple
                                    .withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onPinReset();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Continue',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: AppTheme.errorRed, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Clear All Data?',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will permanently delete ALL your data including:',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            _dataItem(Icons.receipt_long_rounded, 'All transactions'),
            _dataItem(Icons.savings_rounded, 'Savings goals'),
            _dataItem(Icons.person_rounded, 'Account information'),
            _dataItem(Icons.lock_rounded, 'PIN & security settings'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded,
                      color: AppTheme.errorRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performClearData();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text('Clear Everything',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dataItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _performClearData() async {
    // Clear PIN data
    final pinProvider = context.read<PinAuthProvider>();
    await pinProvider.clearAllAuthData();

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Close and delete the database
    await DatabaseHelper.instance.close();

    if (mounted) {
      // Restart the app by pushing to a fresh state
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      if (mounted) {
        // Navigate to a fresh start — the app will detect no PIN + no user
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showNewPinEntry) {
      return _buildNewPinScreen();
    }
    return _buildBackupCodeScreen();
  }

  Widget _buildBackupCodeScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 24),
                // Header
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      size: 36, color: AppTheme.accentOrange),
                ),
                const SizedBox(height: 20),
                Text('Forgot PIN',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(height: 8),
                Text(
                  'Enter your backup code to reset your PIN',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Backup code input card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Backup Code',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          )),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _backupCodeController,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0000-0000-0000',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 22,
                            color: Colors.white.withValues(alpha: 0.2),
                            letterSpacing: 2,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\-]')),
                          LengthLimitingTextInputFormatter(14),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _verifyBackupCode,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text('Verify Code',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Divider
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.1))),
                  ],
                ),
                const SizedBox(height: 32),
                // Clear data option
                GestureDetector(
                  onTap: _showClearDataDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.errorRed.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete_forever_rounded,
                              color: AppTheme.errorRed, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Clear All Data',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.errorRed,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                'Delete everything and start fresh',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: AppTheme.errorRed.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewPinScreen() {
    final currentPin = _isConfirmStep ? _confirmPin : _newPin;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        if (_isConfirmStep) {
                          _isConfirmStep = false;
                          _confirmPin = '';
                        } else {
                          _showNewPinEntry = false;
                          _newPin = '';
                        }
                        _error = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _isConfirmStep
                      ? Icons.verified_rounded
                      : Icons.lock_reset_rounded,
                  size: 36,
                  color: AppTheme.accentGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isConfirmStep ? 'Confirm New PIN' : 'Create New PIN',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirmStep
                    ? 'Re-enter your new PIN'
                    : 'Choose a 4-digit PIN',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 36),
              // PIN Dots
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final offset = sin(_shakeAnimation.value * pi * 4) * 12;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final isFilled = i < currentPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: isFilled ? 20 : 16,
                      height: isFilled ? 20 : 16,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentGreen
                                      .withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              // Error
              SizedBox(
                height: 24,
                child: _error != null
                    ? Text(_error!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w500,
                        ))
                    : const SizedBox.shrink(),
              ),
              const Spacer(),
              // Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    for (int row = 0; row < 4; row++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _buildNewPinKeypadRow(row),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNewPinKeypadRow(int row) {
    if (row < 3) {
      return List.generate(3, (col) {
        final digit = row * 3 + col + 1;
        return _ForgotPinKeyButton(
          label: '$digit',
          onTap: () => _onDigitPressed(digit),
        );
      });
    } else {
      return [
        const _ForgotPinKeyButton(label: '', isSpecial: true),
        _ForgotPinKeyButton(
          label: '0',
          onTap: () => _onDigitPressed(0),
        ),
        _ForgotPinKeyButton(
          icon: Icons.backspace_outlined,
          onTap: _onBackspace,
          isSpecial: true,
        ),
      ];
    }
  }
}

class _ForgotPinKeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSpecial;

  const _ForgotPinKeyButton({
    this.label,
    this.icon,
    this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty =
        (label == null || label!.isEmpty) && icon == null;
    return GestureDetector(
      onTap: isEmpty ? null : onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isEmpty
              ? Colors.transparent
              : Colors.white.withValues(alpha: isSpecial ? 0.03 : 0.07),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon,
                  color: Colors.white.withValues(alpha: 0.7), size: 22)
              : Text(
                  label ?? '',
                  style: GoogleFonts.inter(
                    fontSize: isSpecial ? 20 : 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: isEmpty ? 0 : 0.85),
                  ),
                ),
        ),
      ),
    );
  }
}
