import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown when a call to the Meta Graph API fails, with a message that's
/// safe to show directly to the user in a SnackBar/dialog.
class MetaApiException implements Exception {
  final String message;
  MetaApiException(this.message);

  @override
  String toString() => message;
}

/// Verified details fetched back from Meta for a WhatsApp Business
/// phone number.
class WhatsAppVerification {
  final String verifiedBusinessName;
  final String displayPhoneNumber;
  WhatsAppVerification({
    required this.verifiedBusinessName,
    required this.displayPhoneNumber,
  });
}

/// Verified details fetched back from Meta for an Instagram
/// professional account.
class InstagramVerification {
  final String username;
  final int followersCount;
  InstagramVerification({
    required this.username,
    required this.followersCount,
  });
}

/// Talks directly to the Meta (Facebook) Graph API using credentials the
/// user pastes in from their own Meta Business Manager (System User
/// access token). This is the "manual / System User token" integration
/// model: each connected business grants Lineup access to their own WABA
/// or Instagram account directly in their own Business Manager, so no
/// Tech Provider / Embedded Signup / App Review flow is required.
///
/// Nothing here silently succeeds — every call either returns real data
/// fetched from Meta or throws a [MetaApiException] with a human-readable
/// reason, so the connect flow can never "connect" a bad credential.
class MetaApiService {
  static const String _graphVersion = 'v21.0';
  static const Duration _timeout = Duration(seconds: 15);

  /// Validates a WhatsApp Business phone number ID + access token pair by
  /// asking Meta for that phone number's own record. Only succeeds if the
  /// token actually has access to that phone number.
  static Future<WhatsAppVerification> verifyWhatsAppCredentials({
    required String phoneNumberId,
    required String accessToken,
  }) async {
    final uri = Uri.https(
      'graph.facebook.com',
      '/$_graphVersion/$phoneNumberId',
      {
        'fields': 'display_phone_number,verified_name',
        'access_token': accessToken,
      },
    );

    http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } catch (_) {
      throw MetaApiException(
        'Could not reach Meta. Check your internet connection and try again.',
      );
    }

    final Map<String, dynamic> body = _decode(response.body);

    if (response.statusCode != 200 || body.containsKey('error')) {
      throw MetaApiException(_extractError(body, response.statusCode));
    }

    final displayPhone = body['display_phone_number'] as String?;
    final verifiedName = body['verified_name'] as String?;

    if (displayPhone == null) {
      throw MetaApiException(
        'Meta accepted the request but did not return a phone number. Double-check the Phone Number ID.',
      );
    }

    return WhatsAppVerification(
      verifiedBusinessName: verifiedName ?? '',
      displayPhoneNumber: displayPhone,
    );
  }

  /// Validates an Instagram professional account ID + access token pair
  /// by asking Meta for that account's own public profile fields.
  static Future<InstagramVerification> verifyInstagramCredentials({
    required String igUserId,
    required String accessToken,
  }) async {
    // Instagram Login tokens start with "IG" and must use graph.instagram.com;
    // Facebook-Login / System User tokens use graph.facebook.com.
    final host = accessToken.startsWith('IG') ? 'graph.instagram.com' : 'graph.facebook.com';
    final uri = Uri.https(
      host,
      '/$_graphVersion/$igUserId',
      {
        'fields': 'username,followers_count',
        'access_token': accessToken,
      },
    );

    http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } catch (_) {
      throw MetaApiException(
        'Could not reach Meta. Check your internet connection and try again.',
      );
    }

    final Map<String, dynamic> body = _decode(response.body);

    if (response.statusCode != 200 || body.containsKey('error')) {
      throw MetaApiException(_extractError(body, response.statusCode));
    }

    final username = body['username'] as String?;
    if (username == null) {
      throw MetaApiException(
        'Meta accepted the request but did not return an Instagram username. Double-check the Business Account ID.',
      );
    }

    final followers = body['followers_count'];
    return InstagramVerification(
      username: username,
      followersCount: followers is int ? followers : 0,
    );
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  static String _extractError(Map<String, dynamic> body, int statusCode) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      final msg = error['message'] as String;
      final code = error['code'];
      if (code == 190) {
        return 'This access token is invalid or expired. Generate a new permanent token from Meta Business Manager > System Users.';
      }
      if (code == 10 || code == 200) {
        return 'This access token does not have permission to access this account. Make sure the System User was assigned "Full Control" on this asset.';
      }
      return 'Meta rejected the request: $msg';
    }
    return 'Meta rejected the request (HTTP $statusCode). Double-check the ID and access token.';
  }
}
