import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bot_model.dart';

/// Reads/writes this user's AI bots in Firestore, under
/// `users/{uid}/bots/{botId}`.
///
/// IMPORTANT: this schema is a best-effort guess (name, role, prompt,
/// active, createdAt) carried over from an earlier recovery pass that
/// reconstructed the app from screenshots of the deployed site — it has
/// NOT been confirmed against the real documents in the Firebase
/// console. If existing bots don't show up, or show up with the wrong
/// role/prompt, open the console, look at an actual `bots` document, and
/// fix the field names in [_fromDoc] / the write methods below.
class FirestoreBotsRepo {
  CollectionReference<Map<String, dynamic>> _botsOf(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('bots');

  Stream<List<BotModel>> watchBots(String uid) {
    return _botsOf(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  BotModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final type = (data['role'] as String?) ?? 'custom';
    final rawPrompt = (data['prompt'] as String?)?.trim();

    return BotModel(
      id: doc.id,
      name: (data['name'] as String?) ?? 'AI Bot',
      description: BotModel.defaultDescriptionFor(type),
      type: type,
      isActive: (data['active'] as bool?) ?? true,
      totalConversations: (data['totalConversations'] as int?) ?? 0,
      lastActive: (data['lastActive'] as String?) ?? 'Active',
      knowledge: ((data['knowledge'] as List?) ?? []).map((e) => '$e').toList(),
      instructions: (rawPrompt == null || rawPrompt.isEmpty)
          ? BotModel.defaultInstructionsFor(type)
          : rawPrompt,
    );
  }

  Future<void> createBot(String uid, BotModel bot) {
    return _botsOf(uid).add({
      'name': bot.name,
      'role': bot.type,
      'prompt': bot.instructions,
      'knowledge': bot.knowledge,
      'active': bot.isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBot(String uid, BotModel bot) {
    return _botsOf(uid).doc(bot.id).update({
      'name': bot.name,
      'prompt': bot.instructions,
      'knowledge': bot.knowledge,
      'active': bot.isActive,
    });
  }

  Future<void> setActive(String uid, String botId, bool active) {
    return _botsOf(uid).doc(botId).update({'active': active});
  }

  Future<void> deleteBot(String uid, String botId) {
    return _botsOf(uid).doc(botId).delete();
  }
}
