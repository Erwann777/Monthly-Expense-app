import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/pin_auth_provider.dart';
import '../../utils/app_theme.dart';

/// Screen shown on first launch to set up a PIN.
class PinSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const PinSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  String? _error;
  int _pinLength = 4;
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
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(int digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _error = null;
      if (!_isConfirmStep) {
        if (_pin.length < _pinLength) {
          _pin += digit.toString();
          if (_pin.length == _pinLength) {
            // Auto-advance to confirm step
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _isConfirmStep = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < _pinLength) {
          _confirmPin += digit.toString();
          if (_confirmPin.length == _pinLength) {
            _validateAndSetPin();
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
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _validateAndSetPin() async {
    if (_pin != _confirmPin) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() {
        _error = 'PINs don\'t match. Try again.';
        _confirmPin = '';
      });
      return;
    }

    final provider = context.read<PinAuthProvider>();
    final backupCode = await provider.setupPin(_pin);

    if (mounted) {
      _showBackupCodeDialog(backupCode);
    }
  }

  void _showBackupCodeDialog(String backupCode) {
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
              child: const Icon(
                Icons.shield_rounded,
                color: AppTheme.accentGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Backup Code',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save this backup code securely. You\'ll need it to recover your account if you forget your PIN.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withValues(alpha: 0.08),
                    AppTheme.accentBlue.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    backupCode,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppTheme.accentPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: backupCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup code copied! 📋'),
                          backgroundColor: AppTheme.accentGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: AppTheme.accentPurple.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to copy',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.accentPurple.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'If you lose this code, you\'ll need to clear all app data to reset your PIN.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
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
                widget.onSetupComplete();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'I\'ve Saved It',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPinLengthChanged(int length) {
    HapticFeedback.selectionClick();
    setState(() {
      _pinLength = length;
      _pin = '';
      _confirmPin = '';
      _isConfirmStep = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirmStep ? _confirmPin : _pin;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF6B21A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // ─── Header ───
              _buildHeader(),
              const SizedBox(height: 12),
              // ─── PIN Dots ───
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final offset = sin(_shakeAnimation.value * pi * 4) * 12;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: _buildPinDots(currentPin),
              ),
              const SizedBox(height: 16),
              // ─── Error ───
              _buildErrorText(),
              const Spacer(),
              // ─── Keypad ───
              _buildKeypad(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              _isConfirmStep ? Icons.verified_rounded : Icons.lock_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isConfirmStep ? 'Confirm Your PIN' : 'Create Your PIN',
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
                ? 'Re-enter your PIN to confirm'
                : 'Choose a 4-digit PIN to secure your app',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPinDots(String currentPin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (i) {
        final isFilled = i < currentPin.length;
        final isActive = i == currentPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 20 : (isActive ? 18 : 16),
          height: isFilled ? 20 : (isActive ? 18 : 16),
          decoration: BoxDecoration(
            color: isFilled
                ? Colors.white
                : Colors.white.withValues(alpha: isActive ? 0.3 : 0.15),
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  )
                : null,
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildErrorText() {
    return SizedBox(
      height: 32,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _error != null
            ? Text(
                _error!,
                key: ValueKey(_error),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFF6B6B),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildKeypadRow(row),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildKeypadRow(int row) {
    if (row < 3) {
      return List.generate(3, (col) {
        final digit = row * 3 + col + 1;
        return _KeypadButton(
          label: '$digit',
          onTap: () => _onDigitPressed(digit),
        );
      });
    } else {
      // Bottom row: back, 0, backspace
      return [
        _KeypadButton(
          label: _isConfirmStep ? '←' : '',
          onTap: _isConfirmStep
              ? () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isConfirmStep = false;
                    _confirmPin = '';
                    _error = null;
                  });
                }
              : null,
          isSpecial: true,
        ),
        _KeypadButton(label: '0', onTap: () => _onDigitPressed(0)),
        _KeypadButton(
          icon: Icons.backspace_outlined,
          onTap: _onBackspace,
          isSpecial: true,
        ),
      ];
    }
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSpecial;

  const _KeypadButton({
    this.label,
    this.icon,
    this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = (label == null || label!.isEmpty) && icon == null;
    return GestureDetector(
      onTap: isEmpty ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isEmpty
              ? Colors.transparent
              : Colors.white.withValues(alpha: isSpecial ? 0.06 : 0.12),
          shape: BoxShape.circle,
          border: isEmpty
              ? null
              : Border.all(
                  color: Colors.white.withValues(
                    alpha: isSpecial ? 0.08 : 0.15,
                  ),
                ),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24)
              : Text(
                  label ?? '',
                  style: GoogleFonts.inter(
                    fontSize: isSpecial ? 22 : 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: isEmpty ? 0 : 0.9),
                  ),
                ),
        ),
      ),
    );
  }
}
