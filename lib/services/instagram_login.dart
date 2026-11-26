import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Log in with Instagram": asks the backend for a signed consent URL and
/// sends the owner to Instagram's own authorisation screen. After they approve,
/// the backend stores the token and returns them to the app.
Future<void> startInstagramLogin(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final res = await FirebaseFunctions.instance.httpsCallable('getInstagramAuthUrl').call();
    final url = (res.data as Map)['url'] as String;
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
  } on FirebaseFunctionsException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message ?? 'Instagram login is not available yet.')));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('Could not start Instagram login.')));
  }
}

/// Shows the result of the redirect back from Instagram (?ig=connected|error).
void showInstagramLoginResult(BuildContext context) {
  final q = Uri.base.queryParameters;
  final ig = q['ig'];
  if (ig == null) return;
  final text = ig == 'connected'
      ? 'Instagram connected'
      : (q['msg'] ?? 'Instagram connection failed');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  });
}

/// Build with `--dart-define=IG_LOGIN=true` once the Instagram OAuth backend is
/// configured (INSTAGRAM_APP_ID + INSTAGRAM_APP_SECRET); the button is hidden until then.
const bool kInstagramLoginEnabled = bool.fromEnvironment('IG_LOGIN');
