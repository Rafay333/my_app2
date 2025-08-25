import 'package:flutter/material.dart';
import '../../../services/acknowledged_devices_service.dart';
import '../../inventory/customer_information.dart';
import 'device_installation_page.dart';

class InstallationJobsPage extends StatefulWidget {
  final int initialTab; // 0 pending, 1 completed
  const InstallationJobsPage({super.key, this.initialTab = 0});

  @override
  State<InstallationJobsPage> createState() => _InstallationJobsPageState();
}

class _InstallationJobsPageState extends State<InstallationJobsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AcknowledgedDevicesService _ackService = AcknowledgedDevicesService();
  final List<Map<String, dynamic>> _completed = [];

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

  void _openInstall(Map<String, dynamic> device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceInstallationPage(
          device: device,
          onComplete:
              (
                acknowledgedDeviceId,
                actualInstalledDeviceId,
                testingOk,
                remarks,
                deviceType,
                isPartialInstallation,
              ) {
                setState(() {
                  _completed.add({
                    'acknowledgedDeviceId': acknowledgedDeviceId,
                    'actualInstalledDeviceId': actualInstalledDeviceId,
                    'clientPhone': device['phoneNumber'],
                    'remarks': remarks,
                    'testingOk': testingOk,
                    'deviceType': deviceType,
                    'isPartialInstallation': isPartialInstallation,
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                });

                // Only remove from pending and add to completed if it's a full installation
                if (!isPartialInstallation) {
                  // Remove from acknowledged devices (goes back to pending)
                  _ackService.removeByDeviceId(acknowledgedDeviceId);

                  // Add the completed installation to personal inventory with completed status
                  final completedDevice = Map<String, dynamic>.from(device);
                  completedDevice['actualDeviceId'] = actualInstalledDeviceId;
                  completedDevice['status'] = 'Completed';
                  completedDevice['isinstalled'] = true;
                  completedDevice['testingOk'] = testingOk;
                  completedDevice['remarks'] = remarks;
                  completedDevice['deviceType'] = deviceType;
                  _ackService.addCompletedDevice(completedDevice);
                } else {
                  // For partial installations, update status to 'Partial' but keep in pending
                  _ackService.updateDeviceStatus(acknowledgedDeviceId, 'Partial');
                }
              },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installation'),
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
          // Pending Installations Tab
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _ackService.acknowledgedDevices,
            builder: (context, list, _) {
              if (list.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No pending installations',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Acknowledge devices from inventory to start installation',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final d = list[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Device ID with Status and Icon
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d['deviceId'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              // Info Icon
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CustomerInformationPage(device: d),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Phone Number
                          Text(
                            d['phoneNumber'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Install Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _openInstall(d),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Install',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Completed Installations Tab
          _completed.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No completed installations',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _completed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = _completed[i];
                    return Card(
                      elevation: 2,
                      child: ExpansionTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: d['isPartialInstallation'] == true
                                ? Colors.orange
                                : (d['testingOk'] == true
                                    ? Colors.green
                                    : Colors.red),
                          ),
                        ),
                        title: Text(
                          d['isPartialInstallation'] == true
                              ? 'Partial Installation: ${d['actualInstalledDeviceId'] ?? 'N/A'}'
                              : 'Installed: ${d['actualInstalledDeviceId'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'For Client: ${d['acknowledgedDeviceId'] ?? 'N/A'}${d['isPartialInstallation'] == true ? ' (Partial)' : ''}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Client Device ID',
                                  d['acknowledgedDeviceId'],
                                ),
                                _buildDetailRow(
                                  'Client Phone',
                                  d['clientPhone'],
                                ),
                                _buildDetailRow(
                                  'Actual Installed Device',
                                  d['actualInstalledDeviceId'],
                                ),
                                _buildDetailRow('Device Type', d['deviceType']),
                                Row(
                                  children: [
                                    const Text(
                                      'Testing OK: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      d['testingOk'] == true ? 'Yes' : 'No',
                                      style: TextStyle(
                                        color: d['testingOk'] == true
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (d['remarks'] != null &&
                                    d['remarks'].isNotEmpty)
                                  _buildDetailRow('Remarks', d['remarks']),
                                _buildDetailRow(
                                  'Completed',
                                  _formatTimestamp(d['timestamp']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
