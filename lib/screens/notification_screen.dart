import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../enum/noti_status.dart';
import '../models/notification.dart';
import '../services/noti_service.dart';
import '../theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  final void Function(String leaveId) onOpenLeave;

  const NotificationScreen({super.key, required this.onOpenLeave});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notiService = NotificationService();
  List<Notify> _notis = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = await _notiService.fetchNotifies(id: user.uid);

    if (!mounted) return;

    setState(() {
      _notis = data;
      _loading = false;
    });
  }

  /// ================= UNREAD COUNT =================
  int get unreadCount =>
      _notis.where((e) => e.isRead == false).length;

  /// ================= FILTER =================
  List<Notify> filteredRequests(FilterNotiStatus filter) {
    switch (filter) {
      case FilterNotiStatus.unread:
        return _notis.where((e) => !e.isRead).toList();
      case FilterNotiStatus.important:
        return _notis.where((e) => e.isImportant).toList();
      case FilterNotiStatus.pending:
        return _notis.where((e) => e.status == NotiStatus.pending).toList();
      case FilterNotiStatus.approved:
        return _notis.where((e) => e.status == NotiStatus.approved || e.status == NotiStatus.rejected).toList();
      default:
        return _notis;
    }
  }

  /// ================= DATE HELPERS =================
  String _dateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hôm nay';
    if (d == yesterday) return 'Hôm qua';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Map<String, List<Notify>> _groupByDate(List<Notify> items) {
    final Map<String, List<Notify>> map = {};
    for (final noti in items) {
      final key = _dateKey(noti.createdAt);
      map.putIfAbsent(key, () => []);
      map[key]!.add(noti);
    }
    return map;
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.appBar,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Thông báo',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          actions: const [
            Icon(Icons.search, size: 20),
            SizedBox(width: 12),
            Icon(Icons.more_vert, size: 20),
            SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildFilterBar(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildList(FilterNotiStatus.all, context),
                        _buildList(FilterNotiStatus.unread, context),
                        _buildList(FilterNotiStatus.important, context),
                        _buildList(FilterNotiStatus.pending, context),
                        _buildList(FilterNotiStatus.approved, context)                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// ================= FILTER BAR =================
  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F32),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        isScrollable: true,
        indicator: const BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        tabs: [
          const Tab(text: 'Tất cả'),

          /// ===== CHƯA ĐỌC + BADGE =====
          Tab(
            child: Row(
              children: [
                const Text('Chưa đọc'),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Tab(text: 'Quan trọng'),
          const Tab(text: 'Chờ duyệt'),
          const Tab(text: 'Đã duyệt')
        ],
      ),
    );
  }

  /// ================= LIST + DATE HEADER =================
  Widget _buildList(FilterNotiStatus filter, BuildContext context) {
    final items = filteredRequests(filter);

    if (items.isEmpty) {
      return const _EmptyState();
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final grouped = _groupByDate(items);
    final dateKeys = grouped.keys.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      children: dateKeys.expand((date) {
        final list = grouped[date]!;
        return [
          _dateHeader('$date (${list.length})'),
          ...list.map(
            (noti) => NotificationCard(
              request: noti,
              onTap: () async {
                if (!noti.isRead) {
                  await _notiService.markAsRead(noti.id);
                }
                if (!context.mounted) return;
                widget.onOpenLeave(noti.formId);
              },
              onToggleImportant: () async {
                await _notiService.toggleImportant(
                  noti.id,
                  noti.isImportant,
                );
                _loadData(); // reload lại list
              },
            ),
          ),
        ];
      }).toList(),
    );
  }

  Widget _dateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// ================= EMPTY =================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 90,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            "Hiện tại không có thông báo",
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

/// ================= CARD =================
class NotificationCard extends StatelessWidget {
  final Notify request;
  final VoidCallback onTap;
  final VoidCallback onToggleImportant;

  const NotificationCard({
    super.key,
    required this.request,
    required this.onTap,
    required this.onToggleImportant,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: request.isRead
              ? const Color(0xFF2A2F33)
              : const Color(0xFF32383C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: request.status == NotiStatus.approved
                  ? Colors.blue
                  : request.status == NotiStatus.rejected
                      ? Colors.red
                      : Colors.orange,
              child: const Icon(Icons.notifications,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.status == NotiStatus.approved
                  ? "[${request.title}] đã hoàn thành duyệt"
                  : request.status == NotiStatus.rejected
                      ?"[${request.title}] đã từ chối"
                      : "[${request.title}] đang chờ duyệt",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Người gửi: ${request.senderName}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(request.createdAt),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            
            Column(
              children: [
                const Icon(Icons.chevron_right,
                    color: Colors.orange),
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleImportant, // ⭐ chỉ toggle
                  child: Icon(
                    request.isImportant
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
