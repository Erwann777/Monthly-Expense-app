import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/pin_auth_provider.dart';
import '../../models/currency_model.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/pin_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final user = auth.currentUser;
            if (user == null) return const SizedBox.shrink();
            return Column(
              children: [
                // Scrollable settings
                Expanded(
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(isDark)),
                      SliverToBoxAdapter(
                        child: _buildProfileCard(
                          context,
                          user.displayName,
                          user.username,
                          user.avatarEmoji,
                          user.profilePhotoPath,
                          isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSectionLabel('Appearance', isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildThemeToggle(context, isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSectionLabel('Preferences', isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.attach_money_rounded,
                          color: AppTheme.accentGreen,
                          title: 'Currency',
                          subtitle:
                              '${AppCurrencies.getByCode(user.currency).flag} ${user.currency} — ${AppCurrencies.getByCode(user.currency).name}',
                          onTap: () => _showCurrencyPicker(context),
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppTheme.accentBlue,
                          title: 'Monthly Budget',
                          subtitle:
                              '${AppCurrencies.getByCode(user.currency).symbol}${user.monthlyBudget.toStringAsFixed(0)}',
                          onTap: () => _showBudgetDialog(context),
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.person_rounded,
                          color: AppTheme.accentPurple,
                          title: 'Display Name',
                          subtitle: user.displayName,
                          onTap: () => _showNameDialog(context),
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.camera_alt_rounded,
                          color: AppTheme.accentPink,
                          title: 'Profile Photo',
                          subtitle: user.profilePhotoPath != null
                              ? 'Photo set ✅'
                              : 'Tap to upload',
                          onTap: () => _showPhotoOptions(context),
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.emoji_emotions_rounded,
                          color: AppTheme.accentOrange,
                          title: 'Avatar Emoji',
                          subtitle: user.avatarEmoji ?? 'Tap to set',
                          onTap: () => _showAvatarPicker(context),
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSectionLabel('Security', isDark),
                      ),
                      SliverToBoxAdapter(
                        child: Consumer<PinAuthProvider>(
                          builder: (ctx, pinAuth, _) {
                            if (pinAuth.isPinSet) {
                              return _buildSettingsTile(
                                context,
                                icon: Icons.pin_rounded,
                                color: AppTheme.accentPurple,
                                title: 'Change PIN',
                                subtitle: 'Update your security PIN',
                                onTap: () => _showChangePinDialog(context),
                                isDark: isDark,
                              );
                            } else {
                              return _buildSettingsTile(
                                context,
                                icon: Icons.lock_outline_rounded,
                                color: AppTheme.accentPurple,
                                title: 'Setup PIN',
                                subtitle: 'Enable PIN security',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PinSetupScreen(
                                        onSetupComplete: () {
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'PIN setup successfully! 🔒',
                                              ),
                                              backgroundColor:
                                                  AppTheme.accentGreen,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                isDark: isDark,
                              );
                            }
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Consumer<PinAuthProvider>(
                          builder: (ctx, pinAuth, _) {
                            if (!pinAuth.isPinSet)
                              return const SizedBox.shrink();
                            return Column(
                              children: [
                                _buildSettingsTile(
                                  context,
                                  icon: Icons.key_rounded,
                                  color: AppTheme.accentOrange,
                                  title: 'Backup Code',
                                  subtitle: 'View your recovery backup code',
                                  onTap: () => _showBackupCodeDialog(context),
                                  isDark: isDark,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSectionLabel('Data', isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.help_outline_rounded,
                          color: AppTheme.accentTeal,
                          title: 'Help & Support',
                          subtitle: 'Get help and contact us',
                          onTap: () => _showHelpInfo(context),
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.info_outline_rounded,
                          color: AppTheme.accentBlue,
                          title: 'About',
                          subtitle: 'ExpenseTracker — Built with ❤️',
                          onTap: () => _showAboutInfo(context),
                          isDark: isDark,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
                // Sign out button fixed at bottom
                _buildSignOutButton(context, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        'Settings',
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.darkText : AppTheme.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    String name,
    String username,
    String? emoji,
    String? profilePhotoPath,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showPhotoOptions(context),
              child: _buildProfileAvatar(name, emoji, profilePhotoPath),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@$username',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showPhotoOptions(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(
    String name,
    String? emoji,
    String? profilePhotoPath,
  ) {
    if (profilePhotoPath != null && File(profilePhotoPath).existsSync()) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          image: DecorationImage(
            image: FileImage(File(profilePhotoPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          emoji ?? (name.isNotEmpty ? name[0].toUpperCase() : '?'),
          style: GoogleFonts.inter(
            fontSize: emoji != null ? 26 : 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppTheme.accentPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dark Mode',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkText : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isDark ? 'Currently dark' : 'Currently light',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isDark,
              activeTrackColor: AppTheme.accentPurple,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? AppTheme.errorRed
                            : (isDark
                                  ? AppTheme.darkText
                                  : AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showLogoutDialog(context);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.errorRed.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Security Dialogs ───

  void _showChangePinDialog(BuildContext context) {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          'Change PIN',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                counterText: '',
              ),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'New PIN (4 digits)',
                counterText: '',
              ),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                counterText: '',
              ),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
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
              if (newPinCtrl.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be exactly 4 digits'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }
              if (newPinCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New PINs don\'t match'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }
              final pinAuth = context.read<PinAuthProvider>();
              final ok = await pinAuth.changePin(
                oldPinCtrl.text,
                newPinCtrl.text,
              );
              if (ok && context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN changed successfully! 🔒'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Current PIN is incorrect'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showBackupCodeDialog(BuildContext context) async {
    final pinAuth = context.read<PinAuthProvider>();
    final code = await pinAuth.getBackupCode();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.key_rounded,
              color: AppTheme.accentOrange,
              size: 24,
            ),
            const SizedBox(width: 10),
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
              'Use this code to reset your PIN if you forget it.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.accentPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                code ?? 'No backup code found',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppTheme.accentPurple,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (code != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied! 📋'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy to clipboard'),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ───

  void _showPhotoOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Profile Photo',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _photoOption(
                      context,
                      'Camera',
                      Icons.camera_alt_rounded,
                      AppTheme.accentPurple,
                      isDark,
                      () async {
                        Navigator.pop(ctx);
                        await _pickPhoto(context, ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _photoOption(
                      context,
                      'Gallery',
                      Icons.photo_library_rounded,
                      AppTheme.accentBlue,
                      isDark,
                      () async {
                        Navigator.pop(ctx);
                        await _pickPhoto(context, ImageSource.gallery);
                      },
                    ),
                  ),
                  if (auth.currentUser?.profilePhotoPath != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _photoOption(
                        context,
                        'Remove',
                        Icons.delete_rounded,
                        AppTheme.errorRed,
                        isDark,
                        () {
                          Navigator.pop(ctx);
                          auth.updateProfilePhoto(null);
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _photoOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image == null) return;

      // Save to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile_photos');
      if (!await profileDir.exists()) await profileDir.create(recursive: true);

      final fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final savedFile = await File(
        image.path,
      ).copy('${profileDir.path}/$fileName');

      if (context.mounted) {
        context.read<AuthProvider>().updateProfilePhoto(savedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated! 📸'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showCurrencyPicker(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Currency',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: AppCurrencies.currencies.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final curr = AppCurrencies.currencies[index];
                  final isSelected = auth.currentUser?.currency == curr.code;
                  return GestureDetector(
                    onTap: () {
                      auth.updateCurrency(curr.code);
                      context.read<ExpenseProvider>().loadExpenses();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentPurple.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: isSelected
                            ? Border.all(
                                color: AppTheme.accentPurple,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(curr.flag, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${curr.code} — ${curr.symbol}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.darkText
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  curr.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(
      text: auth.currentUser?.monthlyBudget.toStringAsFixed(0) ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          'Set Monthly Budget',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How much do you plan to spend each month?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText:
                    '${AppCurrencies.getByCode(auth.currentUser!.currency).symbol} ',
                prefixStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
                hintText: '0.00',
              ),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
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
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                auth.updateBudget(val);
                context.read<ExpenseProvider>().loadExpenses();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNameDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(
      text: auth.currentUser?.displayName ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          'Change Display Name',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                auth.updateDisplayName(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    final emojis = [
      '😎',
      '🤑',
      '💰',
      '🦊',
      '🐱',
      '🦁',
      '🐼',
      '🦄',
      '🌟',
      '🔥',
      '💎',
      '🎯',
      '🚀',
      '🎨',
      '🌈',
      '🍀',
      '🎭',
      '🎪',
      '🏆',
      '👑',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Avatar',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: emojis
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          final auth = context.read<AuthProvider>();
                          auth.updateAvatar(e);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkBg
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showHelpInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'If you need help using ExpenseTracker, please reach out to us at support@expensetracker.com.',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            const Text('💰', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'ExpenseTracker',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Offline-first personal finance tracker. Track your income and expenses with ease. Created with Flutter and Erwan',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.read<ExpenseProvider>().clear();
              context.read<GoalsProvider>().clear();
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
