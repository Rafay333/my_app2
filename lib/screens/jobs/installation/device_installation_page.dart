import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';
import '../../../models/device_status.dart';

class DeviceInstallationPage extends StatefulWidget {
  final Map<String, dynamic> device;
  final Function(
    String acknowledgedDeviceId,
    String actualInstalledDeviceId,
    bool testingOk,
    String remarks,
    String deviceType,
    bool isPartialInstallation,
  )
  onComplete;

  const DeviceInstallationPage({
    super.key,
    required this.device,
    required this.onComplete,
  });

  @override
  State<DeviceInstallationPage> createState() => _DeviceInstallationPageState();
}

class _DeviceInstallationPageState extends State<DeviceInstallationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _installedDeviceController = TextEditingController();
  final _deviceIdFocusNode = FocusNode();

  bool _testingOk = true;
  bool _isLoading = false;
  bool _isValidatingDevice = false;
  List<Map<String, dynamic>> _availableDevices = [];
  String? _deviceValidationError;

  // Location Tracking variables
  bool _isTrackingLocation = false;
  String? _trackingError;
  String? _currentLocation;

  // Device Status Testing variables
  bool _isTesting = false;
  bool? _testResult; // null = not tested, true = success, false = failed
  String? _testError;
  DeviceStatus? _currentDeviceStatus;

  // Picture functionality
  List<File> _capturedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  static const int _minImages = 2;
  static const int _maxImages = 10;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Device/Installation options
  final List<String> _deviceTypes = [
    'OBD-I',
    'OBD-II',
    'Tape',
    'Rely',
    'Tie Clip',
    'Wire Thimble',
    'Toll Bag',
    'Tools',
    'Cap',
    'Uniform',
  ];

  String _selectedDeviceType = 'OBD-I';

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _loadAvailableDevices();
    _startAnimations();

    // Auto-focus on device ID field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceIdFocusNode.requestFocus();
    });
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadAvailableDevices() async {
    try {
      final devices = await ApiService.getAvailableDevicesForInstallation();
      if (mounted) {
        setState(() {
          _availableDevices = devices;
        });
      }
    } catch (e) {
      // Silently handle error - devices will remain empty
    }
  }

  Future<void> _validateDeviceId(String deviceId) async {
    if (deviceId.trim().isEmpty) {
      setState(() {
        _deviceValidationError = null;
        _isValidatingDevice = false;
      });
      return;
    }

    setState(() {
      _isValidatingDevice = true;
      _deviceValidationError = null;
    });

    try {
      final validationResult = await ApiService.validateDeviceInInventory(
        deviceId,
      );

      if (mounted) {
        setState(() {
          if (validationResult['exists'] == true) {
            _deviceValidationError = null;
            // Haptic feedback on success
            HapticFeedback.lightImpact();
          } else {
            _deviceValidationError =
                validationResult['message'] ?? 'Device not found in inventory';
            HapticFeedback.mediumImpact();
          }
          _isValidatingDevice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deviceValidationError =
              'Unable to validate device. Please check your connection.';
          _isValidatingDevice = false;
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  // Start Location Tracking - only if device ID is entered
  Future<void> _startLocationTracking() async {
    if (_installedDeviceController.text.trim().isEmpty) {
      _showSnackBar('Please enter device ID first', Colors.orange);
      return;
    }

    if (_deviceValidationError != null) {
      _showSnackBar('Please enter a valid device ID first', Colors.orange);
      return;
    }

    setState(() {
      _isTrackingLocation = true;
      _trackingError = null;
      _currentLocation = null;
    });

    try {
      // Start location tracking via your API
      final trackingResult = await ApiService.startLocationTracking(
        _installedDeviceController.text.trim(),
      );

      if (trackingResult['success'] == true && mounted) {
        setState(() {
          _currentLocation = trackingResult['location'] ?? 'Tracking started';
        });
        _showSnackBar('Location tracking started successfully', Colors.green);
        HapticFeedback.lightImpact();
      } else if (mounted) {
        setState(() {
          _trackingError =
              trackingResult['message'] ?? 'Failed to start tracking';
          _isTrackingLocation = false;
        });
        _showSnackBar(_trackingError!, Colors.red);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _trackingError = 'Failed to start tracking: ${e.toString()}';
          _isTrackingLocation = false;
        });
        _showSnackBar(_trackingError!, Colors.red);
        HapticFeedback.heavyImpact();
      }
    }
  }

  // Stop Location Tracking
  Future<void> _stopLocationTracking() async {
    if (!_isTrackingLocation) return;

    try {
      // Stop location tracking via your API
      await ApiService.stopLocationTracking(
        _installedDeviceController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isTrackingLocation = false;
          _currentLocation = null;
          _trackingError = null;
        });
      }
    } catch (e) {
      // Silently handle error when stopping
      if (mounted) {
        setState(() {
          _isTrackingLocation = false;
        });
      }
    }
  }

  // Device Status Check Method - requires tracking to be started first
  Future<void> _testDeviceConnection() async {
    if (_installedDeviceController.text.trim().isEmpty) {
      _showSnackBar('Please enter device ID first', Colors.orange);
      return;
    }

    if (!_isTrackingLocation) {
      _showSnackBar('Please start location tracking first', Colors.orange);
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testError = null;
      _currentDeviceStatus = null;
    });

    try {
      // Call your C# backend API to get device status
      final deviceStatus = await ApiService.getDeviceStatus(
        _installedDeviceController.text.trim(),
      );

      if (deviceStatus != null) {
        setState(() {
          _currentDeviceStatus = deviceStatus;
          _isTesting = false;

          // Check if device has valid location data (even if GPS currently unavailable)
          bool hasValidLocation =
              (deviceStatus.latitude != 0.0 || deviceStatus.longitude != 0.0) &&
              !(deviceStatus.latitude == 0.0 && deviceStatus.longitude == 0.0);

          // Device test passes if:
          // 1. Device is currently connected, OR
          // 2. Device has valid coordinates and was active within last 7 days
          bool isRecentlyActive = deviceStatus.gpsSent.isAfter(
            DateTime.now().subtract(Duration(days: 7)),
          );

          _testResult =
              deviceStatus.isConnected ||
              (hasValidLocation && isRecentlyActive);
          _testingOk = _testResult ?? false;
        });

        if (deviceStatus.isConnected) {
          _showSnackBar(
            'Device is connected and sending GPS data!',
            Colors.green,
          );
          HapticFeedback.lightImpact();
        } else if (_testResult == true) {
          _showSnackBar(
            'Device found with valid location data (GPS currently ${deviceStatus.gpsAvailable ? "available" : "unavailable"})',
            Colors.orange,
          );
          HapticFeedback.mediumImpact();
        } else {
          _showSnackBar(
            'Device test failed: ${deviceStatus.connectionStatus.toLowerCase()}',
            Colors.red,
          );
          HapticFeedback.heavyImpact();
        }
      } else {
        // Device not found in your backend
        setState(() {
          _isTesting = false;
          _testResult = false;
          _testingOk = false;
          _testError = 'Device not found in GPS tracking system';
        });
        _showSnackBar(_testError!, Colors.red);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = false;
        _testingOk = false;
        _testError = 'Connection test failed: ${e.toString()}';
      });
      _showSnackBar(_testError!, Colors.red);
      HapticFeedback.heavyImpact();
    }
  }

  void _showError() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Installation Error'),
          ],
        ),
        content: const Text(
          'There was an issue with the device installation. Please check all connections and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Retry'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handlePartialInstallation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report Issue'),
          ),
        ],
      ),
    );
  }

  void _handlePartialInstallation() async {
    // Stop tracking before partial installation
    await _stopLocationTracking();

    // For partial installation, only validate basic requirements (not device test)
    if (_installedDeviceController.text.trim().isEmpty) {
      _showSnackBar('Please enter device ID', Colors.orange);
      return;
    }

    if (_deviceValidationError != null) {
      _showSnackBar('Please enter a valid device ID', Colors.orange);
      return;
    }

    if (_remarksController.text.trim().isEmpty) {
      _showSnackBar(
        'Please provide remarks for partial installation',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final acknowledgedDeviceId = widget.device['deviceId'] ?? '';
      final actualInstalledDeviceId = _installedDeviceController.text.trim();

      // Call API for partial installation
      final result = await ApiService.completePartialInstallation(
        acknowledgedDeviceId: acknowledgedDeviceId,
        actualInstalledDeviceId: actualInstalledDeviceId,
        remarks: _remarksController.text.trim(),
        deviceType: _selectedDeviceType,
      );

      if (result['success'] == true && mounted) {
        // Call onComplete with isPartialInstallation = true
        widget.onComplete(
          acknowledgedDeviceId,
          actualInstalledDeviceId,
          false, // testingOk is always false for partial installations
          _remarksController.text.trim(),
          _selectedDeviceType,
          true, // isPartialInstallation = true
        );

        Navigator.pop(context);
        _showSnackBar(
          result['message'] ?? 'Partial installation recorded',
          Colors.orange,
        );
        HapticFeedback.lightImpact();
      } else if (mounted) {
        final errorMessage =
            result['message'] ?? 'Failed to record partial installation';
        _showSnackBar(errorMessage, Colors.red);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Unexpected error: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _completeInstallation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Stop tracking before completing installation
    await _stopLocationTracking();

    setState(() {
      _isLoading = true;
    });

    try {
      final acknowledgedDeviceId = widget.device['deviceId'] ?? '';
      final actualInstalledDeviceId = _installedDeviceController.text.trim();

      // Call API to complete installation
      final result = await ApiService.completeInstallation(
        acknowledgedDeviceId: acknowledgedDeviceId,
        actualInstalledDeviceId: actualInstalledDeviceId,
        testingOk: _testingOk,
        remarks: _remarksController.text.trim(),
        deviceType: _selectedDeviceType,
      );

      if (result['success'] == true && mounted) {
        // Success - update local state and UI
        widget.onComplete(
          acknowledgedDeviceId,
          actualInstalledDeviceId,
          _testingOk,
          _remarksController.text.trim(),
          _selectedDeviceType,
          false, // isPartialInstallation = false
        );

        Navigator.pop(context);
        _showSnackBar(
          result['message'] ??
              'Installation completed for device $actualInstalledDeviceId',
          Colors.green,
        );
        HapticFeedback.lightImpact();
      } else if (mounted) {
        // Failed - show specific error message
        final errorMessage =
            result['message'] ?? 'Failed to complete installation';
        _showSnackBar(errorMessage, Colors.red);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Unexpected error: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancelInstallation() async {
    // Stop tracking before canceling
    await _stopLocationTracking();
    Navigator.pop(context);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: color == Colors.red ? 5 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Launch Google Maps with device location
  Future<void> _openGoogleMaps() async {
    if (_currentDeviceStatus == null) {
      _showSnackBar('No location data available', Colors.orange);
      return;
    }

    try {
      final url = _currentDeviceStatus!.googleMapsUrl;
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        HapticFeedback.lightImpact();
      } else {
        _showSnackBar('Could not open Google Maps', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error opening Google Maps: ${e.toString()}', Colors.red);
    }
  }

  /// Build a status row for device information display
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedImages.add(File(image.path));
        });

        HapticFeedback.lightImpact();
        _showSnackBar(
          'Picture ${_capturedImages.length} captured successfully',
          Colors.green,
        );
      }
    } catch (e) {
      _showSnackBar('Failed to take picture: ${e.toString()}', Colors.red);
    }
  }

  void _removeImage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Picture'),
        content: const Text('Are you sure you want to remove this picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _capturedImages.removeAt(index);
              });
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              _showSnackBar('Picture removed', Colors.orange);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDeviceList() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Available Devices'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _availableDevices.isNotEmpty
              ? ListView.builder(
                  itemCount: _availableDevices.length,
                  itemBuilder: (context, index) {
                    final device = _availableDevices[index];
                    final deviceId = device['deviceId'] ?? '';
                    final phone = device['phoneNumber'] ?? '';
                    final status = device['status'] ?? 'Unknown';

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.memory, color: Colors.blue),
                          ),
                          title: Text(
                            deviceId,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone: $phone'),
                              Text('Status: $status'),
                            ],
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () {
                              _installedDeviceController.text = deviceId;
                              _validateDeviceId(deviceId);
                              Navigator.pop(ctx);
                              HapticFeedback.selectionClick();
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Select'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 36),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No available devices found'),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Stop tracking when disposing
    _stopLocationTracking();
    _remarksController.dispose();
    _installedDeviceController.dispose();
    _deviceIdFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon and title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.wifi,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Install Device ${widget.device['deviceId'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Installing for: ${widget.device['deviceId'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _cancelInstallation,
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Device Selection
                        Text(
                          'Select Actual Installed Device',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          label: 'Device ID input field',
                          hint: 'Enter device ID from inventory',
                          child: TextFormField(
                            controller: _installedDeviceController,
                            focusNode: _deviceIdFocusNode,
                            enabled: !_isLoading,
                            onChanged: (value) {
                              // Clear previous validation errors when user starts typing
                              if (_deviceValidationError != null) {
                                setState(() {
                                  _deviceValidationError = null;
                                });
                              }

                              if (value.length >= 3) {
                                _validateDeviceId(value);
                              } else {
                                setState(() {
                                  _deviceValidationError = null;
                                  _isValidatingDevice = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Device ID from inventory...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isValidatingDevice)
                                    const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  else if (_deviceValidationError == null &&
                                      _installedDeviceController
                                          .text
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  else if (_deviceValidationError != null)
                                    const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  if (_availableDevices.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.list_alt),
                                      onPressed: _showDeviceList,
                                      tooltip: 'Select from available devices',
                                    ),
                                ],
                              ),
                              errorText: _deviceValidationError,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the device ID from inventory';
                              }
                              if (_deviceValidationError != null) {
                                return _deviceValidationError;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Location Tracking Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    color: Colors.purple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Location Tracking',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start tracking location before testing device connection',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Start Tracking Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (_isTrackingLocation ||
                                          _installedDeviceController.text
                                              .trim()
                                              .isEmpty ||
                                          _deviceValidationError != null)
                                      ? null
                                      : _startLocationTracking,
                                  icon: _isTrackingLocation
                                      ? const Icon(Icons.location_on)
                                      : const Icon(Icons.location_off),
                                  label: Text(
                                    _isTrackingLocation
                                        ? 'Tracking Location...'
                                        : 'Start Location Tracking',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isTrackingLocation
                                        ? Colors.green
                                        : Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),

                              // Tracking Status Display
                              if (_isTrackingLocation ||
                                  _trackingError != null) ...[
                                const SizedBox(height: 12),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isTrackingLocation
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isTrackingLocation
                                          ? Colors.green.shade200
                                          : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _isTrackingLocation
                                                ? Icons.location_on
                                                : Icons.location_off,
                                            color: _isTrackingLocation
                                                ? Colors.green
                                                : Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _isTrackingLocation
                                                  ? 'Location Tracking Active'
                                                  : 'Tracking Failed',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _isTrackingLocation
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_currentLocation != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _currentLocation!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      if (_trackingError != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _trackingError!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Device Testing Section - requires tracking to be started first
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.wifi_find,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Device Connection Test',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check if device is connected and sending GPS data (requires location tracking)',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Test Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (_isTesting ||
                                          _installedDeviceController.text
                                              .trim()
                                              .isEmpty ||
                                          !_isTrackingLocation)
                                      ? null
                                      : _testDeviceConnection,
                                  icon: _isTesting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(Icons.location_searching),
                                  label: Text(
                                    _isTesting
                                        ? 'Checking Connection...'
                                        : 'Test Device Connection',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isTesting
                                        ? Colors.orange
                                        : (_testResult == true
                                              ? Colors.green
                                              : Colors.blue),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),

                              // Requirement notice
                              if (!_isTrackingLocation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Start location tracking first',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Test Result Display
                              if (_testResult != null || _isTesting) ...[
                                const SizedBox(height: 12),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isTesting
                                        ? Colors.orange.shade50
                                        : (_testResult == true
                                              ? Colors.green.shade50
                                              : Colors.red.shade50),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isTesting
                                          ? Colors.orange.shade200
                                          : (_testResult == true
                                                ? Colors.green.shade200
                                                : Colors.red.shade200),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _isTesting
                                                ? Icons.hourglass_empty
                                                : (_testResult == true
                                                      ? Icons.check_circle
                                                      : Icons.error),
                                            color: _isTesting
                                                ? Colors.orange
                                                : (_testResult == true
                                                      ? Colors.green
                                                      : Colors.red),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _isTesting
                                                  ? 'Testing in progress...'
                                                  : (_testResult == true
                                                        ? 'Test Successful'
                                                        : 'Test Failed'),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _isTesting
                                                    ? Colors.orange.shade700
                                                    : (_testResult == true
                                                          ? Colors
                                                                .green
                                                                .shade700
                                                          : Colors
                                                                .red
                                                                .shade700),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_currentDeviceStatus != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildStatusRow(
                                                'Status',
                                                _currentDeviceStatus!
                                                    .connectionStatus,
                                              ),
                                              _buildStatusRow(
                                                'GPS',
                                                _currentDeviceStatus!
                                                        .gpsAvailable
                                                    ? "Available"
                                                    : "Unavailable",
                                              ),

                                              // Clickable Location Row
                                              Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 60,
                                                    child: Text(
                                                      'Location:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: _openGoogleMaps,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .blue
                                                              .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors
                                                                .blue
                                                                .shade200,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.location_on,
                                                              size: 14,
                                                              color: Colors
                                                                  .blue
                                                                  .shade700,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                '${_currentDeviceStatus!.latitude.toStringAsFixed(6)}, ${_currentDeviceStatus!.longitude.toStringAsFixed(6)}',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'monospace',
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .blue
                                                                      .shade700,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                            Icon(
                                                              Icons.open_in_new,
                                                              size: 12,
                                                              color: Colors
                                                                  .blue
                                                                  .shade700,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),

                                              _buildStatusRow(
                                                'Speed',
                                                '${_currentDeviceStatus!.speed.toStringAsFixed(1)} km/h',
                                              ),
                                              _buildStatusRow(
                                                'Last Update',
                                                _currentDeviceStatus!.gpsSent
                                                    .toString()
                                                    .substring(0, 19),
                                              ),
                                              _buildStatusRow(
                                                'User',
                                                '${_currentDeviceStatus!.userName} (${_currentDeviceStatus!.phoneNumber})',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (_testError != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _testError!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              // Auto Testing Status Indicator
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _testResult == null
                                      ? Colors.grey.shade50
                                      : (_testResult == true
                                            ? Colors.green.shade50
                                            : Colors.red.shade50),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _testResult == null
                                        ? Colors.grey.shade200
                                        : (_testResult == true
                                              ? Colors.green.shade200
                                              : Colors.red.shade200),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _testResult == null
                                          ? Icons.help_outline
                                          : (_testResult == true
                                                ? Icons.check_circle
                                                : Icons.error),
                                      color: _testResult == null
                                          ? Colors.grey.shade600
                                          : (_testResult == true
                                                ? Colors.green
                                                : Colors.red),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Testing Status:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _testResult == null
                                            ? Colors.grey.shade600
                                            : (_testResult == true
                                                  ? Colors.green
                                                  : Colors.red),
                                        fontSize: 16,
                                      ),
                                      child: Text(
                                        _testResult == null
                                            ? 'Not Tested'
                                            : (_testResult == true
                                                  ? 'PASS'
                                                  : 'FAIL'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Pictures Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Installation Pictures',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_capturedImages.length}/$_maxImages',
                                    style: TextStyle(
                                      color:
                                          _capturedImages.length >= _minImages
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take $_minImages-$_maxImages pictures of the installation',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Camera Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _capturedImages.length >= _maxImages
                                      ? null
                                      : _takePicture,
                                  icon: const Icon(Icons.camera_alt),
                                  label: Text(
                                    _capturedImages.length >= _maxImages
                                        ? 'Maximum pictures reached'
                                        : 'Take Picture',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),

                              // Image Grid
                              if (_capturedImages.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _capturedImages.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                _capturedImages[index],
                                                width: 100,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _removeImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // Validation message
                              if (_capturedImages.length < _minImages)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Please take at least $_minImages pictures',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Device Type Selection
                        Semantics(
                          label: 'Device type selection',
                          child: DropdownButtonFormField<String>(
                            value: _selectedDeviceType,
                            decoration: InputDecoration(
                              labelText: 'Select Device Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.devices,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _deviceTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedDeviceType = value!;
                                    });
                                    HapticFeedback.selectionClick();
                                  },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a device type';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Remarks Field
                        Semantics(
                          label: 'Remarks input field',
                          hint: 'Enter any additional notes or observations',
                          child: TextFormField(
                            controller: _remarksController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Remarks',
                              hintText: 'Add any additional notes here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit_note,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: 3,
                            validator: (value) {
                              // This validator is only used for complete installation
                              // Partial installation has its own validation in _handlePartialInstallation
                              if (!_testingOk &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please provide remarks when testing failed';
                              }
                              if (_capturedImages.length < _minImages) {
                                return 'Please take at least $_minImages pictures';
                              }
                              if (_testResult == null) {
                                return 'Please test the device connection first';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Column(
                          children: [
                            // Complete Installation Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _completeInstallation,
                                icon: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.check_circle),
                                label: const Text(
                                  'Complete Installation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // partial installation and cancel buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _handlePartialInstallation,
                                    icon: const Icon(Icons.error_outline),
                                    label: const Text('Partial Installation'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _cancelInstallation,
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
