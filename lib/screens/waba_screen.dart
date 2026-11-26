import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_action_card.dart';
import '../services/app_state.dart';
import '../widgets/connect_channel_modal.dart';
import 'waba_details_sheet.dart';
import 'waba_tools_sheets.dart';
import 'auto_replies_sheet.dart';

class WabaScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const WabaScreen({super.key, this.onBack});

  @override
  State<WabaScreen> createState() => _WabaScreenState();
}

class _WabaScreenState extends State<WabaScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text('WABA'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                size: 20,
                color: AppColors.whatsappGreen,
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
                // WhatsApp Connected Status Card
                _buildConnectedCard(),

                const SizedBox(height: 22),

                // Action Items
                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Send Message',
                  subtitle: 'Message a WhatsApp number',
                  onTap: () => WabaSendSheet.show(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Delivery Log',
                  subtitle: 'See which messages arrived or failed',
                  onTap: () => WabaDeliverySheet.show(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentLightMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  title: 'Sales Bot Outreach',
                  subtitle: 'Bot starts chats with your contact list',
                  onTap: () => WabaCampaignSheet.show(context),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.article_outlined,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Message Templates',
                  subtitle: 'Manage approved templates',
                  onTap: () => WabaTemplatesSheet.show(context),
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
                  subtitle: 'Keyword replies & FAQs',
                  onTap: () => AutoRepliesSheet.show(context, channel: 'WhatsApp'),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentLightMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  title: '24/7 AI Agent',
                  subtitle: 'Your active bot answers messages',
                  trailing: Switch.adaptive(
                    value: AppState().wabaAiEnabled,
                    activeTrackColor: AppColors.accentMint,
                    onChanged: (val) => AppState().setAiEnabled(whatsapp: true, value: val),
                  ),
                  onTap: () => AppState().setAiEnabled(whatsapp: true, value: !AppState().wabaAiEnabled),
                ),

                MenuActionCard(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: 'Analytics',
                  subtitle: 'View performance & insights',
                  onTap: () => WabaAnalyticsSheet.show(context),
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
    final isConnected = appState.isWabaConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2621), // Dark Slate/Emerald
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // WhatsApp Round Badge
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.whatsappGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WhatsApp Business Account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.accentMint.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected
                        ? AppColors.accentMint.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isConnected ? AppColors.accentMint : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Divider line inside card
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 14),

          if (isConnected) ...[
            // Real Business Name & Phone Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Name',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appState.wabaBusinessName.isNotEmpty ? appState.wabaBusinessName : 'Connected Account',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appState.wabaPhoneNumber.isNotEmpty ? appState.wabaPhoneNumber : '--',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                onTap: () => appState.disconnectWhatsApp(),
                child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Link your official WhatsApp phone number to enable auto-replies and bots.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => ConnectChannelModal.showConnectWhatsApp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsappGreen,
                    foregroundColor: Colors.white,
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
