import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/app_state.dart';
import 'plans_section.dart';

class BusinessDetailsSheet extends StatefulWidget {
  const BusinessDetailsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BusinessDetailsSheet(),
    );
  }

  @override
  State<BusinessDetailsSheet> createState() => _BusinessDetailsSheetState();
}

class _BusinessDetailsSheetState extends State<BusinessDetailsSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _gstController;

  @override
  void initState() {
    super.initState();
    final state = AppState();
    _nameController = TextEditingController(text: state.userName);
    _companyController = TextEditingController(text: state.businessName);
    _emailController = TextEditingController(text: state.userEmail);
    _phoneController = TextEditingController(text: state.businessPhone);
    _websiteController = TextEditingController(text: state.website);
    _gstController = TextEditingController(text: state.gst);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _save() {
    AppState().updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      business: _companyController.text,
      phone: _phoneController.text,
      website: _websiteController.text,
      gst: _gstController.text,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business details updated successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.business_center_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Business Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _field('Your Full Name', _nameController, Icons.person_outline, 'e.g. Alex Morgan'),
                  const SizedBox(height: 14),
                  _field('Company / Brand Name', _companyController, Icons.domain, 'e.g. Acme Innovations'),
                  const SizedBox(height: 14),
                  _field('Official Business Email', _emailController, Icons.email_outlined, 'e.g. contact@yourcompany.com'),
                  const SizedBox(height: 14),
                  _field('Business Phone Number', _phoneController, Icons.phone_outlined, 'e.g. +1 555 123 4567'),
                  const SizedBox(height: 14),
                  _field('Website', _websiteController, Icons.language_rounded, 'e.g. https://yourcompany.com'),
                  const SizedBox(height: 14),
                  _field('Tax / Business ID (Optional)', _gstController, Icons.badge_outlined, 'e.g. TAX-98721'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Profile', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class SubscriptionSheet extends StatelessWidget {
  const SubscriptionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SubscriptionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        final state = AppState();
        final activeBots = state.bots.where((b) => b.isActive).length;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card_outlined, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text('Subscription & Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accentLightMint, borderRadius: BorderRadius.circular(12)),
                    child: const Text('ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LineUp Multi-Channel Suite',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.businessName.isNotEmpty ? state.businessName : 'Your workspace',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'WhatsApp and Instagram messaging, AI bots, keyword auto-replies and lead capture.',
                              style: TextStyle(fontSize: 12, color: Colors.white, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('Usage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _usageItem(
                        'WABA Conversations',
                        '${state.wabaConversations} conversations',
                        0.0,
                      ),
                      _usageItem(
                        'Instagram DM Automations',
                        '${state.instagramConversations} conversations',
                        0.0,
                      ),
                      _usageItem(
                        'Active AI Bots Deployed',
                        '$activeBots active',
                        0.0,
                      ),
                      _usageItem(
                        'Captured Leads Pipeline',
                        '${state.leads.length} leads registered',
                        0.0,
                      ),
                      const SizedBox(height: 20),
                      const PlansSection(),
                      const SizedBox(height: 20),

                      const Text('Account Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.trendUp, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Channels', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(
                                    (state.isWabaConnected || state.isInstagramConnected)
                                        ? '${state.isWabaConnected ? 'WhatsApp connected' : 'WhatsApp not connected'}, ${state.isInstagramConnected ? 'Instagram connected' : 'Instagram not connected'}'
                                        : 'Connect a channel to start',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _usageItem(String label, String value, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationPreferencesSheet extends StatefulWidget {
  const NotificationPreferencesSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationPreferencesSheet(),
    );
  }

  @override
  State<NotificationPreferencesSheet> createState() => _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState extends State<NotificationPreferencesSheet> {
  bool _leadAlerts = true;
  bool _botHealthAlerts = true;
  bool _dailyDigest = true;
  bool _metaTemplateAlerts = true;
  bool _marketingUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
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
              Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _toggle('Instant Lead Alerts', 'Receive real-time mobile push when an AI bot qualifies a new lead.', _leadAlerts, (v) => setState(() => _leadAlerts = v)),
          _toggle('Bot Health & Channel Alerts', 'Notifies immediately if WhatsApp or Instagram token needs attention.', _botHealthAlerts, (v) => setState(() => _botHealthAlerts = v)),
          _toggle('Daily Summary Digest', 'Receive summary of conversations handled and lead conversions.', _dailyDigest, (v) => setState(() => _dailyDigest = v)),
          _toggle('Meta WABA Template Updates', 'Status changes when templates are submitted, approved, or rejected.', _metaTemplateAlerts, (v) => setState(() => _metaTemplateAlerts = v)),
          _toggle('Product & Feature Announcements', 'News about updates and new bot presets.', _marketingUpdates, (v) => setState(() => _marketingUpdates = v)),
        ],
      ),
    );
  }

  Widget _toggle(String title, String desc, bool val, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(value: val, activeTrackColor: AppColors.accentMint, onChanged: onChanged),
        ],
      ),
    );
  }
}

class HelpSupportSheet extends StatelessWidget {
  const HelpSupportSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const HelpSupportSheet(),
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
              Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Help & Support Hub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _contactBtn(
                  'Community Chat',
                  'Online Support',
                  Icons.chat_bubble_rounded,
                  AppColors.whatsappGreen,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support chat connected')));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactBtn(
                  'Support Email',
                  'Direct Inquiries',
                  Icons.email_outlined,
                  AppColors.primary,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support desk ready')));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: const [
                ExpansionTile(
                  title: Text('How do I connect my WhatsApp Business API (WABA)?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Go to WABA tab > Connect Account. Enter your WhatsApp Business phone number and display name to link the account.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text('How do I build an AI Bot?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('In the Bots tab, tap "Create New Bot", enter a name, pick an assistant role (Sales, Support, Leads, or Custom), and launch it.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text('How are leads captured?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('When visitors interact with your AI bots on WhatsApp or Instagram, qualified inquiries are automatically extracted and listed under Leads.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactBtn(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
