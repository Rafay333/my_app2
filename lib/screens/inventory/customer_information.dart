import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CustomerInformationPage extends StatefulWidget {
  final Map<String, dynamic> device;

  const CustomerInformationPage({super.key, required this.device});

  @override
  State<CustomerInformationPage> createState() =>
      _CustomerInformationPageState();
}

class _CustomerInformationPageState extends State<CustomerInformationPage> {
  Map<String, dynamic>? customerInfo;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final String deviceId = (widget.device['deviceId'] ?? '').toString();
      final info = await ApiService.getCustomerInfo(deviceId);

      setState(() {
        customerInfo = info;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.blue[600], size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value.isEmpty ? Colors.grey[400] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String deviceId = (widget.device['deviceId'] ?? '').toString();
    final String phoneNumber = (widget.device['phoneNumber'] ?? '').toString();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Customer Information'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _loadCustomerInfo,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Information Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device ID',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Loading State
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),

            // Error State
            if (errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load customer information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(fontSize: 14, color: Colors.red[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCustomerInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // No Data State
            if (!isLoading && errorMessage == null && customerInfo == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[600],
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Customer Information Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This device is not yet assigned to a customer or the customer information is not available in the system.',
                      style: TextStyle(fontSize: 14, color: Colors.orange[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // Customer Information Display
            if (!isLoading && errorMessage == null && customerInfo != null) ...[
              // Customer Details Section
              _buildSectionHeader('Customer Details', Icons.person),
              _buildInfoCard(
                'Client Name',
                customerInfo!['cnm'] ?? '',
                icon: Icons.person,
              ),
              _buildInfoCard(
                'Client Contact',
                customerInfo!['cct'] ?? '',
                icon: Icons.phone,
              ),
              _buildInfoCard(
                'Unit Number',
                customerInfo!['unit'] ?? '',
                icon: Icons.confirmation_number,
              ),
              _buildInfoCard(
                'Lease Card',
                customerInfo!['lc'] ?? '',
                icon: Icons.credit_card,
              ),
              _buildInfoCard(
                'Lease Type',
                customerInfo!['ltt'] ?? '',
                icon: Icons.assignment,
              ),

              // Vehicle Information Section
              _buildSectionHeader('Vehicle Information', Icons.directions_car),
              _buildInfoCard(
                'Vehicle Model',
                customerInfo!['vmm'] ?? '',
                icon: Icons.directions_car,
              ),
              _buildInfoCard(
                'Registration Number',
                customerInfo!['reg'] ?? '',
                icon: Icons.app_registration,
              ),
              _buildInfoCard(
                'Engine Number',
                customerInfo!['eng'] ?? '',
                icon: Icons.settings,
              ),
              _buildInfoCard(
                'Chassis Number',
                customerInfo!['chss'] ?? '',
                icon: Icons.build,
              ),
              _buildInfoCard(
                'Vehicle Color',
                customerInfo!['vco'] ?? '',
                icon: Icons.palette,
              ),

              // Installation Details Section
              _buildSectionHeader('Installation Details', Icons.build_circle),
              _buildInfoCard(
                'Installed By',
                customerInfo!['inmm'] ?? '',
                icon: Icons.person_pin,
              ),
              _buildInfoCard(
                'Installation Location',
                customerInfo!['inlm'] ?? '',
                icon: Icons.location_on,
              ),
              _buildInfoCard(
                'Intimation Date/Location',
                customerInfo!['ind'] ?? '',
                icon: Icons.calendar_today,
              ),
              _buildInfoCard(
                'Intimated By',
                customerInfo!['inmb'] ?? '',
                icon: Icons.person_outline,
              ),
              _buildInfoCard(
                'Tracker Report Number',
                customerInfo!['prrn'] ?? '',
                icon: Icons.receipt,
              ),
              _buildInfoCard(
                'Branch',
                customerInfo!['branch'] ?? '',
                icon: Icons.business,
              ),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
