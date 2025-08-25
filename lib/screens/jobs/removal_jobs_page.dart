import 'package:flutter/material.dart';

class RemovalJobsPage extends StatefulWidget {
  final int initialTab;
  const RemovalJobsPage({super.key, this.initialTab = 0});

  @override
  State<RemovalJobsPage> createState() => _RemovalJobsPageState();
}

class _RemovalJobsPageState extends State<RemovalJobsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _pending = [];
  final List<String> _completed = [];

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
        title: const Text('Removal'),
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
          _pending.isEmpty
              ? const Center(child: Text('No pending removals'))
              : ListView(
                  children: _pending
                      .map((e) => ListTile(title: Text(e)))
                      .toList(),
                ),
          _completed.isEmpty
              ? const Center(child: Text('No completed removals'))
              : ListView(
                  children: _completed
                      .map((e) => ListTile(title: Text(e)))
                      .toList(),
                ),
        ],
      ),
    );
  }
}
