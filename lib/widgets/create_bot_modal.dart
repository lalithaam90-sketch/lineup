import 'package:flutter/material.dart';
import '../models/bot_model.dart';
import '../theme/app_colors.dart';

class CreateBotModal extends StatefulWidget {
  final Function(BotModel newBot) onBotCreated;

  const CreateBotModal({super.key, required this.onBotCreated});

  static void show(BuildContext context, Function(BotModel newBot) onBotCreated) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateBotModal(onBotCreated: onBotCreated),
    );
  }

  @override
  State<CreateBotModal> createState() => _CreateBotModalState();
}

class _CreateBotModalState extends State<CreateBotModal> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _selectedType = 'sales';

  final List<Map<String, dynamic>> _types = [
    {
      'id': 'sales',
      'title': 'Sales Assistant',
      'icon': Icons.point_of_sale_rounded,
      'desc': 'Handles product inquiries & purchases'
    },
    {
      'id': 'support',
      'title': 'Support Bot',
      'icon': Icons.support_agent_rounded,
      'desc': 'Answers FAQs & resolves tickets'
    },
    {
      'id': 'leads',
      'title': 'Lead Qualifier',
      'icon': Icons.filter_alt_rounded,
      'desc': 'Collects phone, email & intent'
    },
    {
      'id': 'custom',
      'title': 'Custom Agent',
      'icon': Icons.smart_toy_rounded,
      'desc': 'Tailored prompt and business logic'
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bot name')),
      );
      return;
    }

    final roleDesc = _types.firstWhere((t) => t['id'] == _selectedType)['desc'] as String;
    final instructions = _instructionsController.text.trim().isEmpty
        ? BotModel.defaultInstructionsFor(_selectedType)
        : _instructionsController.text.trim();

    final newBot = BotModel(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: roleDesc,
      type: _selectedType,
      isActive: true,
      totalConversations: 0,
      lastActive: 'Just created',
      instructions: instructions,
    );

    widget.onBotCreated(newBot);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentLightMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Build New AI Bot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bot Name Field
            const Text(
              'Bot Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Sales Assistant, Support Bot',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Select Role/Type
            const Text(
              'Bot Role',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final isSelected = _selectedType == type['id'];
                return ChoiceChip(
                  label: Text(type['title'] as String),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = type['id'] as String);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // AI Instructions (the real system prompt for this bot)
            const Text(
              'AI Instructions (System Prompt)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This is exactly what the AI bot will follow when replying to customers. Leave blank to use the default for "${_types.firstWhere((t) => t['id'] == _selectedType)['title']}".',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _instructionsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: BotModel.defaultInstructionsFor(_selectedType),
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Launch Bot',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
