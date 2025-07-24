import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int maxBusCapacity = 40;

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

  Stream<List<int>> getStatsStream() {
    final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);

    return FirebaseFirestore.instance
        .collectionGroup('scans')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .snapshots()
        .asyncMap((snapshot) async {
          final attendanceDocs = snapshot.docs;

          final users = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'faculty')
              .get();

          final activeFaculty = attendanceDocs
              .map((e) => e['faculty'])
              .toSet()
              .length;
          final attendanceToday = attendanceDocs.length;

          return [users.docs.length, activeFaculty, attendanceToday];
        });
  }

  Stream<List<Map<String, dynamic>>> getBusCapacityStream() {
    final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);

    return FirebaseFirestore.instance
        .collectionGroup('scans')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .snapshots()
        .map((snapshot) {
          final Map<String, int> busCounts = {};

          for (var doc in snapshot.docs) {
            final bus = doc['busNumber'];
            if (bus != null && bus != '') {
              busCounts[bus] = (busCounts[bus] ?? 0) + 1;
            }
          }

          return busCounts.entries.map((entry) {
            final fillPercent = ((entry.value / maxBusCapacity) * 100).toInt();
            return {
              'bus': entry.key,
              'fill': fillPercent,
              'count': entry.value,
            };
          }).toList();
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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
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

  Widget _buildStatsPage() {
    return StreamBuilder<List<int>>(
      stream: getStatsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final studentCount = snapshot.data![0].toString();
        final activeFaculty = snapshot.data![1].toString();
        final attendanceToday = snapshot.data![2].toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatCard("Total Buses", "25", Icons.directions_bus),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    "Active Today",
                    activeFaculty,
                    Icons.directions_run,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard("Total Students", studentCount, Icons.group),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    "Today's Present",
                    attendanceToday,
                    Icons.check_circle,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCapacityPage() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getBusCapacityStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final underCapacity = data.where((bus) => bus['fill'] < 50).toList();
        final overCapacity = data.where((bus) => bus['fill'] > 100).toList();

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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("View All"),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
