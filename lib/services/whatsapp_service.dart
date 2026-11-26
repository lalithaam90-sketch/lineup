import 'package:cloud_functions/cloud_functions.dart';

/// Thin client for the callable Cloud Functions in /functions. They act on the
/// signed-in user's own WhatsApp connection; tokens never leave the server.
class WhatsAppService {
  static final FirebaseFunctions _fn = FirebaseFunctions.instance;

  static Future<T> _call<T>(String name, [Map<String, dynamic>? data]) async {
    try {
      final res = await _fn.httpsCallable(name).call(data);
      return res.data as T;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  static Future<void> sendMessage({required String to, required String text}) =>
      _call<dynamic>('sendWhatsAppMessage', {'to': to, 'text': text});

  static Future<void> sendTemplate({
    required String to,
    required String name,
    required String language,
  }) =>
      _call<dynamic>('sendWhatsAppTemplate', {'to': to, 'name': name, 'language': language});

  /// Sales bot opens chats with opted-in numbers using an approved template.
  static Future<Map<String, dynamic>> startSalesCampaign({
    required String templateName,
    required String language,
    required List<String> numbers,
    required String optInSource,
  }) async {
    final res = await _call<Map<dynamic, dynamic>>('startSalesCampaign', {
      'templateName': templateName,
      'language': language,
      'numbers': numbers,
      'optInConfirmed': true,
      'optInSource': optInSource,
    });
    return Map<String, dynamic>.from(res);
  }

  /// Number quality rating (GREEN/YELLOW/RED/UNKNOWN) and today's outreach usage.
  static Future<Map<String, dynamic>> getQuality() async {
    final res = await _call<Map<dynamic, dynamic>>('getWhatsAppQuality');
    return Map<String, dynamic>.from(res);
  }

  static Future<List<Map<String, dynamic>>> listTemplates() async {
    final res = await _call<Map<dynamic, dynamic>>('listWhatsAppTemplates');
    return (res['templates'] as List)
        .map((t) => Map<String, dynamic>.from(t as Map))
        .toList();
  }

  static Future<void> createTemplate({
    required String name,
    required String category,
    required String language,
    required String body,
  }) =>
      _call<dynamic>('createWhatsAppTemplate', {
        'name': name,
        'category': category,
        'language': language,
        'body': body,
      });
}
