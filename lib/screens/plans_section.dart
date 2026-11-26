import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';

/// Shows the customer's current plan and the plans they can buy. Payment happens
/// on a Razorpay-hosted page (UPI, cards, netbanking); our backend marks the plan
/// active when Razorpay confirms the payment.
class PlansSection extends StatefulWidget {
  const PlansSection({super.key});

  @override
  State<PlansSection> createState() => _PlansSectionState();
}

class _PlansSectionState extends State<PlansSection> {
  late final Future<QuerySnapshot<Map<String, dynamic>>> _plans =
      FirebaseFirestore.instance.collection('plans').where('active', isEqualTo: true).get();
  String? _paying;

  Future<void> _pay(String planId) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _paying = planId);
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('createMyPaymentLink')
          .call({'planId': planId});
      final url = (res.data as Map)['url'] as String;
      await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? 'Payments are not available yet.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not start the payment.')));
    } finally {
      if (mounted) setState(() => _paying = null);
    }
  }

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final current = state.planName.isEmpty
        ? 'No paid plan'
        : '${state.planName}${state.planExpiresAt != null ? ' · until ${_date(state.planExpiresAt!)}' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(current, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        const Text('Available plans', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _plans,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('No plans are available right now.', style: TextStyle(fontSize: 12, color: AppColors.textMuted));
            }
            return Column(
              children: docs.map((d) {
                final p = d.data();
                final price = (p['priceInr'] as num?) ?? 0;
                final days = (p['intervalDays'] as num?)?.toInt() ?? 30;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('₹$price for $days days', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: price > 0 && _paying == null ? () => _pay(d.id) : null,
                        child: _paying == d.id
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Pay'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const Text(
          'Payments are processed securely by Razorpay (UPI, cards, netbanking). Your plan activates automatically after payment.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
