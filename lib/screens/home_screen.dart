import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/lineup_logo.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../services/app_state.dart';
import 'notifications_sheet.dart';
import 'leads_list_sheet.dart';

class HomeScreen extends StatelessWidget {
  final Function(int tabIndex) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: AppState(),
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Header with Dark Teal Gradient
                _buildHeroHeader(context),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      // 2x2 KPI Metric Cards Grid
                      _buildMetricsGrid(),

                      const SizedBox(height: 24),

                      // Quick Actions Section Header
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2x2 Quick Actions Grid
                      _buildQuickActionsGrid(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: LineUp small logo + Notification bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LineUpLogo(
                size: 34,
                isDark: true,
                showShadow: false,
              ),
              GestureDetector(
                onTap: () => NotificationsSheet.show(context),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentMint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Greeting
          Text(
            AppState().userName.isNotEmpty ? 'Hello,' : 'Welcome to',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                AppState().userName.isNotEmpty
                    ? '${AppState().userName} '
                    : (AppState().businessName.isNotEmpty ? '${AppState().businessName} ' : 'LineUp '),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const Text(
                '👋',
                style: TextStyle(fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (AppState().isWabaConnected || AppState().isInstagramConnected)
                ? 'Your AI team is working 24/7'
                : 'Connect WhatsApp or Instagram to activate your AI team',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final appState = AppState();
    final activeBotsCount = appState.bots.where((b) => b.isActive).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // WABA Card
            SizedBox(
              width: cardWidth,
              height: 140,
              child: StatCard(
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 13,
                    color: AppColors.whatsappGreen,
                  ),
                ),
                title: 'WABA',
                value: appState.isWabaConnected ? '${appState.wabaConversations}' : '0',
                subtitle: appState.isWabaConnected ? 'Total Conversations' : 'Not Connected',
                trend: appState.isWabaConnected ? 'Active' : 'Offline',
                isTrendPositive: appState.isWabaConnected,
                onTap: () => onNavigateTab(1),
              ),
            ),

            // Instagram Card
            SizedBox(
              width: cardWidth,
              height: 140,
              child: StatCard(
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                title: 'Instagram',
                value: appState.isInstagramConnected ? '${appState.instagramConversations}' : '0',
                subtitle: appState.isInstagramConnected ? 'Total Conversations' : 'Not Connected',
                trend: appState.isInstagramConnected ? 'Active' : 'Offline',
                isTrendPositive: appState.isInstagramConnected,
                onTap: () => onNavigateTab(2),
              ),
            ),

            // Active Bots Card
            SizedBox(
              width: cardWidth,
              height: 140,
              child: StatCard(
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.accentLightMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ),
                title: 'Active Bots',
                value: '$activeBotsCount',
                subtitle: '${appState.bots.length} Deployed',
                trend: activeBotsCount > 0 ? '$activeBotsCount Running' : '0 Running',
                isTrendPositive: activeBotsCount > 0,
                onTap: () => onNavigateTab(3),
              ),
            ),

            // Leads Generated Card
            SizedBox(
              width: cardWidth,
              height: 140,
              child: StatCard(
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 13,
                    color: AppColors.accentCyan,
                  ),
                ),
                title: 'Leads Generated',
                value: '${appState.leadsCount}',
                subtitle: 'Total Captured',
                trend: appState.leadsCount > 0 ? '+${appState.leadsCount}' : '0',
                isTrendPositive: appState.leadsCount > 0,
                onTap: () => LeadsListSheet.show(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // WABA Quick Action
            SizedBox(
              width: cardWidth,
              height: 110,
              child: QuickActionCard(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 16,
                    color: AppColors.whatsappGreen,
                  ),
                ),
                title: 'WABA',
                description: 'Manage WhatsApp business',
                onTap: () => onNavigateTab(1),
              ),
            ),

            // Instagram Quick Action
            SizedBox(
              width: cardWidth,
              height: 110,
              child: QuickActionCard(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                title: 'Instagram',
                description: 'Connect & manage Instagram',
                onTap: () => onNavigateTab(2),
              ),
            ),

            // Bot Management Quick Action
            SizedBox(
              width: cardWidth,
              height: 110,
              child: QuickActionCard(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentLightMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                title: 'Bot Management',
                description: 'Create & manage AI bots',
                onTap: () => onNavigateTab(3),
              ),
            ),

            // Profile Quick Action
            SizedBox(
              width: cardWidth,
              height: 110,
              child: QuickActionCard(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                title: 'Profile',
                description: 'Account & settings',
                onTap: () => onNavigateTab(4),
              ),
            ),
          ],
        );
      },
    );
  }
}
