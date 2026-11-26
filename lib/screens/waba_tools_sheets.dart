import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_colors.dart';

Widget _grabber() => Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
      ),
    );

BoxDecoration _sheetDecoration() => const BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    );

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// Live message templates from Meta, with a form to create new ones.
class WabaTemplatesSheet extends StatefulWidget {
  const WabaTemplatesSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WabaTemplatesSheet(),
    );
  }

  @override
  State<WabaTemplatesSheet> createState() => _WabaTemplatesSheetState();
}

class _WabaTemplatesSheetState extends State<WabaTemplatesSheet> {
  List<Map<String, dynamic>>? _templates;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await WhatsAppService.listTemplates();
      if (mounted) setState(() => _templates = t);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _bodyOf(Map<String, dynamic> t) {
    final comps = (t['components'] as List?) ?? [];
    for (final c in comps) {
      if (c is Map && c['type'] == 'BODY') return (c['text'] as String?) ?? '';
    }
    return '';
  }

  void _openCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateTemplateSheet(onCreated: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: _sheetDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.article_outlined, color: AppColors.whatsappGreen, size: 22),
                  SizedBox(width: 8),
                  Text('Message Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              TextButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final list = _templates ?? [];
    if (list.isEmpty) {
      return const Center(child: Text('No templates yet. Tap Create to add one.', style: TextStyle(color: AppColors.textMuted)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final t = list[i];
          final status = (t['status'] as String?) ?? '';
          final approved = status == 'APPROVED';
          return Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${t['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: approved ? AppColors.accentLightMint : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: approved ? AppColors.accentMint : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${t['category']} • ${t['language']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: Text(_bodyOf(t), style: const TextStyle(fontSize: 12, height: 1.35)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CreateTemplateSheet extends StatefulWidget {
  final Future<void> Function() onCreated;
  const _CreateTemplateSheet({required this.onCreated});

  @override
  State<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<_CreateTemplateSheet> {
  final _name = TextEditingController();
  final _body = TextEditingController();
  String _category = 'UTILITY';
  String _language = 'en_US';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await WhatsAppService.createTemplate(
        name: _name.text.trim(),
        category: _category,
        language: _language,
        body: _body.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast(context, 'Template submitted to Meta for approval');
      await widget.onCreated();
    } catch (e) {
      if (mounted) _toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: _sheetDecoration(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _grabber(),
              const SizedBox(height: 16),
              const Text('Create template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Template name',
                  helperText: 'Lowercase letters, numbers, underscores',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'UTILITY', child: Text('Utility')),
                  DropdownMenuItem(value: 'MARKETING', child: Text('Marketing')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'UTILITY'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: const InputDecoration(labelText: 'Language'),
                items: const [
                  DropdownMenuItem(value: 'en_US', child: Text('English (US)')),
                  DropdownMenuItem(value: 'en_GB', child: Text('English (UK)')),
                  DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                ],
                onChanged: (v) => setState(() => _language = v ?? 'en_US'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message body',
                  helperText: 'Use {{1}}, {{2}} for variables',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit to Meta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Send a message to a WhatsApp number: free text, or an approved template.
class WabaSendSheet extends StatefulWidget {
  const WabaSendSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WabaSendSheet(),
    );
  }

  @override
  State<WabaSendSheet> createState() => _WabaSendSheetState();
}

class _WabaSendSheetState extends State<WabaSendSheet> {
  final _to = TextEditingController();
  final _text = TextEditingController();
  bool _useTemplate = false;
  bool _sending = false;
  List<Map<String, dynamic>> _approved = [];
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    WhatsAppService.listTemplates().then((all) {
      if (!mounted) return;
      setState(() => _approved = all.where((t) => t['status'] == 'APPROVED').toList());
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _to.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      if (_useTemplate) {
        final t = _selected;
        if (t == null) throw Exception('Pick a template.');
        await WhatsAppService.sendTemplate(
          to: _to.text,
          name: t['name'] as String,
          language: t['language'] as String,
        );
      } else {
        await WhatsAppService.sendMessage(to: _to.text, text: _text.text);
      }
      if (!mounted) return;
      _toast(context, 'Sent to WhatsApp. Check Delivery Log to see if it arrived.');
      _text.clear();
    } catch (e) {
      if (mounted) _toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: _sheetDecoration(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _grabber(),
              const SizedBox(height: 16),
              const Text('Send WhatsApp message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(
                controller: _to,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'To (with country code)',
                  hintText: '919876543210',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Send an approved template', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Needed to start a conversation', style: TextStyle(fontSize: 11)),
                value: _useTemplate,
                onChanged: (v) => setState(() => _useTemplate = v),
              ),
              if (_useTemplate)
                DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: _selected,
                  decoration: const InputDecoration(labelText: 'Template'),
                  items: _approved
                      .map((t) => DropdownMenuItem(value: t, child: Text('${t['name']}')))
                      .toList(),
                  onChanged: (v) => setState(() => _selected = v),
                )
              else
                TextField(
                  controller: _text,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    helperText: 'Free text only works within 24h of their last message',
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sales campaign: the active Sales bot opens conversations with a list of
/// opted-in numbers using an approved template, then handles their replies.
class WabaCampaignSheet extends StatefulWidget {
  const WabaCampaignSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WabaCampaignSheet(),
    );
  }

  @override
  State<WabaCampaignSheet> createState() => _WabaCampaignSheetState();
}

class _WabaCampaignSheetState extends State<WabaCampaignSheet> {
  final _numbers = TextEditingController();
  final _source = TextEditingController();
  Map<String, dynamic>? _quality;
  List<Map<String, dynamic>> _approved = [];
  Map<String, dynamic>? _selected;
  bool _optIn = false;
  bool _running = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    WhatsAppService.listTemplates().then((all) {
      if (!mounted) return;
      setState(() => _approved = all.where((t) => t['status'] == 'APPROVED').toList());
    }).catchError((_) {});
    WhatsAppService.getQuality().then((q) {
      if (mounted) setState(() => _quality = q);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _numbers.dispose();
    _source.dispose();
    super.dispose();
  }

  List<String> get _parsed => _numbers.text
      .split(RegExp(r'[\s,;]+'))
      .map((s) => s.replaceAll(RegExp(r'\D'), ''))
      .where((s) => s.length >= 8)
      .toSet()
      .toList();

  Future<void> _run() async {
    final t = _selected;
    if (t == null) return _toast(context, 'Pick a template.');
    setState(() {
      _running = true;
      _result = null;
    });
    try {
      final r = await WhatsAppService.startSalesCampaign(
        templateName: t['name'] as String,
        language: t['language'] as String,
        numbers: _parsed,
        optInSource: _source.text.trim(),
      );
      final errs = (r['errors'] as List?)?.join('\n') ?? '';
      if (mounted) {
        setState(() => _result =
            'Sent ${r['sent']}, failed ${r['failed']}. Skipped ${r['skippedOptedOut']} opted-out and ${r['skippedCap']} over the daily limit (${r['dailyCap']}/day).${errs.isEmpty ? '' : '\n$errs'}');
      }
    } catch (e) {
      if (mounted) _toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: _sheetDecoration(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _grabber(),
              const SizedBox(height: 16),
              const Text('Sales bot outreach', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Your active Sales bot opens each chat with the template below, then handles replies automatically.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (_quality != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Number quality: ${_quality!['quality']} · Today: ${_quality!['usedToday']}/${_quality!['cap']} outreach messages',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _quality!['quality'] == 'RED' ? Colors.redAccent : AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: _selected,
                decoration: const InputDecoration(
                  labelText: 'Opening template (approved)',
                  helperText: 'Must include an opt-out line, e.g. "Reply STOP to unsubscribe"',
                ),
                items: _approved
                    .map((t) => DropdownMenuItem(value: t, child: Text('${t['name']}')))
                    .toList(),
                onChanged: (v) => setState(() => _selected = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _numbers,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Phone numbers (with country code)',
                  helperText: 'Separate with commas or new lines. Max 100. ${_parsed.length} valid',
                ),
              ),
              TextField(
                controller: _source,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'How did they opt in?',
                  hintText: 'e.g. website signup form, in-store sign-up sheet',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _optIn,
                onChanged: (v) => setState(() => _optIn = v ?? false),
                title: const Text(
                  'Everyone on this list has opted in to receive WhatsApp messages from my business.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (_result != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_result!, style: const TextStyle(fontSize: 12)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_running || !_optIn || _parsed.isEmpty || _source.text.trim().length < 3) ? null : _run,
                  child: _running
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Start outreach (${_parsed.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the last messages LineUp sent on WhatsApp and whether each one arrived.
/// Status comes from Meta's delivery reports: sent, delivered, read or failed
/// (with the reason). A message that Meta accepted but could not deliver shows here.
class WabaDeliverySheet extends StatelessWidget {
  const WabaDeliverySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WabaDeliverySheet(),
    );
  }

  (String, Color) _style(String status) {
    switch (status) {
      case 'read':
        return ('Read', AppColors.accentMint);
      case 'delivered':
        return ('Delivered', AppColors.accentMint);
      case 'failed':
        return ('Failed', Colors.redAccent);
      default:
        return ('Sent to WhatsApp', AppColors.textMuted);
    }
  }

  String _when(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: _sheetDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          const SizedBox(height: 16),
          const Text('Delivery log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Messages LineUp sent on WhatsApp and whether they arrived. "Sent to WhatsApp" means WhatsApp accepted it but has not confirmed delivery yet.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: uid == null
                ? const Center(child: Text('Sign in to see messages.'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('outbox')
                        .orderBy('createdAt', descending: true)
                        .limit(40)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const Center(child: Text('Could not load the delivery log.'));
                      }
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('No messages yet. Send one and it will appear here.', style: TextStyle(color: AppColors.textMuted)),
                        );
                      }
                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final m = docs[i].data();
                          final (label, color) = _style('${m['status']}');
                          final what = m['kind'] == 'template'
                              ? 'Template: ${m['templateName'] ?? ''}'
                              : '${m['text'] ?? ''}';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: m['status'] == 'failed' ? Colors.redAccent : AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('To ${m['to']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                    Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(what, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  '${m['source'] == 'bot' ? 'Bot reply' : m['source'] == 'campaign' ? 'Campaign' : 'Sent from LineUp'} · ${_when(m['createdAt'] as Timestamp?)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                if (m['status'] == 'failed') ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${m['hint'] ?? 'WhatsApp could not deliver this message.'}${m['errorCode'] != null ? ' (code ${m['errorCode']})' : ''}',
                                    style: const TextStyle(fontSize: 12, color: Colors.redAccent, height: 1.3),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
