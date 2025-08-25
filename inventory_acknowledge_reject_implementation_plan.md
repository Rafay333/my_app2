# Inventory Acknowledge/Reject Implementation Plan

## 1. Current Implementation Overview

### 1.1 Backend (ASP.NET)
The backend is implemented using ASP.NET with the following key components:

**InventoryController.cs**
- Located at: `AskTrackApi.Controllers.InventoryController`
- Uses JWT authentication for secure endpoints
- Manages device inventory with status tracking via `isinstalled` field

**Key Endpoints:**
1. `GET /api/inventory` - Get all inventory items for user's branch (JWT required)
2. `GET /api/inventory/branch/{branchName}` - Get inventory for specific branch (no auth)
3. `POST /api/inventory/acknowledge/{deviceId}` - Acknowledge a device (set to Processing)
4. `POST /api/inventory/reject/{deviceId}` - Reject a device (set to Rejected/Completed)

**Status Mapping (Backend):**
- `isinstalled = null` → Pending
- `isinstalled = false` → Processing (Acknowledged)
- `isinstalled = true` → Rejected/Completed

### 1.2 Frontend (Flutter)
The frontend is a Flutter mobile application with the following key components:

**API Service:**
- Located at: `lib/api_service.dart`
- Handles HTTP requests to backend API
- Contains methods for login, inventory retrieval, and device operations

**Inventory Page:**
- Located at: `lib/screens/inventory_page.dart`
- Displays devices in inventory with status indicators
- Provides buttons to acknowledge or reject devices

**Acknowledged Devices Service:**
- Located at: `lib/services/acknowledged_devices_service.dart`
- Manages a shared list of acknowledged devices across the app
- Used to populate installation jobs

## 2. Identified Issues

### 2.1 Status Mapping Mismatch
**Problem:** The backend and frontend use different field names and values for status tracking.

**Backend Response:**
```json
{
  "branch": "branch123",
  "deviceCount": 2,
  "devices": [
    {
      "deviceId": "DEV001",
      "groupAccount": "branch123",
      "phoneNumber": "1234567890",
      "isinstalled": null  // null = pending, false = processing, true = rejected/completed
    }
  ]
}
```

**Frontend Expectation:**
```dart
// Expects a 'status' field
final String status = (device['status'] ?? 'Pending').toString();
```

**Impact:** The frontend will always show "Pending" status because it's looking for a `status` field that doesn't exist in the backend response.

### 2.2 Incomplete Status Transformation
**Problem:** When devices are acknowledged or rejected in the frontend, the status is updated locally but not properly synchronized with the backend field names.

**In inventory_page.dart:**
```dart
// When acknowledging a device locally
setState(() {
  device['status'] = 'Processing';  // Only updates local copy
  _availableDevices.remove(device);
  _processingDevices.add(device);
});
```

## 3. Implementation Plan

### 3.1 Fix Status Mapping Issue

**Step 1: Update API Service**
Modify the `getInventory()` method in `lib/api_service.dart` to transform backend response:

```dart
// GET INVENTORY
static Future<Map<String, dynamic>> getInventory() async {
  try {
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/Inventory'), headers: headers)
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Transform isinstalled field to status field
      if (data['devices'] != null && data['devices'] is List) {
        data['devices'] = (data['devices'] as List).map((device) {
          final transformedDevice = Map<String, dynamic>.from(device);
          
          // Convert isinstalled to status
          if (device['isinstalled'] == null) {
            transformedDevice['status'] = 'Pending';
          } else if (device['isinstalled'] == false) {
            transformedDevice['status'] = 'Processing';
          } else if (device['isinstalled'] == true) {
            transformedDevice['status'] = 'Rejected';
          }
          
          return transformedDevice;
        }).toList();
      }
      
      return data;
    } else if (response.statusCode == 401) {
      await AuthService.clearAuthData();
      throw Exception('Session expired. Please log in again.');
    } else {
      throw Exception(
        'Failed to load inventory (status ${response.statusCode})',
      );
    }
  } catch (e) {
    if (e.toString().contains('TimeoutException')) {
      throw Exception(
        'Request timeout. Please check your internet connection.',
      );
    }
    throw Exception('Error fetching inventory: $e');
  }
}
```

**Step 2: Update Acknowledge/Reject Methods**
Modify the acknowledge and reject methods to properly handle the response:

```dart
// ACKNOWLEDGE DEVICE (Processing)
static Future<bool> acknowledgeReceipt(String deviceId, String type) async {
  try {
    final headers = await AuthService.getAuthHeaders();
    final url = '$baseUrl/Inventory/acknowledge/$deviceId';
    print('Acknowledging device at: $url'); // Debug log

    final response = await http
        .post(Uri.parse(url), headers: headers)
        .timeout(timeoutDuration);

    print('Acknowledge response status: ${response.statusCode}'); // Debug log
    print('Acknowledge response body: ${response.body}'); // Debug log

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    if (response.statusCode == 401) {
      await AuthService.clearAuthData();
      print('Authentication failed - token expired'); // Debug log
    } else if (response.statusCode == 404) {
      print('Device not found: $deviceId'); // Debug log
    } else {
      print('Unexpected status code: ${response.statusCode}'); // Debug log
    }
    return false;
  } catch (e) {
    print('Exception in acknowledgeReceipt: $e'); // Debug log
    throw Exception('Error acknowledging receipt: $e');
  }
}
```

### 3.2 Backend API Documentation

**Endpoint 1: Get Inventory**
- **URL:** `GET /api/inventory`
- **Authentication:** Required (JWT)
- **Response:**
```json
{
  "branch": "string",
  "deviceCount": "integer",
  "devices": [
    {
      "deviceId": "string",
      "groupAccount": "string",
      "phoneNumber": "string",
      "isinstalled": "boolean|null"
    }
  ]
}
```

**Endpoint 2: Acknowledge Device**
- **URL:** `POST /api/inventory/acknowledge/{deviceId}`
- **Authentication:** Required (JWT)
- **Response:**
```json
{
  "message": "Device acknowledged and set to Processing."
}
```

**Endpoint 3: Reject Device**
- **URL:** `POST /api/inventory/reject/{deviceId}`
- **Authentication:** Required (JWT)
- **Response:**
```json
{
  "message": "Device rejected successfully."
}
```

### 3.3 Status Mapping Reference

| Backend (isinstalled) | Frontend (status) | Description |
|----------------------|-------------------|-------------|
| null | Pending | Device is available for acknowledgment |
| false | Processing | Device has been acknowledged and is being processed |
| true | Rejected | Device has been rejected |

## 4. Recommendations

### 4.1 Immediate Fixes
1. **Implement the status transformation** in the API service as described in section 3.1
2. **Add proper error handling** for network failures and backend errors
3. **Update UI to reflect actual backend status** after acknowledge/reject operations

### 4.2 Long-term Improvements
1. **Standardize status field naming** across frontend and backend
2. **Add comprehensive logging** for debugging acknowledge/reject operations
3. **Implement offline support** for acknowledge/reject operations with sync when online
4. **Add unit tests** for API service methods
5. **Consider using enums** for status values instead of string literals

### 4.3 Backend Improvements
1. **Add more detailed response messages** from backend API endpoints
2. **Implement proper validation** for device IDs and branch information
3. **Add audit logging** for acknowledge/reject operations
4. **Consider adding a status history** for devices

## 5. Implementation Workflow

### Phase 1: Fix Status Mapping (1-2 days