class ManagerChatMessage {
  final String role; // 'user' | 'model'
  final String text;
  final DateTime at;

  ManagerChatMessage({
    required this.role,
    required this.text,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'at': at.toIso8601String(),
      };

  factory ManagerChatMessage.fromJson(Map<String, dynamic> json) {
    return ManagerChatMessage(
      role: json['role'] as String,
      text: json['text'] as String,
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ManagerChatSession {
  final String id;
  String title;
  DateTime updatedAt;
  final List<ManagerChatMessage> messages;

  ManagerChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    List<ManagerChatMessage>? messages,
  }) : messages = messages ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ManagerChatSession.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    final list = <ManagerChatMessage>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(ManagerChatMessage.fromJson(e));
        }
      }
    }
    return ManagerChatSession(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Cuộc trò chuyện',
      updatedAt: 
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
        messages: list,
      );
    }
  }
