import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

/// Keyword auto-replies, stored in Firestore and executed by the backend
/// before the AI bot: if a customer's message contains any keyword, the
/// saved response is sent instead of an AI answer.
class AutoRepliesSheet extends StatelessWidget {
  /// 'WhatsApp' or 'Instagram': which channel's rules to show/create.
  final String channel;
  const AutoRepliesSheet({super.key, required this.channel});

  static void show(BuildContext context, {required String channel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AutoRepliesSheet(channel: channel),
    );
  }

  Future<void> _edit(BuildContext context, [Map<String, dynamic>? rule]) async {
    final keywords = TextEditingController(text: ((rule?['keywords'] as List?) ?? []).join(', '));
    final response = TextEditingController(text: (rule?['response'] as String?) ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rule == null ? 'New auto-reply' : 'Edit auto-reply'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keywords,
                decoration: const InputDecoration(
                  labelText: 'When message contains',
                  helperText: 'Separate keywords with commas, e.g. price, pricing',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: response,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Reply with'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (save != true) return;
    final kw = keywords.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    if (kw.isEmpty || response.text.trim().isEmpty) return;
    await AppState().saveAutoReply(
      id: rule?['id'] as String?,
      keywords: kw,
      response: response.text.trim(),
      channel: (rule?['channel'] as String?) ?? channel,
      enabled: (rule?['enabled'] as bool?) ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: AnimatedBuilder(
        animation: AppState(),
        builder: (context, _) {
          final rules = AppState()
              .autoReplies
              .where((r) => r['channel'] == 'all' || r['channel'] == channel)
              .toList();
          return Column(
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
                  Text('$channel auto-replies', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'If a customer message contains one of the keywords, this reply is sent instead of the AI answer.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: rules.isEmpty
                    ? const Center(
                        child: Text('No auto-replies yet. Tap Add to create one.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    : ListView.separated(
                        itemCount: rules.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final r = rules[i];
                          final id = r['id'] as String;
                          return InkWell(
                            onTap: () => _edit(context, r),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ((r['keywords'] as List?) ?? []).join(', '),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ),
                                      Switch.adaptive(
                                        value: (r['enabled'] as bool?) ?? true,
                                        activeTrackColor: AppColors.accentMint,
                                        onChanged: (v) => AppState().setAutoReplyEnabled(id, v),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                        tooltip: 'Delete',
                                        onPressed: () => AppState().deleteAutoReply(id),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                                    child: Text('${r['response']}', style: const TextStyle(fontSize: 12, height: 1.3)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
