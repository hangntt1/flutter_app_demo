import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenLeave;

  const DashboardScreen({super.key, required this.onOpenLeave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildTopBackground(),
           _buildContent(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        "Tổng quan",
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, size: 16),
          tooltip: "Đăng xuất",
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Đăng xuất"),
                content: const Text("Bạn có chắc muốn đăng xuất không?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Hủy"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Đăng xuất"),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
              }
            }
          }
        ),
      ],
    );
  }

  Widget _buildTopBackground() {
    return Container(
      height: 40,
      color: AppColors.appBar, // màu đen
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.only(
        top: 0,
        left: 10,
        right: 10,
      ),
      children:[
        ShortcutPagerCard(
          onOpenLeave: onOpenLeave, // 👈 truyền xuống
        ),
        const SizedBox(height: 8),
        const RevenuePagerCard(),
        const SizedBox(height: 8),
        const RecentPagerCard(),
        const SizedBox(height: 8),
        const TodayTaskCard(),
      ],
    );
  }

}

class ShortcutPagerCard extends StatefulWidget {
  final VoidCallback onOpenLeave;

  const ShortcutPagerCard({
    super.key,
    required this.onOpenLeave,
  });
  @override
  State<ShortcutPagerCard> createState() => _ShortcutPagerCardState();
}

class _ShortcutPagerCardState extends State<ShortcutPagerCard> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const int _itemsPerPage = 4;

  @override
  Widget build(BuildContext context) {

    final List<Widget> items = [
      const _ShortcutItem(
        icon: Icons.check_circle,
        color: Colors.green,
        label: "Quản lý\nduyệt",
      ),
      const _ShortcutItem(
        icon: Icons.assignment,
        color: Colors.orange,
        label: "Cập nhật\ncông việc",
      ),
      _ShortcutItem(
        icon: Icons.event_note,
        color: Colors.blue,
        label: "Đơn xin\nnghỉ phép",
        onTap: widget.onOpenLeave,
      ),
      const _ShortcutItem(
        icon: Icons.directions_car,
        color: Colors.red,
        label: "Đăng ký\nsử dụng",
      ),
      const _ShortcutItem(
        icon: Icons.directions_car,
        color: Colors.red,
        label: "Đăng ký\nsử dụng",
      ),
    ];

    final pageCount = (items.length / _itemsPerPage).ceil();

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: PageView.builder(
                controller: _controller,
                itemCount: pageCount,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * _itemsPerPage;
                  final end =
                      (start + _itemsPerPage).clamp(0, items.length);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: items.sublist(start, end),
                  );
                },
              ),
            ),
            if (pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pageCount,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 16 : 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.amber
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _ShortcutItem({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8.5, color: AppColors.textMainColor),
          ),
        ],
      ),
    );
  }
}

class RevenuePagerCard extends StatefulWidget {
  const RevenuePagerCard({super.key});

  @override
  State<RevenuePagerCard> createState() => _RevenuePagerCardState();
}

class _RevenuePagerCardState extends State<RevenuePagerCard> {
  int _page = 0;
  final _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _controller,
              itemCount: 3,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, _) => const _RevenueItem(),
            ),
          ),
          _PagerIndicator(count: 3, index: _page),
        ],
      ),
    );
  }
}

class _RevenueItem extends StatelessWidget {
  const _RevenueItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Doanh thu", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMainColor)),
                SizedBox(height: 8),
                Text(
                  "645,41 tỷ đồng",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 6),
                Text("▲ 10.000,00%", style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
          const Icon(Icons.show_chart, size: 60, color: Colors.amber),
        ],
      ),
    );
  }
}

class RecentPagerCard extends StatefulWidget {
  const RecentPagerCard({super.key});

  @override
  State<RecentPagerCard> createState() => _RecentPagerCardState();
}

class _RecentPagerCardState extends State<RecentPagerCard> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, bottom: 12),
          child: Text("Gần đây", style: TextStyle(fontSize: 10, color: AppColors.textMainColor),),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              SizedBox(
                height: 125,
                child: PageView.builder(
                  itemCount: 5,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, _) => const _RecentItem(),
                ),
              ),
              _PagerIndicator(count: 5, index: _page),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentItem extends StatelessWidget {
  const _RecentItem();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(5),
      children: const [
        _RecentRow(
          icon: Icons.directions_car,
          title: "Cập nhật đăng ký sử dụng xe",
        ),
        _RecentRow(
          icon: Icons.event_note,
          title: "Đơn xin nghỉ phép",
        ),
      ],
    );
  }
}

class _RecentRow extends StatefulWidget {
  final IconData icon;
  final String title;

  const _RecentRow({
    required this.icon,
    required this.title,
  });

  @override
  State<_RecentRow> createState() => _RecentRowState();
}

class _RecentRowState extends State<_RecentRow> {
  bool _isStarred = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      minLeadingWidth: 25,
      horizontalTitleGap: 8,
      leading: Icon(
        widget.icon,
        color: Colors.orange,
        size: 18,
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textMainColor
        ),
      ),
      subtitle: const Text(
        "2 tháng trước",
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
        ),
      ),
      trailing: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _isStarred = !_isStarred;
          });
        },
        child: Icon(
          _isStarred ? Icons.star : Icons.star_border,
          color: _isStarred ? Colors.amber : Colors.grey,
          size: 18,
        ),
      ),
      dense: true, 
    );
  }
}

class TodayTaskCard extends StatelessWidget {
  const TodayTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, bottom: 12),
          child: Text("Công việc trong ngày",style: TextStyle(fontSize: 10, color: AppColors.textMainColor),),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              SizedBox(
                height: 80,
                child: const _EmptyTask()
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _EmptyTask extends StatelessWidget {
  const _EmptyTask();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 36),
          SizedBox(height: 8),
          Text("Hiện tại đang không có dữ liệu", style: TextStyle(fontSize: 10, color: AppColors.textMainColor),),
        ],
      ),
    );
  }
}

class _PagerIndicator extends StatelessWidget {
  final int count;
  final int index;

  const _PagerIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: index == i ? 16 : 6,
            height: 4,
            decoration: BoxDecoration(
              color: index == i ? Colors.amber : Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}


