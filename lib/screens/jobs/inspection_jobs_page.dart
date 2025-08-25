import 'package:flutter/material.dart';

class InspectionJobsPage extends StatefulWidget {
  final int initialTab;
  const InspectionJobsPage({super.key, this.initialTab = 0});

  @override
  State<InspectionJobsPage> createState() => _InspectionJobsPageState();
}

class _InspectionJobsPageState extends State<InspectionJobsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('No pending inspections')),
          Center(child: Text('No completed inspections')),
        ],
      ),
    );
  }
}
