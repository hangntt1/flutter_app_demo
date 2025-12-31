import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_demo/theme/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/leave_request.dart';
import '../../services/leave_service.dart';
import '../enum/noti_status.dart';
import '../enum/status.dart';
import '../models/notification.dart';
import '../services/auth_service.dart';
import '../services/noti_service.dart';


class AddLeaveScreen extends StatefulWidget {
  const AddLeaveScreen({super.key});

  @override
  State<AddLeaveScreen> createState() => _AddLeaveScreenState();
}

class _AddLeaveScreenState extends State<AddLeaveScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();

  final _authService = AuthService();

  int _usedLeaveDays = 0;
  int _remainingLeaveDays = 0;
  bool _loadingLeaveInfo = true;

  @override
  void initState() {
    super.initState();
    _loadLeaveInfo();
  }

  Future<void> _loadLeaveInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final info = await _authService.getLeaveInfo(user.uid);

    if (!mounted) return;

    setState(() {
      _usedLeaveDays = info['used']!;
      _remainingLeaveDays = info['remaining']!;
      _loadingLeaveInfo = false;
    });
  }

  Future<void> _submitLeave() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (_rangeStart == null || _rangeEnd == null) {
      _showMessage("Vui lòng chọn ngày nghỉ");
      return;
    }

    if (_reasonCtrl.text.trim().isEmpty) {
      _showMessage("Vui lòng nhập lý do nghỉ");
      return;
    }

    // add leave request
    final leaveId = FirebaseFirestore.instance
      .collection('leaveRequests')
      .doc()
      .id;

    final leave = LeaveRequest(
      id: leaveId,
      userId: user.uid,
      userName: _nameCtrl.text.trim(),
      reason: _reasonCtrl.text.trim(),
      startDate: _rangeStart!,
      endDate: _rangeEnd!,
      totalDays: totalLeaveDays,
      status: Status.pending,
      createdAt: DateTime.now(),
    );

    await LeaveService.addLeaveRequest(leave);

    //add noti
    final admin = await NotificationService.getAdminInfo();

    final notiId = FirebaseFirestore.instance
        .collection('notifications')
        .doc()
        .id;

    final noti = Notify(
      id: notiId,
      title: 'Đơn xin nghỉ',
      senderId: user.uid,
      senderName: leave.userName,
      receiverId: admin['id']!,
      receiverName: admin['name']!,
      isRead: false,
      isImportant: false,
      status: NotiStatus.pending,
      formId: leaveId,
      createdAt: DateTime.now(),
    );

    await NotificationService.createNotification(noti);

    _showMessage("Đã gửi đơn, chờ admin duyệt");

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  int get totalLeaveDays {
    if (_rangeStart == null || _rangeEnd == null) return 0;
    return _rangeEnd!.difference(_rangeStart!).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thêm đơn xin nghỉ phép",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _createdInfoRow(),
            const SizedBox(height: 6),

            _textReason(),
            const SizedBox(height: 8),

            _calendarSection(),
            const SizedBox(height: 8),

            _leaveSummary(),
            const SizedBox(height: 8),

            _confirmButton(),
          ],
        ),
      ),
    );
  }

  String _today() {
  final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/"
          "${now.month.toString().padLeft(2, '0')}/"
          "${now.year}";
  }

  Widget _createdInfoRow() {
    return Row(
      children: [
        // ===== Ngày lập =====
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ngày lập",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Text(
                _today(), // realtime date
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Container(
                height: 1,
                color: Colors.white24,
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // ===== Người lập =====
        Expanded(
          flex: 1,
          child: TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Người lập",
              labelStyle:
                  const TextStyle(color: Colors.white54, fontSize: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red..withValues(alpha: 0.7),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textReason() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextField(
            controller: _reasonCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Lý do xin nghỉ",
              labelStyle:
                  const TextStyle(color: Colors.white54, fontSize: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red..withValues(alpha: 0.7),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _calendarSection() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2F32),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Thời gian nghỉ",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),

        TableCalendar(
          locale: 'vi_VN',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,

          enabledDayPredicate: (day) {
            final today = DateTime.now();
            return !day.isBefore(
              DateTime(today.year, today.month, today.day),
            );
          },

          rowHeight: 36,

          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          rangeSelectionMode: _rangeSelectionMode,

          onRangeSelected: (start, end, focusedDay) {
            setState(() {
              _focusedDay = focusedDay;

              if (start != null && end == null) {
                _rangeStart = start;
                _rangeEnd = start;
                _rangeSelectionMode = RangeSelectionMode.toggledOn;
                return;
              }

              if (start != null && end != null) {
                _rangeStart = start;
                _rangeEnd = end;
                _rangeSelectionMode = RangeSelectionMode.toggledOn;
              }
            });
          },

          calendarStyle: CalendarStyle(
            disabledTextStyle: const TextStyle(
              color: Colors.white24,
              fontSize: 12,
            ),
            defaultTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            weekendTextStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),

            todayDecoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),

            outsideDaysVisible: false,
          ),

          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            leftChevronIcon:
                const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            rightChevronIcon:
                const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ),

          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            weekendStyle: TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        )
      ],
    ),
  );
}


  Widget _leaveSummary() {
    if (_loadingLeaveInfo) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F32),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Số phép còn lại",
            style: TextStyle(color: Colors.blue, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SummaryRow("Số ngày đã nghỉ", _usedLeaveDays.toString()),
          const SizedBox(height: 6),
          SummaryRow("Số ngày phép", _remainingLeaveDays.toString()),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _submitLeave,
        child: const Text(
          "Xác nhận",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
