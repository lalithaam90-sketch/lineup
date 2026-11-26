import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_action_card.dart';
import '../services/app_state.dart';
import '../widgets/connect_channel_modal.dart';
import 'instagram_details_sheet.dart';
import 'leads_list_sheet.dart';
import 'auto_replies_sheet.dart';

class InstagramScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const InstagramScreen({super.key, this.onBack});

  @override
  State<InstagramScreen> createState() => _InstagramScreenState();
}

class _InstagramScreenState extends State<InstagramScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Instagram'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: AppState(),
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instagram Business Card with signature gradient
                _buildConnectedCard(),

                const SizedBox(height: 22),

                // Action Items
                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: Color(0xFFDB2777),
                    ),
                  ),
                  title: 'DM Automation',
                  subtitle: 'AI bot replies to DMs',
                  trailing: Switch.adaptive(
                    value: AppState().igAiEnabled,
                    activeTrackColor: const Color(0xFFDB2777),
                    onChanged: (val) => AppState().setAiEnabled(whatsapp: false, value: val),
                  ),
                  onTap: () => AppState().setAiEnabled(whatsapp: false, value: !AppState().igAiEnabled),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.question_answer_outlined,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Auto Replies',
                  subtitle: 'Keyword replies for DMs',
                  onTap: () => AutoRepliesSheet.show(context, channel: 'Instagram'),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentLightMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.filter_alt_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  title: 'Lead Capture',
                  subtitle: 'Collect leads from DMs',
                  onTap: () => LeadsListSheet.show(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Analytics',
                  subtitle: 'Track reach, engagement & leads',
                  onTap: () => InstagramAnalyticsSheet.show(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectedCard() {
    final appState = AppState();
    final isConnected = appState.isInstagramConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.igBannerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // IG Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Instagram Business',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (isConnected) ...[
            // Real Meta Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appState.instagramAccount.isNotEmpty ? appState.instagramAccount : '@account',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Followers',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appState.instagramFollowers,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => appState.disconnectInstagram(),
                child: const Text('Disconnect', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Connect your professional Instagram handle to enable automated DM replies.',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => ConnectChannelModal.showConnectInstagram(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFDB2777),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
