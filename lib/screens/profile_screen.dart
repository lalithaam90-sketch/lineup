import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/lineup_logo.dart';
import '../widgets/menu_action_card.dart';
import '../services/app_state.dart';
import 'profile_sheets.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: AppState(),
        builder: (context, _) {
          final appState = AppState();
          final displayName = appState.userName.isNotEmpty
              ? appState.userName
              : (appState.businessName.isNotEmpty ? appState.businessName : 'Your Profile');
          // Prefer the real signed-in phone number (Firebase Auth) when the
          // user hasn't typed an email into Business Details yet.
          final phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
          final displayEmail = appState.userEmail.isNotEmpty
              ? appState.userEmail
              : (phoneNumber ?? 'Tap Business Details to configure');

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Profile Avatar & User Info
                Center(
                  child: InkWell(
                    onTap: () => BusinessDetailsSheet.show(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          const LineUpLogo(
                            size: 72,
                            isDark: true,
                            showShadow: true,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Settings Menu Items
                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business_center_outlined,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Business Details',
                  subtitle: appState.businessName.isNotEmpty
                      ? appState.businessName
                      : 'Set up your business info',
                  onTap: () => BusinessDetailsSheet.show(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.credit_card_outlined,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Subscription',
                  subtitle: 'View plan & usage quotas',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentLightMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  onTap: () => SubscriptionSheet.show(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Notifications',
                  subtitle: 'App & bot alert preferences',
                  onTap: () => NotificationPreferencesSheet.show(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Help & Support',
                  subtitle: 'Documentation & contact',
                  onTap: () => HelpSupportSheet.show(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'About LineUp',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                  title: 'Sign Out',
                  subtitle: phoneNumber ?? 'Sign out of this account',
                  onTap: () => _confirmSignOut(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and all data',
                  onTap: () => _confirmDeleteAccount(context),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.language_rounded),
              title: Text('Language'),
              trailing: Text('English (US)'),
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              leading: Icon(Icons.security_rounded),
              title: Text('Security & Encryption'),
              trailing: Text('AES-256 Enabled'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('You\'ll need to verify your WhatsApp number again to sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // AuthGate's authStateChanges listener detaches AppState and
              // routes back to LoginScreen once this completes.
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool busy = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Delete account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently deletes your profile, WhatsApp and Instagram connections, bots, leads, conversations and notifications, and your login. It cannot be undone. Payment records are kept as required by law.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Type DELETE to confirm'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: (busy || controller.text.trim() != 'DELETE')
                    ? null
                    : () async {
                        setState(() => busy = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await FirebaseFunctions.instance
                              .httpsCallable('deleteMyAccount')
                              .call({'confirm': 'DELETE'});
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          // The login no longer exists; AuthGate routes back to sign-in.
                          await FirebaseAuth.instance.signOut();
                        } on FirebaseFunctionsException catch (e) {
                          setState(() => busy = false);
                          messenger.showSnackBar(SnackBar(content: Text(e.message ?? 'Could not delete the account.')));
                        } catch (_) {
                          setState(() => busy = false);
                          messenger.showSnackBar(const SnackBar(content: Text('Could not delete the account.')));
                        }
                      },
                child: busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Delete forever', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'LineUp',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 AARDINOVATIONS PRIVATE LIMITED. All rights reserved.',
    );
  }
}
