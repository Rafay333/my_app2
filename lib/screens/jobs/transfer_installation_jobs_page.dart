import 'package:flutter/material.dart';

class TransferInstallationJobsPage extends StatefulWidget {
  final int initialTab;

  const TransferInstallationJobsPage({super.key, this.initialTab = 0});

  @override
  State<TransferInstallationJobsPage> createState() =>
      _TransferInstallationJobsPageState();
}

class _TransferInstallationJobsPageState
    extends State<TransferInstallationJobsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _pendingJobs = [];
  final List<String> _completedJobs = [];

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
        title: const Text('Transfer Installation'),
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
        children: [
          _pendingJobs.isEmpty
              ? const Center(child: Text('No pending transfer installations'))
              : ListView(
                  children: _pendingJobs
                      .map((job) => ListTile(title: Text(job)))
                      .toList(),
                ),
          _completedJobs.isEmpty
              ? const Center(child: Text('No completed transfer installations'))
              : ListView(
                  children: _completedJobs
                      .map((job) => ListTile(title: Text(job)))
                      .toList(),
                ),
        ],
      ),
    );
  }
}
