import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/pin_auth_provider.dart';
import '../../utils/app_theme.dart';
import 'forgot_pin_screen.dart';

/// Lock screen requiring PIN or biometric to unlock.
class PinLockScreen extends StatefulWidget {
  final void Function(BuildContext context) onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  bool _isVerifying = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _lockoutTimer;

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

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Setup lockout timer on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLockoutTimer();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockoutTimer() {
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final provider = context.read<PinAuthProvider>();
      provider.refreshLockout();
    });
  }


  void _onDigitPressed(int digit) {
    final provider = context.read<PinAuthProvider>();
    if (provider.isLockedOut || _isVerifying) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (_pin.length < 4) {
        _pin += digit.toString();
      }
    });

    if (_pin.length == 4) {
      _tryVerify();
    }
  }

  void _onBackspace() {
    final provider = context.read<PinAuthProvider>();
    if (provider.isLockedOut || _isVerifying) return;

    HapticFeedback.selectionClick();
    setState(() {
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _tryVerify() async {
    if (_isVerifying) return;

    setState(() => _isVerifying = true);
    final provider = context.read<PinAuthProvider>();
    final result = await provider.verifyPin(_pin);

    if (result) {
      HapticFeedback.mediumImpact();
      if (mounted) widget.onUnlocked(context);
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() => _pin = '');
    }

    if (mounted) setState(() => _isVerifying = false);
  }

  void _navigateToForgotPin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPinScreen(
          onPinReset: () {
            Navigator.of(context).pop();
            widget.onUnlocked(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const SizedBox(height: 50),
                // ─── Header ───
                _buildHeader(),
                const SizedBox(height: 36),
                // ─── PIN Dots ───
                Consumer<PinAuthProvider>(
                  builder: (_, provider, __) {
                    return AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final offset =
                            sin(_shakeAnimation.value * pi * 4) * 12;
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: _buildPinDots(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // ─── Error / Lockout ───
                _buildStatusArea(),
                const Spacer(),

                // ─── Keypad ───
                _buildKeypad(),
                const SizedBox(height: 12),
                // ─── Forgot PIN ───
                _buildForgotPinButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentPurple.withValues(alpha: 0.3),
                AppTheme.accentBlue.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.accentPurple.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome Back',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your PIN to unlock',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isFilled = i < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
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
                      color: AppTheme.accentPurple.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildStatusArea() {
    return Consumer<PinAuthProvider>(
      builder: (_, provider, __) {
        if (provider.isLockedOut && provider.remainingLockout != null) {
          final secs = provider.remainingLockout!.inSeconds;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_rounded,
                    color: AppTheme.errorRed, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Locked out. Try again in ${secs}s',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.error != null && !provider.isLockedOut) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              provider.error!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFF6B6B),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return const SizedBox(height: 20);
      },
    );
  }


  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
        return _DarkKeypadButton(
          label: '$digit',
          onTap: () => _onDigitPressed(digit),
        );
      });
    } else {
      return [
        const _DarkKeypadButton(label: '', isSpecial: true),
        _DarkKeypadButton(
          label: '0',
          onTap: () => _onDigitPressed(0),
        ),
        _DarkKeypadButton(
          icon: Icons.backspace_outlined,
          onTap: _onBackspace,
          isSpecial: true,
        ),
      ];
    }
  }

  Widget _buildForgotPinButton() {
    return TextButton(
      onPressed: _navigateToForgotPin,
      child: Text(
        'Forgot PIN?',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _DarkKeypadButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSpecial;

  const _DarkKeypadButton({
    this.label,
    this.icon,
    this.onTap,
    this.isSpecial = false,
  });

  @override
  State<_DarkKeypadButton> createState() => _DarkKeypadButtonState();
}

class _DarkKeypadButtonState extends State<_DarkKeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEmpty =
        (widget.label == null || widget.label!.isEmpty) && widget.icon == null;
    return GestureDetector(
      onTapDown: isEmpty ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isEmpty
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            },
      onTapCancel: isEmpty ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isEmpty
              ? Colors.transparent
              : _isPressed
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(
                      alpha: widget.isSpecial ? 0.03 : 0.07),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: widget.icon != null
              ? Icon(widget.icon,
                  color: Colors.white.withValues(alpha: 0.7), size: 22)
              : Text(
                  widget.label ?? '',
                  style: GoogleFonts.inter(
                    fontSize: widget.isSpecial ? 20 : 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.white
                        .withValues(alpha: isEmpty ? 0 : 0.85),
                  ),
                ),
        ),
      ),
    );
  }
}
