import 'package:flutter/material.dart';

class RedoJobsPage extends StatefulWidget {
  final int initialTab;
  const RedoJobsPage({super.key, this.initialTab = 0});

  @override
  State<RedoJobsPage> createState() => _RedoJobsPageState();
}

class _RedoJobsPageState extends State<RedoJobsPage>
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
        title: const Text('Redo'),
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
          Center(child: Text('No pending redo jobs')),
          Center(child: Text('No completed redo jobs')),
        ],
      ),
    );
  }
}
