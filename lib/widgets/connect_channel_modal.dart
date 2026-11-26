import '../services/instagram_login.dart';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/meta_api_service.dart';
import '../theme/app_colors.dart';

class ConnectChannelModal {
  static void showConnectWhatsApp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ConnectWhatsAppSheet(),
    );
  }

  static void showConnectInstagram(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ConnectInstagramSheet(),
    );
  }
}

/// Shared styled text field used by both connect sheets.
class _CredentialField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isSecret;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  const _CredentialField({
    required this.label,
    required this.controller,
    required this.hint,
    this.isSecret = false,
    this.obscure = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isSecret ? obscure : false,
          maxLines: isSecret ? 1 : 1,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            suffixIcon: isSecret
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _HowToGetThis extends StatelessWidget {
  final String text;
  const _HowToGetThis({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.accentLightMint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _ConnectWhatsAppSheet extends StatefulWidget {
  const _ConnectWhatsAppSheet();

  @override
  State<_ConnectWhatsAppSheet> createState() => _ConnectWhatsAppSheetState();
}

class _ConnectWhatsAppSheetState extends State<_ConnectWhatsAppSheet> {
  final _wabaIdController = TextEditingController();
  final _phoneNumberIdController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _obscureToken = true;
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _wabaIdController.dispose();
    _phoneNumberIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final wabaId = _wabaIdController.text.trim();
    final phoneNumberId = _phoneNumberIdController.text.trim();
    final token = _tokenController.text.trim();

    if (wabaId.isEmpty || phoneNumberId.isEmpty || token.isEmpty) {
      setState(() => _error = 'Please fill in all three fields.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final result = await MetaApiService.verifyWhatsAppCredentials(
        phoneNumberId: phoneNumberId,
        accessToken: token,
      );

      await AppState().connectWhatsApp(
        wabaId: wabaId,
        phoneNumberId: phoneNumberId,
        accessToken: token,
        displayPhoneNumber: result.displayPhoneNumber,
        businessName: result.verifiedBusinessName.isNotEmpty
            ? result.verifiedBusinessName
            : AppState().businessName,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp connected: ${result.displayPhoneNumber}')),
      );
    } on MetaApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong verifying this account. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.chat_bubble_rounded, color: AppColors.whatsappGreen, size: 24),
                SizedBox(width: 10),
                Text('Connect WhatsApp Business', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            const _HowToGetThis(
              text: 'In Meta Business Manager, go to Business Settings > Users > System Users. Create (or open) a System User, assign it "Full Control" on your app and your WhatsApp Business Account, then generate a permanent access token with whatsapp_business_management and whatsapp_business_messaging permissions.',
            ),
            _CredentialField(
              label: 'WhatsApp Business Account (WABA) ID',
              controller: _wabaIdController,
              hint: 'e.g. 102938475610293',
            ),
            const SizedBox(height: 14),
            _CredentialField(
              label: 'Phone Number ID',
              controller: _phoneNumberIdController,
              hint: 'e.g. 109876543210987',
            ),
            const SizedBox(height: 14),
            _CredentialField(
              label: 'Permanent Access Token',
              controller: _tokenController,
              hint: 'EAAG...',
              isSecret: true,
              obscure: _obscureToken,
              onToggleObscure: () => setState(() => _obscureToken = !_obscureToken),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent, height: 1.3)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.whatsappGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify & Connect', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectInstagramSheet extends StatefulWidget {
  const _ConnectInstagramSheet();

  @override
  State<_ConnectInstagramSheet> createState() => _ConnectInstagramSheetState();
}

class _ConnectInstagramSheetState extends State<_ConnectInstagramSheet> {
  final _igUserIdController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _obscureToken = true;
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _igUserIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final igUserId = _igUserIdController.text.trim();
    final token = _tokenController.text.trim();

    if (igUserId.isEmpty || token.isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final result = await MetaApiService.verifyInstagramCredentials(
        igUserId: igUserId,
        accessToken: token,
      );

      await AppState().connectInstagram(
        igUserId: igUserId,
        accessToken: token,
        username: result.username,
        followersCount: result.followersCount,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Instagram connected: @${result.username}')),
      );
    } on MetaApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong verifying this account. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.camera_alt_rounded, color: Color(0xFFDB2777), size: 24),
                SizedBox(width: 10),
                Text('Connect Instagram Business', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            if (kInstagramLoginEnabled) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => startInstagramLogin(context),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Log in with Instagram', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You approve access on Instagram, and LineUp never sees your password. Your account must be an Instagram Professional (Business or Creator) account.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            ],
            if (!kInstagramLoginEnabled) ...[
            const _HowToGetThis(
              text: 'Your Instagram account must be a Professional (Business or Creator) account. In your Meta app go to Use cases > Instagram > API setup with Instagram login, add your account, and generate an access token. Paste the Instagram account ID and token here. The token needs the instagram_business_basic and instagram_business_manage_messages permissions.',
            ),
            _CredentialField(
              label: 'Instagram Business Account ID',
              controller: _igUserIdController,
              hint: 'e.g. 17841400000000000',
            ),
            const SizedBox(height: 14),
            _CredentialField(
              label: 'Permanent Access Token',
              controller: _tokenController,
              hint: 'EAAG...',
              isSecret: true,
              obscure: _obscureToken,
              onToggleObscure: () => setState(() => _obscureToken = !_obscureToken),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent, height: 1.3)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify & Connect', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }
}
