import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/app_state.dart';

class InstagramAnalyticsSheet extends StatelessWidget {
  const InstagramAnalyticsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const InstagramAnalyticsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: Color(0xFFEC4899), size: 22),
              SizedBox(width: 8),
              Text('Instagram Analytics Hub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          if (!AppState().isInstagramConnected)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link_off_rounded, color: AppColors.textMuted, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Instagram account is not connected yet. Connect your account in the Instagram tab to activate automated DMs and reach analytics.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _metricCard('Conversations', '${AppState().instagramConversations}', 'Contacts who messaged you')),
                const SizedBox(width: 10),
                Expanded(child: _metricCard('Leads', '${AppState().leads.where((l) => l['channel'] == 'Instagram').length}', 'From Instagram')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accentMint)),
        ],
      ),
    );
  }

}
