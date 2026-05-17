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

  static const List<_ShiftSlotPreset> _scheduleSlots = <_ShiftSlotPreset>[
    _ShiftSlotPreset(
      id: 'morning',
      start: TimeOfDay(hour: 6, minute: 30),
      end: TimeOfDay(hour: 11, minute: 30),
    ),
    _ShiftSlotPreset(
      id: 'noon',
      start: TimeOfDay(hour: 11, minute: 30),
      end: TimeOfDay(hour: 17, minute: 30),
    ),
    _ShiftSlotPreset(
      id: 'evening',
      start: TimeOfDay(hour: 17, minute: 30),
      end: TimeOfDay(hour: 23, minute: 30),
    ),
  ];

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
Khi nói về ca làm, luôn dùng mẫu: "ca sáng/trưa/tối thứ X (dd/MM/yyyy)". Không dùng ngày kiểu yyyy-MM-dd trong phần trả lời cho quản lý.

KHI NGƯỜI DÙNG YÊU CẦU THAO TÁC DỮ LIỆU (thêm/sửa/xóa), bạn PHẢI kèm block hành động theo mẫu (KHÔNG dùng backtick):
[ACTION]{"type":"<action_type>","data":{...}}[/ACTION]

Các action_type và data:
- add_menu_item: {"name":"Tên","price":55000,"category":"food hoặc drink"}
- update_menu_item: {"id":123,"name":"Tên mới","price":60000}
- delete_menu_item: {"id":123,"name":"Tên món"}
- add_employee: {"name":"Tên","username":"taikhoan","password":"matkhau","role":"staff hoặc cashier hoặc manager"}
- update_employee: {"id":"emp_id","name":"Tên mới","role":"staff"}
- delete_employee: {"id":"emp_id","name":"Tên nhân viên"}
- add_shift: {"employeeName":"Tên ca","date":"yyyy-MM-dd","startTime":"HH:mm","endTime":"HH:mm","maxEmployees":2}
- update_shift: {"id":"shift_id","date":"yyyy-MM-dd","startTime":"HH:mm","endTime":"HH:mm"}
- delete_shift: {"id":"shift_id"}
- add_table: {"name":"Tên bàn"}
- update_table: {"id":5,"name":"Tên mới"}
- delete_table: {"id":5,"name":"Bàn 5"} (Ví dụ: "xóa bàn 5")
- delete_table: {"id":15,"name":"Bàn 15"} (Ví dụ: "xóa bàn 15")
- delete_table: {"id":18,"name":"Bàn 18"} (Ví dụ: "xóa bàn 18")

Mỗi thao tác 1 block [ACTION]...[/ACTION] riêng. TỰ ĐỘNG tra cứu id từ "DỮ LIỆU NHÀ HÀNG" dựa trên tên/số bàn/tên món mà người dùng cung cấp. PHẢI điền đầy đủ cả "id" và "name" vào khối JSON data. KHÔNG được để id null hoặc name rỗng nếu thông tin đã có trong dữ liệu.
Khi quản lý yêu cầu tạo combo, hãy tạo luôn action block add_menu_item cho combo đó.

Hỗ trợ xếp lịch làm việc cân bằng từ danh sách ca rảnh nhân viên:
- auto_schedule_shifts: {"registrations":"Khang: sáng t3 t4 t5 trưa t3 t6 cn; Linh: sáng t2 t6","weekStart":"yyyy-MM-dd (tùy chọn)"}
Quy tắc: ưu tiên cân bằng số ca giữa nhân viên, tránh trùng giờ trong cùng tuần.
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
  Widget _buildModelMessage({
    required ManagerChatMessage message,
    required int messageIndex,
  }) {
    final text = message.text;
    final matches = _actionBlockRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return SelectableText(
        text,
        style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
      );
    }

    final children = <Widget>[];
    int lastEnd = 0;
    for (final match in matches) {
      final before = text.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) {
        children.add(SelectableText(
          before,
          style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
        ));
        children.add(const SizedBox(height: 12));
      }
      final jsonStr = match.group(1)?.trim() ?? '';
      final actionKey = 'action_${match.start}_${jsonStr.hashCode}';
      try {
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final type = parsed['type'] as String? ?? '';
        final data = parsed['data'] as Map<String, dynamic>? ?? {};
        children.add(_ActionCard(
          key: ValueKey(actionKey),
          actionType: type,
          data: data,
          onConfirm: () => _executeAction(type, data),
          initialSuccess: message.completedActionKeys.contains(actionKey),
          onSuccess: () {
            final session = _session;
            if (session == null) return;
            if (messageIndex < 0 || messageIndex >= session.messages.length) {
              return;
            }
            final current = session.messages[messageIndex];
            if (current.completedActionKeys.contains(actionKey)) return;
            session.messages[messageIndex] = ManagerChatMessage(
              role: current.role,
              text: current.text,
              at: current.at,
              completedActionKeys: [
                ...current.completedActionKeys,
                actionKey,
              ],
            );
            unawaited(_storage.upsertSession(session));
          },
        ));
        children.add(const SizedBox(height: 12));
      } catch (_) {
        children.add(SelectableText(
          jsonStr,
          style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
        ));
      }
      lastEnd = match.end;
    }
    final after = text.substring(lastEnd).trim();
    if (after.isNotEmpty) {
      children.add(SelectableText(
        after,
        style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
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
  Future<bool> _executeAction(
      String type, Map<String, dynamic> data) async {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    final description = _ActionCard.describe(type, data);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type.startsWith('delete') ? 'Xác nhận ${description.toLowerCase()}' : _actionTitle(type)),
        content: Text(type.startsWith('delete') ? 'Bạn có chắc chắn muốn thực hiện hành động này?' : description),
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
    if (confirmed != true || !mounted) return false;

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
          break;
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
          break;
        case 'delete_menu_item':
          final id = (data['id'] as num?)?.toInt() ?? 0;
          success = await provider.deleteMenuItem(id);
          break;

        // ── Nhân viên ──
        case 'add_employee':
          final roleStr =
              (data['role'] as String? ?? 'staff').trim().toLowerCase();
          final username = (data['username'] as String? ?? '').trim();
          final name = (data['name'] as String? ?? '').trim();
          if (username.isEmpty || name.isEmpty) {
            success = false;
            break;
          }
          final role = switch (roleStr) {
            'manager' => UserRole.manager,
            'cashier' => UserRole.cashier,
            _ => UserRole.staff,
          };
          success = await provider.addEmployee(EmployeeModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            username: username,
            name: name,
            password: data['password'] as String? ?? '123456',
            role: role,
          ));
          break;
        case 'update_employee':
          final id = await _resolveEmployeeIdFromActionData(provider, data);
          if (id == null) {
            success = false;
            break;
          }
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
          break;
        case 'delete_employee':
          final id = await _resolveEmployeeIdFromActionData(provider, data);
          if (id == null) {
            success = false;
            break;
          }
          success = await provider.deleteEmployee(id);
          break;

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
          break;
        case 'auto_schedule_shifts':
          final registrations = (data['registrations'] as String? ?? '').trim();
          final weekStart = (data['weekStart'] as String?)?.trim();
          final requiredPerShift = data['requiredPerShift'] is Map
              ? Map<String, dynamic>.from(data['requiredPerShift'] as Map)
              : null;
          success = await _autoScheduleShiftsFromRegistrations(
            provider: provider,
            registrationsText: registrations,
            weekStart: weekStart,
            requiredPerShiftRaw: requiredPerShift,
          );
          break;
        case 'update_shift':
          final existing = await _resolveShiftFromActionData(provider, data);
          if (existing != null) {
            TimeOfDay? start;
            TimeOfDay? end;
            DateTime? date;
            final dateStr = data['date'] as String?;
            if (dateStr != null) {
              date = _tryParseDateFlexible(dateStr);
            }
            final startStr = data['startTime'] as String?;
            if (startStr != null) {
              start = _tryParseTimeFlexible(startStr);
            }
            final endStr = data['endTime'] as String?;
            if (endStr != null) {
              end = _tryParseTimeFlexible(endStr);
            }
            success = await provider.updateShift(existing.copyWith(
              date: date,
              startTime: start,
              endTime: end,
              maxEmployees: (data['maxEmployees'] as num?)?.toInt(),
            ));
          }
          break;
        case 'delete_shift':
          final existing = await _resolveShiftFromActionData(provider, data);
          if (existing == null) {
            success = false;
            break;
          }
          success = await provider.deleteShift(existing.id);
          break;

        // ── Bàn ──
        case 'add_table':
          final tables = provider.tables;
          final nextId =
              tables.isEmpty ? 1 : tables.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
          success = await provider.addTable(TableModel(
            id: nextId,
            name: data['name'] as String? ?? 'Bàn $nextId',
          ));
          break;
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
          break;
        case 'delete_table':
          final id = (data['id'] as num?)?.toInt() ?? 0;
          success = await provider.deleteTable(id);
          break;
        default:
          success = false;
          break;
      }
    } catch (e) {
      debugPrint('Lỗi thực thi action $type: $e');
    }

    if (!mounted) return success;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Thành công!' : 'Thao tác thất bại.'),
      backgroundColor: success ? AppTheme.statusGreen : AppTheme.statusRed,
    ));
    return success;
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
      'auto_schedule_shifts' => 'Xếp lịch làm việc tự động',
      'update_shift' => 'Cập nhật ca làm',
      'delete_shift' => 'Xóa ca làm',
      'add_table' => 'Thêm bàn',
      'update_table' => 'Cập nhật bàn',
      'delete_table' => 'Xóa bàn',
      _ => 'Thao tác',
    };
  }

  Future<String?> _resolveEmployeeIdFromActionData(
    RestaurantProvider provider,
    Map<String, dynamic> data,
  ) async {
    final rawId = (data['id'] as String? ?? '').trim();
    if (rawId.isNotEmpty) {
      final employees = await provider.getEmployees();
      final byId = employees.where((e) => e.id == rawId);
      if (byId.isNotEmpty) return byId.first.id;
      final byUsername = employees.where(
        (e) => e.username.toLowerCase() == rawId.toLowerCase(),
      );
      if (byUsername.isNotEmpty) return byUsername.first.id;
    }

    final rawUsername = (data['username'] as String? ?? '').trim();
    if (rawUsername.isNotEmpty) {
      final employees = await provider.getEmployees();
      final byUsername = employees.where(
        (e) => e.username.toLowerCase() == rawUsername.toLowerCase(),
      );
      if (byUsername.isNotEmpty) return byUsername.first.id;
    }

    final rawName = (data['name'] as String? ?? '').trim();
    if (rawName.isNotEmpty) {
      final employees = await provider.getEmployees();
      final byName = employees.where(
        (e) => e.name.toLowerCase() == rawName.toLowerCase(),
      );
      if (byName.isNotEmpty) return byName.first.id;
    }
    return null;
  }

  Future<ShiftModel?> _resolveShiftFromActionData(
    RestaurantProvider provider,
    Map<String, dynamic> data,
  ) async {
    final allShifts = await provider.getShifts();
    if (allShifts.isEmpty) return null;

    final rawId = (data['id'] as String? ?? '').trim();
    if (rawId.isNotEmpty) {
      final exact = allShifts.where((s) => s.id == rawId);
      if (exact.isNotEmpty) return exact.first;
    }

    final targetDate = _tryParseDateFlexible(data['date']?.toString());
    final targetName = _normalizeText(
      data['employeeName']?.toString() ?? data['name']?.toString() ?? '',
    );

    TimeOfDay? oldStart;
    TimeOfDay? oldEnd;
    String idHintName = '';
    DateTime? idHintDate;
    if (rawId.contains('_')) {
      final parts = rawId.split('_');
      if (parts.isNotEmpty) {
        idHintDate = _tryParseDateFlexible(parts[0]);
      }
      if (parts.length >= 2 && parts[1].contains('-')) {
        final range = parts[1].split('-');
        if (range.length == 2) {
          oldStart = _tryParseTimeFlexible(range[0]);
          oldEnd = _tryParseTimeFlexible(range[1]);
        }
      }
      if (parts.length >= 3) {
        idHintName = _normalizeText(parts.sublist(2).join('_'));
      }
    }

    final candidates = allShifts.where((s) {
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      if (targetDate != null) {
        final d = DateTime(targetDate.year, targetDate.month, targetDate.day);
        if (day != d) return false;
      } else if (idHintDate != null) {
        final d = DateTime(idHintDate.year, idHintDate.month, idHintDate.day);
        if (day != d) return false;
      }

      final shiftName = _normalizeText(s.employeeName);
      if (targetName.isNotEmpty && !shiftName.contains(targetName)) {
        return false;
      }
      if (targetName.isEmpty &&
          idHintName.isNotEmpty &&
          !shiftName.contains(idHintName)) {
        return false;
      }
      if (oldStart != null &&
          oldEnd != null &&
          (s.startTime.hour != oldStart.hour ||
              s.startTime.minute != oldStart.minute ||
              s.endTime.hour != oldEnd.hour ||
              s.endTime.minute != oldEnd.minute)) {
        return false;
      }
      return true;
    }).toList();

    if (candidates.isNotEmpty) return candidates.first;
    return null;
  }

  DateTime? _tryParseDateFlexible(String? raw) {
    final input = (raw ?? '').trim();
    if (input.isEmpty) return null;
    final iso = DateTime.tryParse(input);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    final cleaned = input
        .toLowerCase()
        .replaceAll('ngày', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('.', '/')
        .replaceAll('-', '/');
    final parts = cleaned.split('/');
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a == null || b == null || c == null) return null;
      if (a > 1900) return DateTime(a, b, c);
      return DateTime(c, b, a);
    }
    return null;
  }

  TimeOfDay? _tryParseTimeFlexible(String? raw) {
    final input = (raw ?? '').trim().toLowerCase();
    if (input.isEmpty) return null;
    final cleaned = input
        .replaceAll('h', ':')
        .replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = cleaned.split(':').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    if (parts.length == 1) {
      final h = int.tryParse(parts[0]);
      if (h == null || h < 0 || h > 23) return null;
      return TimeOfDay(hour: h, minute: 0);
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _normalizeText(String input) {
    final s = input.trim().toLowerCase();
    if (s.isEmpty) return s;
    return s
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');
  }

  Future<bool> _autoScheduleShiftsFromRegistrations({
    required RestaurantProvider provider,
    required String registrationsText,
    String? weekStart,
    Map<String, dynamic>? requiredPerShiftRaw,
  }) async {
    if (registrationsText.trim().isEmpty) {
      return false;
    }

    final allEmployees = await provider.getEmployees();
    if (allEmployees.isEmpty) return false;

    final weekMonday = _resolveWeekMonday(weekStart);
    final weekDays = List<DateTime>.generate(
      7,
      (i) => DateTime(
        weekMonday.year,
        weekMonday.month,
        weekMonday.day,
      ).add(Duration(days: i)),
    );

    final availabilityByEmployee =
        _parseRegistrationsByEmployee(registrationsText);
    if (availabilityByEmployee.isEmpty) return false;
    final requiredMatrix =
        _normalizeRequiredPerShift(requiredPerShiftRaw, weekMonday) ??
            await _askRequiredPerShiftDialog(weekMonday);
    if (requiredMatrix == null) return false;

    final employeeByName = <String, EmployeeModel>{};
    for (final e in allEmployees) {
      employeeByName[e.name.trim().toLowerCase()] = e;
    }

    final weekStartDate = weekDays.first;
    final weekEndDate = weekDays.last;
    final existingShifts = await provider.getShifts();
    final shiftsInWeek = existingShifts.where((s) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      return !d.isBefore(weekStartDate) && !d.isAfter(weekEndDate);
    }).toList();

    final baseAssignedCount = <String, int>{};
    for (final e in allEmployees) {
      baseAssignedCount[e.id] = shiftsInWeek.where((s) {
        return s.involvesEmployee(e.id) && !s.openSlot;
      }).length;
    }
    final plannedAssignedCount = <String, int>{};
    final assignedDateByEmployee = <String, Set<String>>{};
    final plan = <_PlannedShift>[];

    for (final day in weekDays) {
      for (final slot in _scheduleSlots) {
        final requiredCount = requiredMatrix[day.weekday]?[slot.id] ?? 0;
        if (requiredCount <= 0) continue;
        final candidates = <EmployeeModel>[];
        for (final entry in availabilityByEmployee.entries) {
          final employee = employeeByName[entry.key];
          if (employee == null) continue;
          final availableDaysForSlot = entry.value[slot.id] ?? <int>{};
          if (availableDaysForSlot.contains(day.weekday)) {
            candidates.add(employee);
          }
        }
        if (candidates.isEmpty) continue;

        candidates.sort((a, b) {
          final plannedA = plannedAssignedCount[a.id] ?? 0;
          final plannedB = plannedAssignedCount[b.id] ?? 0;
          if (plannedA != plannedB) return plannedA.compareTo(plannedB);
          final baseA = baseAssignedCount[a.id] ?? 0;
          final baseB = baseAssignedCount[b.id] ?? 0;
          if (baseA != baseB) return baseA.compareTo(baseB);
          return a.name.compareTo(b.name);
        });

        var assignedForThisSlot = 0;
        for (final employee in candidates) {
          if (assignedForThisSlot >= requiredCount) break;
          final dateKey = '${day.year}-${day.month}-${day.day}';
          final assignedDates =
              assignedDateByEmployee.putIfAbsent(employee.id, () => <String>{});
          if (assignedDates.contains(dateKey)) {
            continue;
          }

          final overlaps = await provider.checkOverlappingShifts(
            employee.id,
            day,
            slot.start,
            slot.end,
          );
          if (overlaps.isNotEmpty) continue;

          plan.add(_PlannedShift(employee: employee, date: day, slot: slot));
          assignedForThisSlot++;
          assignedDates.add(dateKey);
          plannedAssignedCount[employee.id] =
              (plannedAssignedCount[employee.id] ?? 0) + 1;
        }
      }
    }
    if (plan.isEmpty) return false;

    final confirm = await _confirmAutoSchedulePlanDialog(
      weekMonday: weekMonday,
      plan: plan,
      requiredPerShift: requiredMatrix,
    );
    if (confirm != true) return false;

    var created = 0;
    for (final item in plan) {
      final ok = await provider.addShift(
        ShiftModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          employeeId: item.employee.id,
          employeeName: item.employee.name,
          date: item.date,
          startTime: item.slot.start,
          endTime: item.slot.end,
          openSlot: false,
          maxEmployees: 1,
        ),
      );
      if (ok) created++;
    }
    return created > 0;
  }

  Map<int, Map<String, int>>? _normalizeRequiredPerShift(
    Map<String, dynamic>? raw,
    DateTime weekMonday,
  ) {
    if (raw == null || raw.isEmpty) return null;
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    final morning = toInt(raw['morning']);
    final noon = toInt(raw['noon']);
    final evening = toInt(raw['evening']);
    if (morning > 0 || noon > 0 || evening > 0) {
      final out = <int, Map<String, int>>{};
      for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
        out[weekday] = {
          'morning': morning.clamp(0, 20),
          'noon': noon.clamp(0, 20),
          'evening': evening.clamp(0, 20),
        };
      }
      return out;
    }

    final out = <int, Map<String, int>>{};
    for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final dayDate = weekMonday.add(Duration(days: weekday - 1));
      final dayKeys = <String>[
        't${weekday + 1 > 8 ? 8 : weekday + 1}',
        weekday == DateTime.sunday ? 'cn' : '',
        dayDate.toIso8601String().split('T').first,
      ]..removeWhere((e) => e.isEmpty);
      Map<String, dynamic>? dayMap;
      for (final k in dayKeys) {
        if (raw[k] is Map) {
          dayMap = Map<String, dynamic>.from(raw[k] as Map);
          break;
        }
      }
      out[weekday] = {
        'morning': toInt(dayMap?['morning']).clamp(0, 20),
        'noon': toInt(dayMap?['noon']).clamp(0, 20),
        'evening': toInt(dayMap?['evening']).clamp(0, 20),
      };
    }
    return out;
  }

  Future<Map<int, Map<String, int>>?> _askRequiredPerShiftDialog(
    DateTime weekMonday,
  ) async {
    final horizontalCtrl = ScrollController();
    final verticalCtrl = ScrollController();
    final ctrls = <int, Map<String, TextEditingController>>{};
    for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      ctrls[weekday] = {
        'morning': TextEditingController(text: '2'),
        'noon': TextEditingController(text: '2'),
        'evening': TextEditingController(text: '3'),
      };
    }

    final result = await showDialog<Map<int, Map<String, int>>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận số lượng nhân viên theo tuần',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: (MediaQuery.sizeOf(ctx).width * 0.9).clamp(320.0, 1100.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nhập số nhân viên cho từng ca theo từng ngày trong tuần.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: SizedBox(
                    height: 250,
                    child: Scrollbar(
                      controller: verticalCtrl,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: verticalCtrl,
                        child: Scrollbar(
                          controller: horizontalCtrl,
                          thumbVisibility: true,
                          notificationPredicate: (n) => n.depth == 1,
                          child: SingleChildScrollView(
                            controller: horizontalCtrl,
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 44,
                              dataRowMinHeight: 50,
                              dataRowMaxHeight: 56,
                              columnSpacing: 8,
                              horizontalMargin: 8,
                              columns: [
                                const DataColumn(
                                  label: SizedBox(
                                    width: 58,
                                    child: Text('Ca', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                ...List.generate(7, (i) {
                                  final d = weekMonday.add(Duration(days: i));
                                  final title =
                                      '${_weekdayLabelVi(d.weekday)}\n${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                                  return DataColumn(
                                    label: SizedBox(
                                      width: 94,
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                              rows: [
                                _buildHeadcountRow(
                                  slotId: 'morning',
                                  slotLabel: 'Ca sáng',
                                  controllersByDay: ctrls,
                                ),
                                _buildHeadcountRow(
                                  slotId: 'noon',
                                  slotLabel: 'Ca trưa',
                                  controllersByDay: ctrls,
                                ),
                                _buildHeadcountRow(
                                  slotId: 'evening',
                                  slotLabel: 'Ca tối',
                                  controllersByDay: ctrls,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final matrix = <int, Map<String, int>>{};
              for (int weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++) {
                final m = int.tryParse(
                        ctrls[weekday]!['morning']!.text.trim()) ??
                    0;
                final n = int.tryParse(ctrls[weekday]!['noon']!.text.trim()) ?? 0;
                final e = int.tryParse(
                        ctrls[weekday]!['evening']!.text.trim()) ??
                    0;
                matrix[weekday] = {
                  'morning': m.clamp(0, 20),
                  'noon': n.clamp(0, 20),
                  'evening': e.clamp(0, 20),
                };
              }
              Navigator.pop(ctx, matrix);
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    for (final day in ctrls.values) {
      for (final c in day.values) {
        c.dispose();
      }
    }
    horizontalCtrl.dispose();
    verticalCtrl.dispose();
    return result;
  }

  DataRow _buildHeadcountRow({
    required String slotId,
    required String slotLabel,
    required Map<int, Map<String, TextEditingController>> controllersByDay,
  }) {
    return DataRow(
      cells: [
        DataCell(Text(
          slotLabel,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        )),
        ...List.generate(7, (i) {
          final weekday = DateTime.monday + i;
          return DataCell(
            SizedBox(
              width: 74,
              child: TextField(
                controller: controllersByDay[weekday]![slotId],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<bool?> _confirmAutoSchedulePlanDialog({
    required DateTime weekMonday,
    required List<_PlannedShift> plan,
    required Map<int, Map<String, int>> requiredPerShift,
  }) {
    String fmtDate(DateTime d) =>
        '${_weekdayLabelVi(d.weekday)}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    String fmtTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final grouped = <String, List<_PlannedShift>>{};
    for (final p in plan) {
      grouped.putIfAbsent(p.slot.id, () => <_PlannedShift>[]).add(p);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final d = a.date.compareTo(b.date);
        if (d != 0) return d;
        return a.employee.name.compareTo(b.employee.name);
      });
    }

    Widget section(String slotId, String title) {
      final slot = _scheduleSlots.firstWhere((s) => s.id == slotId);
      final entries = grouped[slotId] ?? <_PlannedShift>[];
      final totalNeed = List.generate(
        7,
        (i) => requiredPerShift[DateTime.monday + i]?[slotId] ?? 0,
      ).fold<int>(0, (a, b) => a + b);
      final totalAssigned = entries.length;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${fmtTime(slot.start)} - ${fmtTime(slot.end)})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Cần: $totalNeed',
                    style: const TextStyle(
                      color: Color(0xFFEF6C00),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Đã xếp: $totalAssigned',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (entries.isEmpty)
              const Text('Chưa xếp được ca nào.', style: TextStyle(fontSize: 14)),
            ...entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '• ${fmtDate(e.date)}: ${e.employee.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
          ],
        ),
      );
    }

    final weekEnd = weekMonday.add(const Duration(days: 6));
    final byDay = <String, List<_PlannedShift>>{};
    for (final p in plan) {
      final k =
          '${p.date.year}-${p.date.month}-${p.date.day}';
      byDay.putIfAbsent(k, () => <_PlannedShift>[]).add(p);
    }
    final dayCards = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final missingByDay = <String, List<String>>{};
    final slotName = <String, String>{
      'morning': 'Ca sáng',
      'noon': 'Ca trưa',
      'evening': 'Ca tối',
    };
    for (int i = 0; i < 7; i++) {
      final d = weekMonday.add(Duration(days: i));
      final dayKey = '${d.year}-${d.month}-${d.day}';
      final slotsForDay = byDay[dayKey] ?? <_PlannedShift>[];
      final countBySlot = <String, int>{};
      for (final p in slotsForDay) {
        countBySlot[p.slot.id] = (countBySlot[p.slot.id] ?? 0) + 1;
      }
      for (final slot in _scheduleSlots) {
        final need = requiredPerShift[d.weekday]?[slot.id] ?? 0;
        final got = countBySlot[slot.id] ?? 0;
        final miss = need - got;
        if (miss > 0) {
          missingByDay.putIfAbsent(dayKey, () => <String>[]);
          missingByDay[dayKey]!
              .add('${slotName[slot.id] ?? slot.id}: thiếu $miss');
        }
      }
    }

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Xác nhận tạo lịch làm',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 920,
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tuần ${weekMonday.day}/${weekMonday.month} - ${weekEnd.day}/${weekEnd.month}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      section('morning', 'Ca sáng'),
                      section('noon', 'Ca trưa'),
                      section('evening', 'Ca tối'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng quan theo ngày',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            ...dayCards.map((e) {
                              final first = e.value.first.date;
                              final label =
                                  '${_weekdayLabelVi(first.weekday)} ${first.day.toString().padLeft(2, '0')}/${first.month.toString().padLeft(2, '0')}/${first.year}';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• $label: ${e.value.length} ca',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ca còn thiếu',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFFC62828),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (missingByDay.isEmpty)
                              const Text(
                                'Đã đủ ca theo nhu cầu trong tuần.',
                                style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
                              )
                            else
                              ...missingByDay.entries.map((entry) {
                                final parts = entry.key.split('-');
                                final d = DateTime(
                                  int.parse(parts[0]),
                                  int.parse(parts[1]),
                                  int.parse(parts[2]),
                                );
                                final label =
                                    '${_weekdayLabelVi(d.weekday)} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '• $label: ${entry.value.join(', ')}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text(
              'Xác nhận tạo ca',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _resolveWeekMonday(String? weekStart) {
    final parsed = DateTime.tryParse((weekStart ?? '').trim());
    final anchor = parsed ?? DateTime.now();
    final local = DateTime(anchor.year, anchor.month, anchor.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  Map<String, Map<String, Set<int>>> _parseRegistrationsByEmployee(String text) {
    final result = <String, Map<String, Set<int>>>{};
    final parts = text
        .split(RegExp(r'[\n;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final line in parts) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final name = line.substring(0, idx).trim().toLowerCase();
      if (name.isEmpty) continue;
      final body = line.substring(idx + 1).trim().toLowerCase();
      if (body.isEmpty) continue;
      final tokens = body
          .split(RegExp(r'[\s,]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      String? currentSlotId;
      for (final tk in tokens) {
        final slotId = _slotTokenToId(tk);
        if (slotId != null) {
          currentSlotId = slotId;
          result.putIfAbsent(name, () => <String, Set<int>>{});
          result[name]!.putIfAbsent(slotId, () => <int>{});
          continue;
        }
        final weekday = _weekdayTokenToInt(tk);
        if (weekday != null && currentSlotId != null) {
          result.putIfAbsent(name, () => <String, Set<int>>{});
          result[name]!.putIfAbsent(currentSlotId, () => <int>{});
          result[name]![currentSlotId]!.add(weekday);
        }
      }
    }
    return result;
  }

  String? _slotTokenToId(String token) {
    final t = token.trim().toLowerCase();
    if (t == 'sang' || t == 'sáng' || t == 'morning') return 'morning';
    if (t == 'trua' || t == 'trưa' || t == 'noon' || t == 'afternoon') {
      return 'noon';
    }
    if (t == 'chieu' || t == 'chiều' || t == 'toi' || t == 'tối' || t == 'evening') {
      return 'evening';
    }
    return null;
  }

  int? _weekdayTokenToInt(String token) {
    final t = token.trim().toLowerCase();
    switch (t) {
      case 't2':
      case 'thu2':
      case 'th2':
      case 'mon':
        return DateTime.monday;
      case 't3':
      case 'thu3':
      case 'th3':
      case 'tue':
        return DateTime.tuesday;
      case 't4':
      case 'thu4':
      case 'th4':
      case 'wed':
        return DateTime.wednesday;
      case 't5':
      case 'thu5':
      case 'th5':
      case 'thu':
        return DateTime.thursday;
      case 't6':
      case 'thu6':
      case 'th6':
      case 'fri':
        return DateTime.friday;
      case 't7':
      case 'thu7':
      case 'th7':
      case 'sat':
        return DateTime.saturday;
      case 'cn':
      case 'chunhat':
      case 'sun':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  String _weekdayLabelVi(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'thứ 2';
      case DateTime.tuesday:
        return 'thứ 3';
      case DateTime.wednesday:
        return 'thứ 4';
      case DateTime.thursday:
        return 'thứ 5';
      case DateTime.friday:
        return 'thứ 6';
      case DateTime.saturday:
        return 'thứ 7';
      default:
        return 'Chủ nhật';
    }
  }

  // ---------------------------------------------------------------------------
  // Build & helpers cho giao diện Web Desktop
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final session = _session;
    // Xác định xem màn hình có đủ rộng để áp dụng layout Web/Desktop không
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4FF), // Nền xanh nhạt nguyên khối
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  title: const Text('Bạn muốn xóa cuộc trò chuyện này?'),
                                  content: const Text(
                                    'Bạn sẽ không thể khôi phục lại cuộc trò chuyện này.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
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
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          tooltip: 'Về Quản lý',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59B42), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59B42).withValues(alpha:0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Trợ lý AI TKA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                Text('Sẵn sàng hỗ trợ quản lý nhà hàng', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.black87),
              tooltip: 'Lịch sử chat',
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: session == null || session.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        itemCount: session.messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (_sending && i == session.messages.length) {
                            return _buildTypingIndicator();
                          }

                          final m = session.messages[i];
                          final isUser = m.role == 'user';
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isUser) _buildAiAvatar(),
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isDesktop ? 650 : MediaQuery.sizeOf(context).width * 0.85,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: isUser ? null : Colors.white,
                                        gradient: isUser
                                            ? const LinearGradient(
                                                colors: [Color(0xFFF59B42), Color(0xFFFF8C42)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                                          bottomRight: Radius.circular(isUser ? 4 : 20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isUser
                                                ? const Color(0xFFF59B42).withValues(alpha:0.25)
                                                : Colors.black.withValues(alpha:0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        border: isUser ? null : Border.all(color: Colors.grey.shade200, width: 1),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          isUser
                                              ? SelectableText(
                                                  m.text,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    height: 1.5,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                )
                                              : _buildModelMessage(message: m, messageIndex: i),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${m.at.hour.toString().padLeft(2, '0')}:${m.at.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isUser ? Colors.white.withValues(alpha:0.8) : Colors.grey[400],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  padding: const EdgeInsets.only(left: 24, right: 8, top: 6, bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.newline,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                          decoration: const InputDecoration(
                            hintText: 'Hỏi AI về doanh thu, tạo combo, xếp lịch...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sending ? null : _send,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            gradient: _sending
                                ? null
                                : const LinearGradient(
                                    colors: [Color(0xFFF59B42), Color(0xFFFF6B35)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: _sending ? Colors.grey[200] : null,
                            shape: BoxShape.circle,
                            boxShadow: _sending
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(0xFFF59B42).withValues(alpha:0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: _sending ? Colors.grey[500] : Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59B42), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59B42).withValues(alpha:0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAiAvatar(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFF59B42))),
                const SizedBox(width: 12),
                Text('Trợ lý đang phân tích dữ liệu...', style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF59B42).withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 48, color: Color(0xFFF59B42)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hôm nay tôi có thể giúp gì cho bạn?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            'Hãy hỏi tôi về doanh thu, tạo món mới,\nhoặc xếp lịch ca làm cho nhân sự nhé.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
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

class _ShiftSlotPreset {
  final String id;
  final TimeOfDay start;
  final TimeOfDay end;

  const _ShiftSlotPreset({
    required this.id,
    required this.start,
    required this.end,
  });
}

class _PlannedShift {
  final EmployeeModel employee;
  final DateTime date;
  final _ShiftSlotPreset slot;

  const _PlannedShift({
    required this.employee,
    required this.date,
    required this.slot,
  });
}

// =============================================================================
// Widget hiện thẻ hành động CRUD với nút xác nhận
// =============================================================================
class _ActionCard extends StatefulWidget {
  final String actionType;
  final Map<String, dynamic> data;
  final Future<bool> Function() onConfirm;
  final bool initialSuccess;
  final VoidCallback onSuccess;

  const _ActionCard({
    super.key,
    required this.actionType,
    required this.data,
    required this.onConfirm,
    required this.initialSuccess,
    required this.onSuccess,
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
        'Thêm ${_shiftLabelFromTimes(data['startTime'], data['endTime'])} ${_weekdayAndDateText(data['date'])} (${_timeText(data['startTime'])} - ${_timeText(data['endTime'])}) — tối đa ${data['maxEmployees'] ?? 1} người',
      'auto_schedule_shifts' =>
        'Xếp lịch làm việc tự động từ danh sách đăng ký ca làm',
      'update_shift' =>
        'Cập nhật ca #$id — ${_shiftLabelFromTimes(data['startTime'], data['endTime'])} ${_weekdayAndDateText(data['date'])} (${_timeText(data['startTime'])} - ${_timeText(data['endTime'])})',
      'delete_shift' => 'Xóa ca làm #$id',
      'add_table' => 'Thêm bàn "$name"',
      'update_table' => 'Cập nhật bàn #$id${name.isNotEmpty ? ' → "$name"' : ''}',
      'delete_table' => 'Xóa bàn ${name.isNotEmpty ? name : (id != null && id != 0 ? "số $id" : "được chọn")}',
      _ => 'Thao tác: $type',
    };
  }

  static String _timeText(dynamic raw) {
    final input = (raw?.toString() ?? '').trim();
    if (input.isEmpty) return '--:--';
    final cleaned = input
        .replaceAll('h', ':')
        .replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = cleaned.split(':').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--:--';
    final h = int.tryParse(parts[0]);
    final m = parts.length >= 2 ? int.tryParse(parts[1]) : 0;
    if (h == null || m == null) return '--:--';
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String _shiftLabelFromTimes(dynamic startRaw, dynamic endRaw) {
    final start = _timeText(startRaw);
    final end = _timeText(endRaw);
    if (start == '06:30' && end == '11:30') return 'ca sáng';
    if (start == '11:30' && end == '17:30') return 'ca trưa';
    if (start == '17:30' && end == '23:30') return 'ca tối';
    return 'ca làm';
  }

  static String _weekdayAndDateText(dynamic rawDate) {
    final d = _toDate(rawDate?.toString() ?? '');
    if (d == null) return '';
    String weekday;
    switch (d.weekday) {
      case DateTime.monday:
        weekday = 'thứ 2';
        break;
      case DateTime.tuesday:
        weekday = 'thứ 3';
        break;
      case DateTime.wednesday:
        weekday = 'thứ 4';
        break;
      case DateTime.thursday:
        weekday = 'thứ 5';
        break;
      case DateTime.friday:
        weekday = 'thứ 6';
        break;
      case DateTime.saturday:
        weekday = 'thứ 7';
        break;
      default:
        weekday = 'Chủ nhật';
    }
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$weekday ($dd/$mm/$yyyy)';
  }

  static DateTime? _toDate(String inputRaw) {
    final input = inputRaw.trim();
    if (input.isEmpty) return null;
    final iso = DateTime.tryParse(input);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final p = input
        .replaceAll('.', '/')
        .replaceAll('-', '/')
        .split('/');
    if (p.length != 3) return null;
    final a = int.tryParse(p[0]);
    final b = int.tryParse(p[1]);
    final c = int.tryParse(p[2]);
    if (a == null || b == null || c == null) return null;
    return a > 1900 ? DateTime(a, b, c) : DateTime(c, b, a);
  }

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _processing = false;
  late bool _success;

  @override
  void initState() {
    super.initState();
    _success = widget.initialSuccess;
  }

  IconData get _icon {
    if (widget.actionType.contains('menu_item')) return Icons.restaurant_menu;
    if (widget.actionType.contains('employee')) return Icons.person;
    if (widget.actionType.contains('shift')) return Icons.schedule;
    if (widget.actionType.contains('table')) return Icons.table_bar;
    return Icons.settings;
  }

  Color _accentColor(String type) {
    if (type.startsWith('delete')) return AppTheme.statusRed;
    if (type.startsWith('update')) return Colors.blue;
    return AppTheme.primaryOrange;
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        _success ? AppTheme.statusGreen : _accentColor(widget.actionType);
    final desc = _ActionCard.describe(widget.actionType, widget.data);
    final isDelete = widget.actionType.startsWith('delete');

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _success ? AppTheme.statusGreen.withValues(alpha: 0.06) : accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _success ? AppTheme.statusGreen.withValues(alpha: 0.3) : accent.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  desc,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGreyText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _success
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.statusGreen.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: AppTheme.statusGreen),
                        SizedBox(width: 6),
                        Text('Đã thực hiện thành công', style: TextStyle(color: AppTheme.statusGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _processing ? null : () async {
                      setState(() => _processing = true);
                      var ok = false;
                      try {
                        ok = await widget.onConfirm();
                      } catch (_) {
                        ok = false;
                      } finally {
                        if (mounted) setState(() { _processing = false; _success = ok; });
                      }
                      if (!mounted) return;
                      if (ok) widget.onSuccess();
                    },
                    icon: _processing
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(isDelete ? Icons.delete_outline : Icons.check_rounded, size: 17),
                    label: Text(_processing ? 'Đang xử lý…' : (isDelete ? desc : 'Xác nhận thực hiện')),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}