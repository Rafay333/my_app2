import 'package:flutter/material.dart';
import '../inventory/inventory_page.dart';

class PaymentPage extends StatefulWidget {
  final int initialTab;
  const PaymentPage({super.key, this.initialTab = 0});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
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

  void _openPayment(Map<String, dynamic> payment) {
    final remarks = TextEditingController();
    bool paymentReceived = false;
    String paymentMethod = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text('Process Payment ${payment['jobId'] ?? ''}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Payment Received'),
                  const SizedBox(width: 8),
                  Switch(
                    value: paymentReceived,
                    onChanged: (v) => setInner(() => paymentReceived = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: ['Cash', 'Bank Transfer', 'Check', 'Online'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setInner(() {
                    paymentMethod = newValue!;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: remarks,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                  () => _completed.add({
                    'jobId': payment['jobId'],
                    'amount': payment['amount'],
                    'remarks': remarks.text,
                    'paymentReceived': paymentReceived,
                    'paymentMethod': paymentMethod,
                    'timestamp': DateTime.now().toIso8601String(),
                  }),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment processed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Back to Inventory Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Inventory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending Payments Tab
                _buildPendingPayments(),
                // Completed Payments Tab
                _buildCompletedPayments(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPayments() {
    final pendingPayments = [
      {
        'jobId': 'JOB001',
        'amount': 'PKR 1,500',
        'date': '2024-01-15',
        'status': 'Pending',
        'type': 'Installation',
        'deviceId': 'DEV001',
        'phoneNumber': '+92 300 1234567',
      },
      {
        'jobId': 'JOB002',
        'amount': 'PKR 2,000',
        'date': '2024-01-16',
        'status': 'Pending',
        'type': 'Removal',
        'deviceId': 'DEV002',
        'phoneNumber': '+92 301 2345678',
      },
      {
        'jobId': 'JOB003',
        'amount': 'PKR 1,800',
        'date': '2024-01-17',
        'status': 'Pending',
        'type': 'Transfer',
        'deviceId': 'DEV003',
        'phoneNumber': '+92 302 3456789',
      },
    ];

    if (pendingPayments.isEmpty) {
      return const Center(child: Text('No pending payments'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pendingPayments.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (_, i) {
        final payment = pendingPayments[i];
        return ListTile(
          title: Text('Job ${payment['jobId'] ?? ''}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(payment['phoneNumber'] ?? ''),
              Text('Amount: ${payment['amount'] ?? ''}'),
              Text('Type: ${payment['type'] ?? ''}'),
            ],
          ),
          trailing: ElevatedButton(
            onPressed: () => _openPayment(payment),
            child: const Text('Process Payment'),
          ),
        );
      },
    );
  }

  Widget _buildCompletedPayments() {
    if (_completed.isEmpty) {
      return const Center(child: Text('No completed payments'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _completed.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (_, i) {
        final payment = _completed[i];
        return ListTile(
          title: Text('Job ${payment['jobId'] ?? ''}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ${payment['amount'] ?? ''}'),
              Text('Method: ${payment['paymentMethod'] ?? ''}'),
              Text(
                'Received: ${payment['paymentReceived'] == true ? 'Yes' : 'No'}',
              ),
              if (payment['remarks']?.isNotEmpty == true)
                Text('Remarks: ${payment['remarks']}'),
            ],
          ),
          trailing: Text(payment['timestamp'] ?? ''),
        );
      },
    );
  }
}
