import 'package:flutter/material.dart';
import '../models/bot_model.dart';
import '../theme/app_colors.dart';

class BotDetailSheet extends StatefulWidget {
  final BotModel bot;
  final VoidCallback onUpdated;

  const BotDetailSheet({
    super.key,
    required this.bot,
    required this.onUpdated,
  });

  static void show(BuildContext context, BotModel bot, VoidCallback onUpdated) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BotDetailSheet(bot: bot, onUpdated: onUpdated),
    );
  }

  @override
  State<BotDetailSheet> createState() => _BotDetailSheetState();
}

class _BotDetailSheetState extends State<BotDetailSheet> {
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late bool _isActive;
  late List<String> _knowledgeSources;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bot.name);
    // Previously this always reloaded a hardcoded default prompt and any
    // edits were discarded on save. Now it loads (and actually persists)
    // the bot's real saved instructions.
    _promptController = TextEditingController(text: widget.bot.instructions);
    _isActive = widget.bot.isActive;
    _knowledgeSources = List<String>.from(widget.bot.knowledge);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bot name cannot be empty')),
      );
      return;
    }

    widget.bot.name = name;
    widget.bot.isActive = _isActive;
    widget.bot.knowledge = _knowledgeSources;
    widget.bot.instructions = _promptController.text.trim().isEmpty
        ? BotModel.defaultInstructionsFor(widget.bot.type)
        : _promptController.text.trim();

    widget.onUpdated();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bot settings saved for ${widget.bot.name}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _addKnowledgeSource() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add business knowledge'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'e.g. Opening hours: 9am-6pm Mon-Sat. Delivery is free above Rs 999.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _knowledgeSources.add(controller.text.trim());
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentLightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bot.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'AI Agent • ${_isActive ? "Active" : "Paused"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isActive,
                activeTrackColor: AppColors.accentMint,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Editable bot name
                  const Text(
                    'Bot Name',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Performance Stats Grid (Using real numbers from this bot)
                  Row(
                    children: [
                      Expanded(
                        child: _statPill(
                          'Conversations',
                          '${widget.bot.totalConversations}',
                          Icons.chat_bubble_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Prompt Configuration
                  const Text(
                    'Agent System Prompt & Instructions',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The instructions your bot follows when it replies on WhatsApp and Instagram.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _promptController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Enter specific prompt guidelines for this bot',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Knowledge Base Documents
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Business Knowledge',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: _addKnowledgeSource,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_knowledgeSources.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'No business knowledge added. Add facts like pricing, hours and FAQs so the bot answers accurately.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    )
                  else
                    ..._knowledgeSources.map((src) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _knowledgeFile(src, 'Used by bot', () => setState(() => _knowledgeSources.remove(src))),
                        )),
                  const SizedBox(height: 20),

                  // Live Simulation Preview
                  const Text(
                    'Conversation Log Status',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      widget.bot.totalConversations == 0
                          ? 'No live conversations recorded yet. Customer dialogues on WhatsApp or Instagram will be logged here.'
                          : '${widget.bot.totalConversations} customer interaction(s) logged.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Save Button
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
              child: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _knowledgeFile(String name, String meta, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Flexible(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ),
          IconButton(icon: const Icon(Icons.close_rounded, size: 16), tooltip: 'Remove', onPressed: onRemove),
        ],
      ),
    );
  }
}
