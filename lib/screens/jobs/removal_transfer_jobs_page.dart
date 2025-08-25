import 'package:flutter/material.dart';

class RemovalTransferJobsPage extends StatefulWidget {
  final int initialTab;
  const RemovalTransferJobsPage({super.key, this.initialTab = 0});

  @override
  State<RemovalTransferJobsPage> createState() =>
      _RemovalTransferJobsPageState();
}

class _RemovalTransferJobsPageState extends State<RemovalTransferJobsPage>
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
        title: const Text('Removal Transfer'),
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
          Center(child: Text('No pending removal transfers')),
          Center(child: Text('No completed removal transfers')),
        ],
      ),
    );
  }
}
