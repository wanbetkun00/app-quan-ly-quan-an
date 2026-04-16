import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/manager_chat_message.dart';

/// Lưu toàn bộ cuộc chat trên máy (không đồng bộ Firebase).
/// Dùng SharedPreferences — hoạt động trên cả Web, Windows, Android, iOS.
class ManagerChatStorageService {
  static const String _key = 'manager_ai_chats';

  Future<List<ManagerChatSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_key);
      if (text == null || text.trim().isEmpty) return [];
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return [];
      final raw = decoded['sessions'];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map(
            (e) =>
                ManagerChatSession.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('ManagerChatStorage.loadSessions error: $e');
      return [];
    }
  }

  Future<void> saveSessions(List<ManagerChatSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
      await prefs.setString(
        _key,
        const JsonEncoder.withIndent('  ').convert(map),
      );
    } catch (e) {
      debugPrint('ManagerChatStorage.saveSessions error: $e');
    }
  }

  Future<void> upsertSession(ManagerChatSession session) async {
    final all = await loadSessions();
    final i = all.indexWhere((s) => s.id == session.id);
    if (i >= 0) {
      all[i] = session;
    } else {
      all.add(session);
    }
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await saveSessions(all);
  }

  Future<void> deleteSession(String id) async {
    final all = await loadSessions();
    all.removeWhere((s) => s.id == id);
    await saveSessions(all);
  }
}
