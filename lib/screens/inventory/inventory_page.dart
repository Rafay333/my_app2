import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/acknowledged_devices_service.dart';
import 'personal_inventory_page.dart'; // Import the new page
import 'customer_information.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late Future<Map<String, dynamic>> _inventoryFuture;

  // Local state for rows and operation loading
  final List<Map<String, dynamic>> _availableDevices = [];
  final List<Map<String, dynamic>> _processingDevices = [];
  final List<Map<String, dynamic>> _rejectedDevices = [];
  bool _initialized = false;
  bool _opLoading = false;

  final AcknowledgedDevicesService _ackService = AcknowledgedDevicesService();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = ApiService.getInventory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshInventory() async {
    setState(() {
      _initialized = false;
      _availableDevices.clear();
      _processingDevices.clear();
      _rejectedDevices.clear();
    });
    _inventoryFuture = ApiService.getInventory();
    setState(() {});
  }

  void _initListsFromApi(Map<String, dynamic> data) {
    if (_initialized) return; // Prevent multiple initializations

    _availableDevices.clear();
    _processingDevices.clear();
    _rejectedDevices.clear();

    final List<dynamic> devices = (data['devices'] ?? []) as List<dynamic>;

    for (final dynamic d in devices) {
      final Map<String, dynamic> device = Map<String, dynamic>.from(d as Map);

      // Backend uses isinstalled field: null = Pending, false = Processing, true = Rejected
      final dynamic isInstalled = device['isinstalled'];
      String status;

      if (isInstalled == null) {
        status = 'Pending';
        _availableDevices.add(device);
      } else if (isInstalled == false) {
        status = 'Processing';
        _processingDevices.add(device);
      } else if (isInstalled == true) {
        status = 'Rejected';
        _rejectedDevices.add(device);
      } else {
        status = 'Unknown';
        // Add to available by default for unknown status
        _availableDevices.add(device);
      }

      // Set the status for display
      device['status'] = status;

      // Debug log to help identify status issues
      print(
        'Device ${device['deviceId']} has status: $status (isinstalled: ${device['isinstalled']})',
      );
    }

    // Remove devices from available list if they've been acknowledged
    final acknowledgedDevices = _ackService.acknowledgedDevices.value;
    for (final acknowledgedDevice in acknowledgedDevices) {
      final String deviceId = (acknowledgedDevice['deviceId'] ?? '').toString();

      _availableDevices.removeWhere(
        (d) => (d['deviceId'] ?? '').toString() == deviceId,
      );
    }

    _initialized = true;
  }

  Future<void> _acknowledgeDevice(Map<String, dynamic> device) async {
    if (_opLoading) return;

    final bool confirm = await _showConfirmDialog(
      'Confirm Acknowledgment',
      'Are you sure you want to acknowledge device ${device['deviceId'] ?? ''}?',
      'Acknowledge',
      Colors.green,
    );

    if (!confirm) return;

    setState(() => _opLoading = true);

    try {
      final String deviceId = (device['deviceId'] ?? '').toString();
      final String type = (device['type'] ?? 'Unknown').toString();
      final bool success = await ApiService.acknowledgeReceipt(deviceId, type);

      if (!mounted) return;

      if (success) {
        // Remove device from available list locally for immediate UI update
        setState(() {
          _availableDevices.removeWhere((d) => d['deviceId'] == deviceId);
        });

        // Add to shared acknowledged list for personal inventory
        device['status'] = 'Processing';
        device['isinstalled'] = false;
        _ackService.addDevice(device);

        _showSuccessSnackBar(
          'Acknowledged $deviceId - Check Personal Inventory',
        );

        // Force refresh to ensure backend state is synced
        await _refreshInventory();
      } else {
        _showErrorSnackBar('Failed to acknowledge device');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error acknowledging device: $e');
    } finally {
      if (mounted) {
        setState(() => _opLoading = false);
      }
    }
  }

  Future<void> _rejectDevice(Map<String, dynamic> device) async {
    if (_opLoading) return;

    final bool confirm = await _showConfirmDialog(
      'Confirm Rejection',
      'Are you sure you want to reject device ${device['deviceId'] ?? ''}?',
      'Reject',
      Colors.red,
    );

    if (!confirm) return;

    setState(() => _opLoading = true);

    try {
      final String deviceId = (device['deviceId'] ?? '').toString();
      final String type = (device['type'] ?? 'Unknown').toString();
      final bool success = await ApiService.rejectDevice(deviceId, type);

      if (!mounted) return;

      if (success) {
        // Move device from available to rejected locally for immediate UI update
        setState(() {
          _availableDevices.removeWhere((d) => d['deviceId'] == deviceId);
          device['status'] = 'Rejected';
          device['isinstalled'] = true;
          _rejectedDevices.add(device);
        });

        _showRejectSnackBar('Rejected $deviceId');
      } else {
        _showErrorSnackBar('Failed to reject device');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error rejecting device: $e');
    } finally {
      if (mounted) {
        setState(() => _opLoading = false);
      }
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String content,
    String actionText,
    Color actionColor,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: actionColor),
                child: Text(
                  actionText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showRejectSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildDeviceCard(
    Map<String, dynamic> device, {
    required bool showActions,
  }) {
    final String id = (device['deviceId'] ?? '').toString();
    final String phone = (device['phoneNumber'] ?? '').toString();
    final String status = (device['status'] ?? 'Pending').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    id,
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
                            CustomerInformationPage(device: device),
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
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
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
              phone,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _opLoading
                          ? null
                          : () => _acknowledgeDevice(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Acknowledge',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _opLoading
                          ? null
                          : () => _rejectDevice(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusSummary(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Device Inventory'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // Personal inventory button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PersonalInventoryPage(),
                ),
              );
            },
            icon: const Icon(Icons.person),
            tooltip: 'Personal Inventory',
          ),
          IconButton(
            onPressed: _refreshInventory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshInventory,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          // Check if we have valid data
          if (data['devices'] == null || data['devices'] is! List) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No inventory data available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('The inventory data format is invalid'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshInventory,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          _initListsFromApi(data);

          return ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _ackService.acknowledgedDevices,
            builder: (context, acknowledgedDevices, child) {
              return Column(
                children: [
                  // Branch info and summary
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Branch: ${data['branch'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatusSummary(
                              'Pending',
                              _availableDevices.length,
                              Colors.orange,
                            ),
                            _buildStatusSummary(
                              'Personal',
                              acknowledgedDevices.length,
                              Colors.blue,
                            ),
                          ],
                        ),
                        if (acknowledgedDevices.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PersonalInventoryPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person),
                            label: const Text('View Personal Inventory'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Device lists
                  Expanded(
                    child: ListView(
                      children: [
                        // Available devices section
                        if (_availableDevices.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: const Text(
                              'Available Devices (Pending)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          ..._availableDevices.map(
                            (device) =>
                                _buildDeviceCard(device, showActions: true),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Empty state
                        if (_availableDevices.isEmpty) ...[
                          const SizedBox(height: 50),
                          const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No pending devices found for this branch',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Check Personal Inventory for acknowledged devices',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
