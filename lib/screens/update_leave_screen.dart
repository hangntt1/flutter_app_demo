import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_demo/enum/status.dart';
import 'package:flutter_app_demo/theme/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

import '../enum/noti_status.dart';
import '../models/leave_request.dart';
import '../models/notification.dart';
import '../services/auth_service.dart';
import '../services/leave_service.dart';
import '../services/noti_service.dart';

class UpdateLeaveScreen extends StatefulWidget {
  final String leaveId;
  const UpdateLeaveScreen({super.key, required this.leaveId});

  @override
  State<UpdateLeaveScreen> createState() => _UpdateLeaveScreenState();
}

class _UpdateLeaveScreenState extends State<UpdateLeaveScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isAdmin = false; 
  bool _canAction = true;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  final _service = LeaveService();
  final _authService = AuthService();

  int _usedLeaveDays = 0;
  int _remainingLeaveDays = 0;

  final _reasonController = TextEditingController();
  final _userNameController = TextEditingController();

  LeaveRequest? _leave;

  @override
  void initState() {
    super.initState();
    _loadLeaveDetail();
  }

  Future<void> _loadLeaveDetail() async {
    final isAdmin = await AuthService().isAdmin();

    final leave = await _service.getLeaveDetail(widget.leaveId);

    final info = await _authService.getLeaveInfo(leave.userId);

    setState(() {
      _leave = leave;
      _reasonController.text = leave.reason;
      _userNameController.text = leave.userName;
      _rangeStart = leave.startDate;
      _rangeEnd = leave.endDate;
      _usedLeaveDays = info['used']!;
      _remainingLeaveDays = info['remaining']!;
      _isAdmin = isAdmin;
      _canAction = leave.status == Status.pending;
    });
  }

  Future<void> _createNotify(NotiStatus status) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final info = await _authService.getLeaveInfo(user.uid);

    final notiId = FirebaseFirestore.instance
        .collection('notifications')
        .doc()
        .id;

    final noti = Notify(
      id: notiId,
      title: 'Đơn xin nghỉ',
      senderId: user.uid,
      senderName: info['userName'],
      receiverId: _leave!.userId,
      receiverName: _leave!.userName,
      isRead: false,
      isImportant: false,
      status: status,
      formId: _leave!.id,
      createdAt: DateTime.now(),
    );

    await NotificationService.createNotification(noti);

    if(status == NotiStatus.approved){
      _showMessage("Đã duyệt đơn thành công");
    } else {
      _showMessage("Đã từ chối đơn thành công");
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_leave == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
          "Cập nhật đơn xin nghỉ phép",
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

            _actionButtons(),
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
            controller: _userNameController,
            enabled: false,
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
            controller: _reasonController,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F32),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Số phép còn lại",
              style: TextStyle(color: Colors.blue, fontSize: 12)),
          const SizedBox(height: 8),
          SummaryRow("Số ngày nghỉ", _usedLeaveDays.toString()),
          const SizedBox(height: 6),
          SummaryRow("Số ngày phép", _remainingLeaveDays.toString()),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        if (_leave!.userId == FirebaseAuth.instance.currentUser!.uid) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _canAction ? Colors.red : Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _canAction ? () async {
                      if (_leave == null) return;
          
                      await _service.cancelLeave(_leave!.id);
          
                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                    } : null,
                    child: Text(
                      "Hủy đơn",
                      style: TextStyle(color: _canAction ? Colors.redAccent : Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  _canAction ? Colors.orange : Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _canAction ? () async {
                      if (_leave == null || _rangeStart == null || _rangeEnd == null) return;
          
                      await _service.updateLeave(
                        leaveId: _leave!.id,
                        reason: _reasonController.text,
                        startDate: _rangeStart!,
                        endDate: _rangeEnd!,
                        totalDays: 1,
                      );
          
                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                    } : null,
                    child: const Text(
                      "Cập nhật",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        /// ===== ADMIN ACTION =====
        if (_isAdmin) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _canAction ? Colors.redAccent : Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _canAction ? () async {
                      if (_leave == null) return;

                      await _service.rejectLeave(_leave!.id);

                      _createNotify(NotiStatus.rejected);

                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                    } : null,
                    child: Text(
                      "Từ chối",
                      style: TextStyle(
                        color: _canAction ? Colors.redAccent : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canAction ? Colors.green : Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _canAction ? () async {
                      if (_leave == null) return;

                      await _service.approveLeave(_leave!.id, _leave!.userId, _leave!.totalDays);

                      _createNotify(NotiStatus.approved);

                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                    } : null,
                    child: const Text(
                      "Duyệt đơn",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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
