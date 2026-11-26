class BotModel {
  final String id;
  String name;
  String description;
  bool isActive;
  final String type; // 'sales', 'support', 'leads', 'custom'
  int totalConversations;
  String lastActive;

  /// The real AI system prompt / behavior instructions for this bot.
  /// This is what will actually be sent to the AI engine once the
  /// Cloud Functions backend is live. Previously this was typed into
  /// bot_detail_sheet.dart and silently discarded on save — it is now
  /// a persisted field.
  String instructions;

  /// Business facts (pricing, hours, FAQs) the bot may use when answering.
  /// Sent to the AI with every reply by the backend.
  List<String> knowledge;

  BotModel({
    required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
    required this.type,
    this.totalConversations = 0,
    this.lastActive = 'Just now',
    String? instructions,
    List<String>? knowledge,
  })  : instructions = instructions ?? defaultInstructionsFor(type),
        knowledge = knowledge ?? [];

  static List<BotModel> get initialBots => [];

  /// Stock starting instructions for each bot role, used when a bot is
  /// created without custom instructions and as the pre-filled text in
  /// the bot detail editor.
  static String defaultInstructionsFor(String type) {
    switch (type) {
      case 'sales':
        return 'You are an AI sales assistant for our business. Guide customers through our offerings, answer product questions clearly, and collect their contact details for our sales team.';
      case 'support':
        return 'You are our customer support AI. Provide accurate, helpful answers based strictly on business FAQs. If an issue requires escalation, request supervisor review.';
      case 'leads':
        return 'You qualify incoming visitors. Inquire about their business requirements and preferred contact method, then confirm details.';
      default:
        return 'You are a dedicated AI assistant for our business across WhatsApp and Instagram. Respond politely, concisely, and accurately.';
    }
  }

  /// Stock short blurb shown in bot list cards for each role. Firestore's
  /// guessed schema (see FirestoreBotsRepo) doesn't store this, so it's
  /// always derived from the role rather than persisted.
  static String defaultDescriptionFor(String type) {
    switch (type) {
      case 'sales':
        return 'Handles product inquiries & purchases';
      case 'support':
        return 'Answers FAQs & resolves tickets';
      case 'leads':
        return 'Collects phone, email & intent';
      default:
        return 'Tailored prompt and business logic';
    }
  }
}
