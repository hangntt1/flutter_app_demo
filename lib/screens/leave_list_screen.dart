import 'package:flutter/material.dart';
import 'package:flutter_app_demo/theme/app_colors.dart';
import '../enum/status.dart';
import '../models/leave_request.dart';
import '../services/auth_service.dart';
import '../services/leave_service.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  Status _currentFilter = Status.all;

  final _leaveService = LeaveService();
  List<LeaveRequest> _requests = [];
  bool _loading = true;
  bool _isAdmin = false; 

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final isAdmin = await AuthService().isAdmin();

    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
    });

    await _loadData();
  }

  Future<void> _loadData() async {
    final data = await _leaveService.fetchLeaveRequests(
      isAdmin: _isAdmin,
    );

    if (!mounted) return;

    setState(() {
      _requests = data;
      _loading = false;
    });
  }

  List<LeaveRequest> get filteredRequests {
    switch (_currentFilter) {
      case Status.pending:
        return _requests.where((e) => e.status == Status.pending).toList();
      case Status.approved:
        return _requests.where((e) => e.status == Status.approved || e.status == Status.rejected).toList();
      case Status.cancel:
        return _requests.where((e) => e.status == Status.cancel).toList();
      default:
        return _requests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.swap_vert, size: 20),
            ),
          ],
        ),
        title: const Text(
          "Đơn xin nghỉ phép",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.orange,
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/add');
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
      ? const Center(
          child: CircularProgressIndicator(),
        )
      : Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: filteredRequests.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    itemCount: filteredRequests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return LeaveCard(
                        request: filteredRequests[index],
                        onTap: () async {
                          final result = await Navigator.of(context).pushNamed(
                            '/update',
                            arguments: filteredRequests[index].id,
                          );

                          if (result == true) {
                            _loadData(); 
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F32),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _filterItem("Tất cả", Status.all),
          _divider(),
          _filterItem("Chưa duyệt", Status.pending),
          _divider(),
          _filterItem("Đã duyệt", Status.approved),
          _divider(),
          _filterItem("Đã huỷ", Status.cancel),
        ],
      ),
    );
  }
  Widget _filterItem(String label, Status filter) {
    final isActive = _currentFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentFilter = filter);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
  Widget _divider() {
    return Container(
      width: 1,
      height: 18,
      color: Colors.white12,
    );
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 90,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            "Hiện tại không có đơn xin nghỉ",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}


class LeaveCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback onTap;

  const LeaveCard({
    super.key,
    required this.request,
    required this.onTap
  });

  Color get statusColor {
    switch (request.status) {
      case Status.approved:
        return Colors.green;
      case Status.rejected:
        return Colors.red;
      case Status.cancel:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String get statusText {
    switch (request.status) {
      case Status.approved:
        return "Đã duyệt";
      case Status.rejected:
        return "Từ chối";
      case Status.cancel:
        return "Đã hủy";
      default:
        return "Chờ duyệt";
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2F32),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            /// ICON TRONG NỀN TRÒN
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 18,
                color: Colors.orange,
              ),
            ),
      
            const SizedBox(width: 12),
      
            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Đơn xin nghỉ phép",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Người lập: ${request.userName}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(request.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
      
            /// STATUS CHIP
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}


