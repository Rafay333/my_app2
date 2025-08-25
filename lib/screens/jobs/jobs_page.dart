import 'package:flutter/material.dart';
import 'installation/installation_jobs_page.dart';
import 'removal_jobs_page.dart';
import 'redo_jobs_page.dart';
import 'removal_transfer_jobs_page.dart';
import 'transfer_installation_jobs_page.dart';
import 'inspection_jobs_page.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openJobType(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _jobTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _jobTile(
              icon: Icons.build,
              title: 'Installation',
              onTap: () => _openJobType(const InstallationJobsPage()),
            ),
            _jobTile(
              icon: Icons.delete_outline,
              title: 'Removal',
              onTap: () => _openJobType(const RemovalJobsPage()),
            ),
            _jobTile(
              icon: Icons.refresh,
              title: 'Redo',
              onTap: () => _openJobType(const RedoJobsPage()),
            ),
            _jobTile(
              icon: Icons.local_shipping_outlined,
              title: 'Removal Transfer',
              onTap: () => _openJobType(const RemovalTransferJobsPage()),
            ),
            _jobTile(
              icon: Icons.swap_horiz,
              title: 'Transfer Installation',
              onTap: () => _openJobType(const TransferInstallationJobsPage()),
            ),
            _jobTile(
              icon: Icons.verified_user_outlined,
              title: 'Inspection',
              onTap: () => _openJobType(const InspectionJobsPage()),
            ),
          ],
        ),
      ),
    );
  }
}
