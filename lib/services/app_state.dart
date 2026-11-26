import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/bot_model.dart';
import 'firestore_bots_repo.dart';

/// App-wide state, backed entirely by Firestore under `users/{uid}`:
///   users/{uid}                  profile + WhatsApp/Instagram connections
///   users/{uid}/bots/{id}        AI bots (see [FirestoreBotsRepo])
///   users/{uid}/leads/{id}       captured leads
///   users/{uid}/notifications/{id}
/// AuthGate calls [attachToUser]/[detachUser] as Firebase Auth state changes.
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final FirestoreBotsRepo _botsRepo = FirestoreBotsRepo();
  String? _uid;
  StreamSubscription<List<BotModel>>? _botsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _leadsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _rulesSub;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  // User Profile
  String userName = '';
  String userEmail = '';
  String businessName = '';
  String businessPhone = '';
  String website = '';
  String gst = '';
  String instagramHandle = '';

  // --- WhatsApp Business Account (WABA) ---
  // Credentials come from the user's own Meta Business Manager (System User
  // access token model — see MetaApiService). Display fields are fetched
  // from Meta at connect time, not typed free-text.
  bool isWabaConnected = false;
  String wabaId = '';
  String wabaPhoneNumberId = '';
  String wabaAccessToken = '';
  String wabaPhoneNumber = ''; // display_phone_number, verified by Meta
  String wabaBusinessName = ''; // verified_name, verified by Meta

  // --- Instagram Professional Account ---
  bool isInstagramConnected = false;
  String igUserId = '';
  String igAccessToken = '';
  String instagramAccount = ''; // @username, verified by Meta
  String instagramFollowers = '0'; // real followers_count from Meta

  // Live metric counters
  int wabaConversations = 0;
  int instagramConversations = 0;
  int leadsCount = 0;

  // Per-channel switch for the AI bot. Keyword auto-replies keep working
  // when this is off. Backend (functions/index.js) reads the same fields.
  // Current plan (set by admin or after a Razorpay payment).
  String planName = '';
  DateTime? planExpiresAt;

  bool wabaAiEnabled = true;
  bool igAiEnabled = true;

  /// Keyword rules: {id, keywords (a list of strings), response, channel
  /// ('all' | 'WhatsApp' | 'Instagram'), enabled}.
  List<Map<String, dynamic>> autoReplies = [];

  List<BotModel> bots = [];
  List<Map<String, dynamic>> leads = [];
  List<Map<String, dynamic>> notifications = [];

  /// Kept for main.dart; all data now loads via [attachToUser].
  Future<void> init() async {}

  void attachToUser(String uid) {
    if (_uid == uid) return;
    _cancelAll();
    _uid = uid;
    _resetLocal();
    notifyListeners();

    _botsSub = _botsRepo.watchBots(uid).listen((list) {
      bots = list;
      notifyListeners();
    });
    _userSub = _userDoc.snapshots().listen((snap) {
      _applyUserDoc(snap.data() ?? {});
      notifyListeners();
    });
    _leadsSub = _userDoc
        .collection('leads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      leads = snap.docs.map((d) => _withTime(d.data())).toList();
      leadsCount = leads.length;
      notifyListeners();
    });
    _rulesSub = _userDoc.collection('autoReplies').snapshots().listen((snap) {
      autoReplies = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      notifyListeners();
    });
    _notifsSub = _userDoc
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      notifications = snap.docs.map((d) => _withTime(d.data())).toList();
      notifyListeners();
    });
  }

  void detachUser() {
    _cancelAll();
    _uid = null;
    _resetLocal();
    notifyListeners();
  }

  void _cancelAll() {
    _botsSub?.cancel();
    _userSub?.cancel();
    _leadsSub?.cancel();
    _notifsSub?.cancel();
    _rulesSub?.cancel();
    _botsSub = _userSub = _leadsSub = _notifsSub = _rulesSub = null;
  }

  void _resetLocal() {
    autoReplies = [];
    bots = [];
    leads = [];
    notifications = [];
    leadsCount = 0;
    _applyUserDoc({});
  }

  /// Converts a stored `createdAt` Timestamp into the relative `time` label
  /// the UI shows. A pending server timestamp (local write) reads as now.
  static Map<String, dynamic> _withTime(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : DateTime.now();
    final diff = DateTime.now().difference(created);
    final String label;
    if (diff.inMinutes < 1) {
      label = 'Just now';
    } else if (diff.inHours < 1) {
      label = '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      label = '${diff.inHours}h ago';
    } else {
      label = '${diff.inDays}d ago';
    }
    return {...data, 'time': label}..remove('createdAt');
  }

  void _applyUserDoc(Map<String, dynamic> d) {
    userName = d['userName'] ?? '';
    userEmail = d['userEmail'] ?? '';
    businessName = d['businessName'] ?? '';
    businessPhone = d['businessPhone'] ?? '';
    website = d['website'] ?? '';
    gst = d['gst'] ?? '';
    instagramHandle = d['instagramHandle'] ?? '';

    isWabaConnected = d['wabaConnected'] ?? false;
    wabaId = d['wabaId'] ?? '';
    wabaPhoneNumberId = d['wabaPhoneNumberId'] ?? '';
    wabaAccessToken = d['wabaAccessToken'] ?? '';
    wabaPhoneNumber = d['wabaPhoneNumber'] ?? '';
    wabaBusinessName = d['wabaBusinessName'] ?? '';

    isInstagramConnected = d['igConnected'] ?? false;
    igUserId = d['igUserId'] ?? '';
    igAccessToken = d['igAccessToken'] ?? '';
    instagramAccount = d['igAccount'] ?? '';
    instagramFollowers = d['igFollowers'] ?? '0';

    final plan = d['plan'];
    planName = plan is Map ? '${plan['name'] ?? plan['id'] ?? ''}' : '';
    final exp = plan is Map ? plan['expiresAt'] : null;
    planExpiresAt = exp is Timestamp ? exp.toDate() : null;

    wabaAiEnabled = d['wabaAiEnabled'] ?? true;
    igAiEnabled = d['igAiEnabled'] ?? true;
    wabaConversations = (d['wabaConversations'] as num?)?.toInt() ?? 0;
    instagramConversations = (d['igConversations'] as num?)?.toInt() ?? 0;
  }

  // Writes below only touch Firestore; the live snapshot listeners above
  // update the fields and call notifyListeners() once Firestore confirms.

  Future<void> updateProfile({
    required String name,
    required String email,
    required String business,
    required String phone,
    String website = '',
    String gst = '',
  }) async {
    if (_uid == null) return;
    await _userDoc.set({
      'userName': name.trim(),
      'userEmail': email.trim(),
      'businessName': business.trim(),
      'businessPhone': phone.trim(),
      'website': website.trim(),
      'gst': gst.trim(),
    }, SetOptions(merge: true));

    addNotification(
      title: 'Profile Updated',
      desc: 'Business and account profile information updated.',
      type: 'profile',
    );
  }

  /// Persists a WhatsApp Business connection. The values passed in here
  /// must already have been verified against the live Meta Graph API
  /// (see MetaApiService.verifyWhatsAppCredentials) — this method just
  /// stores them, it does not itself validate anything.
  Future<void> connectWhatsApp({
    required String wabaId,
    required String phoneNumberId,
    required String accessToken,
    required String displayPhoneNumber,
    required String businessName,
  }) async {
    if (_uid == null) return;
    await _userDoc.set({
      'wabaConnected': true,
      'wabaId': wabaId,
      'wabaPhoneNumberId': phoneNumberId,
      'wabaAccessToken': accessToken,
      'wabaPhoneNumber': displayPhoneNumber,
      'wabaBusinessName': businessName,
    }, SetOptions(merge: true));

    addNotification(
      title: 'WhatsApp Business Connected',
      desc: 'Successfully linked $displayPhoneNumber ($businessName) to LineUp.',
      type: 'waba',
    );
  }

  Future<void> disconnectWhatsApp() async {
    if (_uid == null) return;
    await _userDoc.set({
      'wabaConnected': false,
      'wabaId': FieldValue.delete(),
      'wabaPhoneNumberId': FieldValue.delete(),
      'wabaAccessToken': FieldValue.delete(),
      'wabaPhoneNumber': FieldValue.delete(),
      'wabaBusinessName': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Persists an Instagram connection. Like [connectWhatsApp], the caller
  /// must have already verified these values against the live Graph API.
  Future<void> connectInstagram({
    required String igUserId,
    required String accessToken,
    required String username,
    required int followersCount,
  }) async {
    if (_uid == null) return;
    final account = username.startsWith('@') ? username : '@$username';
    await _userDoc.set({
      'igConnected': true,
      'igUserId': igUserId,
      'igAccessToken': accessToken,
      'igAccount': account,
      'igFollowers': _formatFollowerCount(followersCount),
    }, SetOptions(merge: true));

    addNotification(
      title: 'Instagram Account Linked',
      desc: 'Successfully connected $account to LineUp.',
      type: 'bot',
    );
  }

  Future<void> disconnectInstagram() async {
    if (_uid == null) return;
    await _userDoc.set({
      'igConnected': false,
      'igUserId': FieldValue.delete(),
      'igAccessToken': FieldValue.delete(),
      'igAccount': FieldValue.delete(),
      'igFollowers': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  static String _formatFollowerCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Future<void> setAiEnabled({required bool whatsapp, required bool value}) async {
    if (_uid == null) return;
    await _userDoc.set(
      {whatsapp ? 'wabaAiEnabled' : 'igAiEnabled': value},
      SetOptions(merge: true),
    );
  }

  Future<void> saveAutoReply({
    String? id,
    required List<String> keywords,
    required String response,
    required String channel,
    bool enabled = true,
  }) async {
    if (_uid == null) return;
    final col = _userDoc.collection('autoReplies');
    final data = {
      'keywords': keywords,
      'response': response,
      'channel': channel,
      'enabled': enabled,
    };
    if (id == null) {
      await col.add(data);
    } else {
      await col.doc(id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> setAutoReplyEnabled(String id, bool enabled) async {
    if (_uid == null) return;
    await _userDoc.collection('autoReplies').doc(id).update({'enabled': enabled});
  }

  Future<void> deleteAutoReply(String id) async {
    if (_uid == null) return;
    await _userDoc.collection('autoReplies').doc(id).delete();
  }

  Future<void> addBot(BotModel bot) async {
    if (_uid == null) return;
    await _botsRepo.createBot(_uid!, bot);
    addNotification(
      title: 'New AI Bot Deployed',
      desc: '${bot.name} is now online and ready to handle inquiries.',
      type: 'bot',
    );
  }

  Future<void> removeBot(int index) async {
    if (_uid == null || index < 0 || index >= bots.length) return;
    await _botsRepo.deleteBot(_uid!, bots[index].id);
  }

  Future<void> toggleBot(int index) async {
    if (_uid == null || index < 0 || index >= bots.length) return;
    final bot = bots[index];
    await _botsRepo.setActive(_uid!, bot.id, !bot.isActive);
  }

  Future<void> updateBot(BotModel updated) async {
    if (_uid == null) return;
    await _botsRepo.updateBot(_uid!, updated);
  }

  void addLead({
    required String name,
    required String contact,
    required String channel,
    required String intent,
    required String tag,
  }) {
    if (_uid == null) return;
    _userDoc.collection('leads').add({
      'name': name,
      'contact': contact,
      'channel': channel,
      'intent': intent,
      'tag': tag,
      'createdAt': FieldValue.serverTimestamp(),
    });
    addNotification(
      title: 'New Lead Captured',
      desc: '$name reached out via $channel: "$intent"',
      type: 'lead',
    );
  }

  void addNotification({
    required String title,
    required String desc,
    required String type,
  }) {
    if (_uid == null) return;
    _userDoc.collection('notifications').add({
      'title': title,
      'desc': desc,
      'type': type,
      'unread': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearNotifications() async {
    if (_uid == null) return;
    final snap = await _userDoc.collection('notifications').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
