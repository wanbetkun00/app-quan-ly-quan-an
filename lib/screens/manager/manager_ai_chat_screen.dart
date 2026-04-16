import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/employee_model.dart';
import '../../models/enums.dart';
import '../../models/manager_chat_message.dart';
import '../../models/menu_item.dart';
import '../../models/shift_model.dart';
import '../../models/table_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/manager_ai_service.dart';
import '../../services/manager_chat_storage_service.dart';
import '../../theme/app_theme.dart';

class ManagerAiChatScreen extends StatefulWidget {
  const ManagerAiChatScreen({super.key});

  @override
  State<ManagerAiChatScreen> createState() => _ManagerAiChatScreenState();
}

class _ManagerAiChatScreenState extends State<ManagerAiChatScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _storage = ManagerChatStorageService();
  final _contextService = ManagerAiContextService();
  final _gemini = GeminiManagerChatService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<ManagerChatSession> _sessions = [];
  ManagerChatSession? _session;
  bool _sending = false;
  bool _loadingSessions = true;

  static final _actionBlockRegex = RegExp(
    r'\[ACTION\]([\s\S]*?)\[/ACTION\]',
  );

  static const _system = '''
Bạn là trợ lý AI cho quản lý nhà hàng. Trả lời bằng tiếng Việt.
TUYỆT ĐỐI KHÔNG dùng ký tự markdown: cấm **, *, #, ```, >. Chỉ viết text thuần.
Hạn chế tối đa dùng gạch đầu dòng (-). Ưu tiên viết liền mạch, dùng số thứ tự (1. 2. 3.) khi liệt kê.
Dùng đúng tên món, giá từ khối "DỮ LIỆU NHÀ HÀNG". Món ăn tính theo "phần", thức uống tính theo "lon". Tiền VND ghi dạng 75.000 vnđ.

Khi gợi ý combo, đánh số thứ tự mỗi combo và viết gọn theo mẫu:
1. Tên combo: [tên]
   Gồm: [tên món 1] + [tên món 2] + ...
   Giá gốc: [tổng giá lẻ]
   Giá bán gợi ý: [giá combo]
Không ghi số lượng (1 phần, 1 lon) trong combo. Không giải thích dài dòng, không ghi mục tiêu, không ghi lý do.

Hỗ trợ: phân tích doanh thu, gợi ý combo, sắp xếp ca, đề xuất món mới.

KHI NGƯỜI DÙNG YÊU CẦU THAO TÁC DỮ LIỆU (thêm/sửa/xóa), bạn PHẢI kèm block hành động theo mẫu (KHÔNG dùng backtick):
[ACTION]{"type":"<action_type>","data":{...}}[/ACTION]

Các action_type và data:
- add_menu_item: {"name":"Tên","price":55000,"category":"food hoặc drink"}
- update_menu_item: {"id":123,"name":"Tên mới","price":60000}
- delete_menu_item: {"id":123,"name":"Tên"}
- add_employee: {"name":"Tên","username":"taikhoan","password":"matkhau","role":"staff hoặc cashier hoặc manager"}
- update_employee: {"id":"emp_id","name":"Tên mới","role":"staff"}
- delete_employee: {"id":"emp_id","name":"Tên"}
- add_shift: {"employeeName":"Tên ca","date":"yyyy-MM-dd","startTime":"HH:mm","endTime":"HH:mm","maxEmployees":2}
- update_shift: {"id":"shift_id","date":"yyyy-MM-dd","startTime":"HH:mm","endTime":"HH:mm"}
- delete_shift: {"id":"shift_id"}
- add_table: {"name":"Tên bàn"}
- update_table: {"id":5,"name":"Tên mới"}
- delete_table: {"id":5,"name":"Tên bàn"}

Mỗi thao tác 1 block [ACTION]...[/ACTION] riêng. Dùng đúng id từ dữ liệu. Nếu thiếu thông tin, hỏi lại.
Khi quản lý yêu cầu tạo combo, hãy tạo luôn action block add_menu_item cho combo đó.
''';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final list = await _storage.loadSessions();
    if (!mounted) return;
    setState(() {
      _sessions = list;
      _loadingSessions = false;
      _session ??= list.isNotEmpty ? list.first : _newSession();
    });
  }

  ManagerChatSession _newSession() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return ManagerChatSession(
      id: id,
      title: 'Cuộc trò chuyện mới',
      updatedAt: DateTime.now(),
    );
  }

  void _startNewChat() {
    final s = _newSession();
    setState(() => _session = s);
    _scaffoldKey.currentState?.closeEndDrawer();
    _textCtrl.clear();
  }

  void _selectSession(ManagerChatSession s) {
    setState(() => _session = s);
    _scaffoldKey.currentState?.closeEndDrawer();
    _scrollToBottom();
  }

  Future<void> _deleteSession(ManagerChatSession s) async {
    await _storage.deleteSession(s.id);
    if (!mounted) return;
    final rest = await _storage.loadSessions();
    setState(() {
      _sessions = rest;
      if (_session?.id == s.id) {
        _session = rest.isNotEmpty ? rest.first : _newSession();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty || _sending) return;

    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    _session ??= _newSession();
    final session = _session!;

    final userMsg = ManagerChatMessage(
      role: 'user',
      text: raw,
      at: DateTime.now(),
    );
    session.messages.add(userMsg);
    if (session.title == 'Cuộc trò chuyện mới' || session.title.length < 3) {
      session.title = raw.length > 42 ? '${raw.substring(0, 42)}…' : raw;
    }
    session.updatedAt = DateTime.now();
    _textCtrl.clear();
    setState(() => _sending = true);
    _scrollToBottom();

    try {
      try {
        await _storage.upsertSession(session);
      } catch (e) {
        debugPrint('Lỗi lưu session: $e');
      }

      final restaurantContext = await _contextService
          .buildContext(provider)
          .timeout(const Duration(seconds: 15));

      final rawReply = await _gemini.generateReply(
        systemInstruction: _system,
        restaurantContext: restaurantContext,
        historyIncludingLatestUser: session.messages,
      );
      final replyText = _stripMarkdown(rawReply);

      session.messages.add(
        ManagerChatMessage(
          role: 'model',
          text: replyText,
          at: DateTime.now(),
        ),
      );
      session.updatedAt = DateTime.now();
      try {
        await _storage.upsertSession(session);
      } catch (e) {
        debugPrint('Lỗi lưu session sau reply: $e');
      }
    } on TimeoutException {
      _addErrorReply(session, 'Quá thời gian chờ. Vui lòng thử lại.');
    } catch (e) {
      debugPrint('Lỗi gọi AI: $e');
      _addErrorReply(session, '$e');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
      _refreshSessionList(session.id);
      _scrollToBottom();
    }
  }

  void _addErrorReply(ManagerChatSession session, String errorText) {
    session.messages.add(
      ManagerChatMessage(
        role: 'model',
        text: '⚠️ $errorText',
        at: DateTime.now(),
      ),
    );
    session.updatedAt = DateTime.now();
    _storage.upsertSession(session).catchError((_) {});
  }

  Future<void> _refreshSessionList(String currentId) async {
    try {
      final rest = await _storage.loadSessions();
      if (!mounted) return;
      setState(() {
        _sessions = rest;
        final idx = rest.indexWhere((x) => x.id == currentId);
        if (idx >= 0) {
          _session = rest[idx];
        }
      });
    } catch (e) {
      debugPrint('Lỗi refresh session list: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Tự động xóa Markdown, giữ lại block [ACTION]...[/ACTION]
  // ---------------------------------------------------------------------------
  static String _stripMarkdown(String text) {
    var s = text;
    final preserved = <String, String>{};
    int idx = 0;
    s = s.replaceAllMapped(_actionBlockRegex, (m) {
      final key = '\x00BLOCK${idx++}\x00';
      preserved[key] = m.group(0)!;
      return key;
    });

    s = s.replaceAll(RegExp(r'#{1,6}\s*'), '');
    s = s.replaceAllMapped(
        RegExp(r'\*{1,3}(.+?)\*{1,3}'), (m) => m.group(1)!);
    s = s.replaceAll(RegExp(r'\*{1,3}'), '');
    s = s.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);
    s = s.replaceAll(RegExp(r'^>\s?', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^\*\s', multiLine: true), '- ');

    for (final entry in preserved.entries) {
      s = s.replaceAll(entry.key, entry.value);
    }
    return s.trim();
  }

  // ---------------------------------------------------------------------------
  // Parse tin nhắn model: tách text thuần và action blocks
  // ---------------------------------------------------------------------------
  Widget _buildModelMessage(String text) {
    final matches = _actionBlockRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return SelectableText(
        text,
        style: const TextStyle(color: AppTheme.darkGreyText, height: 1.35),
      );
    }

    final children = <Widget>[];
    int lastEnd = 0;
    for (final match in matches) {
      final before = text.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) {
        children.add(SelectableText(
          before,
          style: const TextStyle(color: AppTheme.darkGreyText, height: 1.35),
        ));
        children.add(const SizedBox(height: 8));
      }
      final jsonStr = match.group(1)?.trim() ?? '';
      try {
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final type = parsed['type'] as String? ?? '';
        final data = parsed['data'] as Map<String, dynamic>? ?? {};
        children.add(_ActionCard(
          actionType: type,
          data: data,
          onConfirm: () => _executeAction(type, data),
        ));
        children.add(const SizedBox(height: 8));
      } catch (_) {
        children.add(SelectableText(
          jsonStr,
          style: const TextStyle(color: AppTheme.darkGreyText, height: 1.35),
        ));
      }
      lastEnd = match.end;
    }
    final after = text.substring(lastEnd).trim();
    if (after.isNotEmpty) {
      children.add(SelectableText(
        after,
        style: const TextStyle(color: AppTheme.darkGreyText, height: 1.35),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  // ---------------------------------------------------------------------------
  // Thực thi action CRUD qua RestaurantProvider
  // ---------------------------------------------------------------------------
  Future<void> _executeAction(
      String type, Map<String, dynamic> data) async {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    final description = _ActionCard.describe(type, data);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_actionTitle(type)),
        content: Text(description),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    bool success = false;
    try {
      switch (type) {
        // ── Menu ──
        case 'add_menu_item':
          final catStr = data['category'] as String? ?? 'food';
          success = await provider.addMenuItem(MenuItem(
            id: DateTime.now().millisecondsSinceEpoch,
            name: data['name'] as String? ?? '',
            price: (data['price'] as num?)?.toDouble() ?? 0,
            category: catStr == 'drink' ? MenuCategory.drink : MenuCategory.food,
          ));
        case 'update_menu_item':
          final id = (data['id'] as num?)?.toInt() ?? 0;
          final existing = provider.menu.cast<MenuItem?>().firstWhere(
              (m) => m!.id == id,
              orElse: () => null);
          if (existing != null) {
            final catStr = data['category'] as String?;
            success = await provider.updateMenuItem(
              id,
              MenuItem(
                id: id,
                name: data['name'] as String? ?? existing.name,
                price: (data['price'] as num?)?.toDouble() ?? existing.price,
                category: catStr != null
                    ? (catStr == 'drink'
                        ? MenuCategory.drink
                        : MenuCategory.food)
                    : existing.category,
                imageUrl: existing.imageUrl,
              ),
            );
          }
        case 'delete_menu_item':
          final id = (data['id'] as num?)?.toInt() ?? 0;
          success = await provider.deleteMenuItem(id);

        // ── Nhân viên ──
        case 'add_employee':
          final roleStr = data['role'] as String? ?? 'staff';
          final role = switch (roleStr) {
            'manager' => UserRole.manager,
            'cashier' => UserRole.cashier,
            _ => UserRole.staff,
          };
          success = await provider.addEmployee(EmployeeModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            username: data['username'] as String? ?? '',
            name: data['name'] as String? ?? '',
            password: data['password'] as String? ?? '123456',
            role: role,
          ));
        case 'update_employee':
          final id = data['id'] as String? ?? '';
          final allEmployees = await provider.getEmployees();
          final existing = allEmployees.cast<EmployeeModel?>().firstWhere(
              (e) => e!.id == id,
              orElse: () => null);
          if (existing != null) {
            final roleStr = data['role'] as String?;
            UserRole? role;
            if (roleStr != null) {
              role = switch (roleStr) {
                'manager' => UserRole.manager,
                'cashier' => UserRole.cashier,
                _ => UserRole.staff,
              };
            }
            success = await provider.updateEmployee(existing.copyWith(
              name: data['name'] as String? ?? existing.name,
              role: role ?? existing.role,
              updatedAt: DateTime.now(),
            ));
          }
        case 'delete_employee':
          final id = data['id'] as String? ?? '';
          success = await provider.deleteEmployee(id);

        // ── Ca làm ──
        case 'add_shift':
          final dateParts = (data['date'] as String? ?? '').split('-');
          final startParts = (data['startTime'] as String? ?? '08:00').split(':');
          final endParts = (data['endTime'] as String? ?? '17:00').split(':');
          if (dateParts.length == 3 &&
              startParts.length == 2 &&
              endParts.length == 2) {
            success = await provider.addShift(ShiftModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              employeeId: ShiftModel.openSlotEmployeeId,
              employeeName: data['employeeName'] as String? ?? 'Ca mở',
              date: DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              ),
              startTime: TimeOfDay(
                hour: int.parse(startParts[0]),
                minute: int.parse(startParts[1]),
              ),
              endTime: TimeOfDay(
                hour: int.parse(endParts[0]),
                minute: int.parse(endParts[1]),
              ),
              openSlot: true,
              maxEmployees: (data['maxEmployees'] as num?)?.toInt() ?? 1,
            ));
          }
        case 'update_shift':
          final id = data['id'] as String? ?? '';
          final allShifts = await provider.getShifts();
          final existing = allShifts.cast<ShiftModel?>().firstWhere(
              (s) => s!.id == id,
              orElse: () => null);
          if (existing != null) {
            TimeOfDay? start;
            TimeOfDay? end;
            DateTime? date;
            final dateStr = data['date'] as String?;
            if (dateStr != null) {
              final p = dateStr.split('-');
              if (p.length == 3) {
                date = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
              }
            }
            final startStr = data['startTime'] as String?;
            if (startStr != null) {
              final p = startStr.split(':');
              if (p.length == 2) {
                start = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
              }
            }
            final endStr = data['endTime'] as String?;
            if (endStr != null) {
              final p = endStr.split(':');
              if (p.length == 2) {
                end = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
              }
            }
            success = await provider.updateShift(existing.copyWith(
              date: date,
              startTime: start,
              endTime: end,
              maxEmployees: (data['maxEmployees'] as num?)?.toInt(),
            ));
          }
        case 'delete_shift':
          final id = data['id'] as String? ?? '';
          success = await provider.deleteShift(id);

        // ── Bàn ──
        case 'add_table':
          final tables = provider.tables;
          final nextId =
              tables.isEmpty ? 1 : tables.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
          success = await provider.addTable(TableModel(
            id: nextId,
            name: data['name'] as String? ?? 'Bàn $nextId',
          ));
        case 'update_table':
          final id = (data['id'] as num?)?.toInt() ?? 0;
          final existing = provider.tables.cast<TableModel?>().firstWhere(
              (t) => t!.id == id,
              orElse: () => null);
          if (existing != null) {
            success = await provider.updateTable(TableModel(
              id: id,
              name: data['name'] as String? ?? existing.name,
              status: existing.status,
              currentOrderId: existing.currentOrderId,
            ));
          }
        case 'delete_table':
          final id = (data['id'] as num?)?.toInt() ?? 0;
          success = await provider.deleteTable(id);
      }
    } catch (e) {
      debugPrint('Lỗi thực thi action $type: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Thành công!' : 'Thao tác thất bại.'),
      backgroundColor: success ? AppTheme.statusGreen : AppTheme.statusRed,
    ));
  }

  String _actionTitle(String type) {
    return switch (type) {
      'add_menu_item' => 'Thêm món mới',
      'update_menu_item' => 'Cập nhật món',
      'delete_menu_item' => 'Xóa món',
      'add_employee' => 'Thêm nhân viên',
      'update_employee' => 'Cập nhật nhân viên',
      'delete_employee' => 'Xóa nhân viên',
      'add_shift' => 'Thêm ca làm',
      'update_shift' => 'Cập nhật ca làm',
      'delete_shift' => 'Xóa ca làm',
      'add_table' => 'Thêm bàn',
      'update_table' => 'Cập nhật bàn',
      'delete_table' => 'Xóa bàn',
      _ => 'Thao tác',
    };
  }

  // ---------------------------------------------------------------------------
  // Build & helpers
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final session = _session;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              color: AppTheme.primaryOrange,
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Lịch sử trò chuyện',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FilledButton.icon(
                onPressed: _startNewChat,
                icon: const Icon(Icons.add_comment),
                label: const Text('Cuộc trò chuyện mới'),
              ),
            ),
            Expanded(
              child: _loadingSessions
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (context, i) {
                        final s = _sessions[i];
                        final selected = session?.id == s.id;
                        return ListTile(
                          selected: selected,
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            s.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _formatTime(s.updatedAt),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () => _selectSession(s),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                      'Bạn muốn xóa cuộc trò chuyện này?'),
                                  content: const Text(
                                    'Bạn sẽ không thể khôi phục lại cuộc trò chuyện này.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && context.mounted) {
                                await _deleteSession(s);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Về Quản lý',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Chatbot AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Lịch sử chat',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: session == null
                ? const SizedBox.shrink()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount:
                        session.messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_sending && i == session.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Đang suy nghĩ…'),
                            ],
                          ),
                        );
                      }
                      final m = session.messages[i];
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.sizeOf(context).width * 0.88,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppTheme.primaryOrange
                                    .withValues(alpha: 0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft:
                                  Radius.circular(isUser ? 14 : 4),
                              bottomRight:
                                  Radius.circular(isUser ? 4 : 14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isUser
                              ? SelectableText(
                                  m.text,
                                  style: const TextStyle(
                                    color: AppTheme.darkGreyText,
                                    height: 1.35,
                                  ),
                                )
                              : _buildModelMessage(m.text),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Material(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Nhập câu hỏi…',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                      tooltip: 'Gửi',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final d = t.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// Widget hiện thẻ hành động CRUD với nút xác nhận
// =============================================================================
class _ActionCard extends StatelessWidget {
  final String actionType;
  final Map<String, dynamic> data;
  final VoidCallback onConfirm;

  const _ActionCard({
    required this.actionType,
    required this.data,
    required this.onConfirm,
  });

  static String describe(String type, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? '';
    final price = (data['price'] as num?)?.toDouble();
    final id = data['id'];

    return switch (type) {
      'add_menu_item' =>
        'Thêm món "$name" — ${price?.toStringAsFixed(0) ?? 0}đ (${data['category'] ?? 'food'})',
      'update_menu_item' =>
        'Cập nhật món #$id${name.isNotEmpty ? ' → "$name"' : ''}${price != null ? ' — ${price.toStringAsFixed(0)}đ' : ''}',
      'delete_menu_item' => 'Xóa món "$name" (#$id)',
      'add_employee' =>
        'Thêm nhân viên "$name" — tài khoản: ${data['username'] ?? ''} — vai trò: ${data['role'] ?? 'staff'}',
      'update_employee' =>
        'Cập nhật nhân viên #$id${name.isNotEmpty ? ' → "$name"' : ''}',
      'delete_employee' => 'Xóa nhân viên "$name" (#$id)',
      'add_shift' =>
        'Thêm ca làm ${data['date'] ?? ''} (${data['startTime'] ?? ''} - ${data['endTime'] ?? ''}) — tối đa ${data['maxEmployees'] ?? 1} người',
      'update_shift' =>
        'Cập nhật ca #$id — ${data['date'] ?? ''} (${data['startTime'] ?? ''} - ${data['endTime'] ?? ''})',
      'delete_shift' => 'Xóa ca làm #$id',
      'add_table' => 'Thêm bàn "$name"',
      'update_table' => 'Cập nhật bàn #$id${name.isNotEmpty ? ' → "$name"' : ''}',
      'delete_table' => 'Xóa bàn "$name" (#$id)',
      _ => 'Thao tác: $type',
    };
  }

  IconData get _icon {
    if (actionType.contains('menu_item')) return Icons.restaurant_menu;
    if (actionType.contains('employee')) return Icons.person;
    if (actionType.contains('shift')) return Icons.schedule;
    if (actionType.contains('table')) return Icons.table_bar;
    return Icons.settings;
  }

  Color _accentColor(String type) {
    if (type.startsWith('delete')) return AppTheme.statusRed;
    if (type.startsWith('update')) return Colors.blue;
    return AppTheme.primaryOrange;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(actionType);
    final desc = describe(actionType, data);
    final isDelete = actionType.startsWith('delete');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: accent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: AppTheme.darkGreyText),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: onConfirm,
            icon: Icon(isDelete ? Icons.delete : Icons.check, size: 18),
            label: Text(isDelete ? 'Xóa' : 'Xác nhận'),
            style: FilledButton.styleFrom(
              backgroundColor: accent.withValues(alpha: 0.15),
              foregroundColor: accent,
            ),
          ),
        ],
      ),
    );
  }
}
