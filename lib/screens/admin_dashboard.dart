import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final int maxBusCapacity = 40;
  final int totalStudents = 60;
  final int totalBuses = 10;

  int todayAttendance = 0;
  int activeBusCount = 0;

  @override
  void initState() {
    super.initState();
    fetchTodayData(); // initial fetch
    scheduleDailyRefresh(); // schedule 12AM refresh
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    context.go('/login');
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 🔁 Fetch today's attendance & active buses
  void fetchTodayData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance_logs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final studentIds = snapshot.docs
        .map((doc) => doc['studentId']?.toString())
        .whereType<String>()
        .toSet();

    final buses = snapshot.docs
        .map((doc) => doc['busNumber']?.toString())
        .where((b) => b != null && b.isNotEmpty && b != 'NA')
        .toSet();

    setState(() {
      todayAttendance = studentIds.length;
      activeBusCount = buses.length;
    });
  }

  /// ⏰ Schedule midnight refresh
  void scheduleDailyRefresh() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    Future.delayed(timeUntilMidnight, () {
      fetchTodayData(); // refresh
      scheduleDailyRefresh(); // reschedule for next day
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xff3f51b5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [_buildStatsPage(), _buildCapacityPage()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 0
                      ? () => _goToPage(_currentPage - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _currentPage < 1
                      ? () => _goToPage(_currentPage + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Page 1: Dashboard Stats
  Widget _buildStatsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                "Total Students",
                totalStudents.toString(),
                Icons.group,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                "Today's Present",
                todayAttendance.toString(),
                Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                "Total Buses",
                totalBuses.toString(),
                Icons.directions_bus,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                "Active Buses",
                activeBusCount.toString(),
                Icons.local_shipping,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Page 2: Bus Fill Capacity
  Widget _buildCapacityPage() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final stream = FirebaseFirestore.instance
        .collection('attendance_logs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final Map<String, int> busCounts = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final bus = data['busNumber'];
          if (bus != null && bus != '') {
            busCounts[bus] = (busCounts[bus] ?? 0) + 1;
          }
        }

        final buses = busCounts.entries.map((entry) {
          final percent = ((entry.value / maxBusCapacity) * 100).toInt();
          return {'bus': entry.key, 'count': entry.value, 'fill': percent};
        }).toList();

        final underCapacity = buses
            .where((b) => (b['fill'] as int? ?? 0) < 50)
            .toList();

        final overCapacity = buses
            .where((b) => (b['fill'] as int? ?? 0) > 100)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Under-capacity Buses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildAlertList(underCapacity, Colors.orange),
              const SizedBox(height: 24),
              const Text(
                "Over-capacity Buses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildAlertList(overCapacity, Colors.red),
            ],
          ),
        );
      },
    );
  }

  /// 📦 Stat Card Widget
  Widget _buildStatCard(String title, String count, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff3f51b5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚨 Alert List Widget
  Widget _buildAlertList(List<Map<String, dynamic>> buses, Color color) {
    return Column(
      children: buses.map((bus) {
        final busNo = bus['bus'];
        final fillPercent = bus['fill'];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$busNo - $fillPercent%",
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: fillPercent / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
