import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/medication.dart';
import 'notification_service.dart';

/// BluetoothService manages all interactions with the BLE Smart Inhaler (BT05)
/// 
/// This service is responsible for:
/// - Scanning for nearby BLE devices
/// - Connecting to BT05 Smart Inhalers
/// - Reading data from connected devices
/// - Processing and interpreting inhaler usage data
/// - Broadcasting usage events to the application
class BluetoothService {
  // Singleton implementation to ensure a single instance throughout the app
  static final BluetoothService _instance = BluetoothService._();
  
  /// Factory constructor that returns the singleton instance
  factory BluetoothService() => _instance;
  
  /// Private constructor for singleton pattern
  BluetoothService._();

  // Core dependencies
  final NotificationService _notificationService = NotificationService();  // For user alerts
  
  // BT05 Specific Configuration (from working Python scripts)
  /// MAC Address of the specific BT05 device
  static const String bt05MacAddress = "04:A3:16:A8:94:D2";
  
  /// Service UUID for BT05 communication
  static const String bt05ServiceUuid = "0000ffe0-0000-1000-8000-00805f9b34fb";
  
  /// Characteristic UUID for BT05 data communication
  static const String bt05CharacteristicUuid = "0000ffe1-0000-1000-8000-00805f9b34fb";
  
  // Legacy configuration for generic devices (kept for backward compatibility)
  /// Name prefix used to identify Smart Inhalers during scanning
  final String _inhalerNamePrefix = 'SmartInhaler';
  
  /// Service UUID for the inhaler functionality (legacy)
  final String _inhalerServiceUuid = '1809';  // Health Thermometer service example
  
  /// Characteristic UUID for reading inhaler usage data (legacy)
  final String _inhalerCharacteristicUuid = '2A1C';  // Temperature Measurement characteristic example
  
  // State tracking variables
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;  // Manages the scan result stream
  fbp.BluetoothDevice? _connectedDevice;  // Currently connected inhaler device
  fbp.BluetoothCharacteristic? _inhalerCharacteristic;  // Characteristic for inhaler usage data
  bool _isScanning = false;  // Flag indicating if scanning is in progress
  bool _isConnected = false;  // Flag indicating if connected to an inhaler
  
  // Stream controllers for exposing state to the app
  /// Stream controller for broadcasting connection state changes
  final _isConnectedStreamController = StreamController<bool>.broadcast();
  
  /// Public stream that components can listen to for connection status updates
  Stream<bool> get isConnectedStream => _isConnectedStreamController.stream;
  
  /// Stream controller for broadcasting inhaler usage data
  final _inhalerDataStreamController = StreamController<Map<String, dynamic>>.broadcast();
  
  /// Public stream that components can listen to for inhaler usage data
  Stream<Map<String, dynamic>> get inhalerDataStream => _inhalerDataStreamController.stream;

  /// Starts scanning specifically for BT05 device
  /// 
  /// This method will:
  /// 1. Check if Bluetooth is enabled
  /// 2. Start scanning with a 30-second timeout
  /// 3. Look specifically for the BT05 device by MAC address
  /// 4. Automatically connect when found
  Future<void> startScanForBT05() async {
    // Prevent starting multiple scans simultaneously
    if (_isScanning) return;
    
    try {
      _isScanning = true;
      
      // Check if Bluetooth is enabled on the device
      if (await fbp.FlutterBluePlus.adapterState.first != fbp.BluetoothAdapterState.on) {
        _notificationService.showMessage(
          'Bluetooth is turned off',
          'Please turn on Bluetooth to connect to your BT05 device.'
        );
        _isScanning = false;
        return;
      }
      
      // Begin scanning for devices with a 30-second timeout
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
      
      // Listen for scan results and look for BT05 device
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (fbp.ScanResult result in results) {
          // Check if the device MAC address matches our BT05
          if (result.device.remoteId.toString().toUpperCase() == bt05MacAddress.toUpperCase()) {
            // Found the BT05 device, attempt to connect
            _connectToBT05Device(result.device);
            stopScan(); // Stop scanning once we find the device
            break;
          }
          // Also check by name if MAC address matching fails
          else if (result.device.platformName.toLowerCase().contains('bt05') ||
                   result.device.platformName.toLowerCase().contains('bt-05')) {
            _connectToBT05Device(result.device);
            stopScan();
            break;
          }
        }
      }, onError: (e) {
        // Handle scan errors
        _isScanning = false;
        _notificationService.showMessage(
          'Scan Error',
          'Error scanning for BT05: $e'
        );
      });
    } catch (e) {
      // Handle any exceptions during scan start
      _isScanning = false;
      _notificationService.showMessage(
        'Bluetooth Error',
        'Error starting BT05 scan: $e'
      );
    }
  }

  /// Attempts to connect directly to BT05 using the known MAC address
  /// 
  /// This method bypasses scanning and tries to connect directly
  Future<void> connectToBT05Direct() async {
    try {
      // Check if Bluetooth is enabled
      if (await fbp.FlutterBluePlus.adapterState.first != fbp.BluetoothAdapterState.on) {
        _notificationService.showMessage(
          'Bluetooth is turned off',
          'Please turn on Bluetooth to connect to BT05.'
        );
        return;
      }

      // Get list of bonded devices to see if BT05 is already paired
      List<fbp.BluetoothDevice> bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
      
      fbp.BluetoothDevice? bt05Device;
      for (fbp.BluetoothDevice device in bondedDevices) {
        if (device.remoteId.toString().toUpperCase() == bt05MacAddress.toUpperCase()) {
          bt05Device = device;
          break;
        }
      }

      if (bt05Device != null) {
        // Device is bonded, try to connect directly
        await _connectToBT05Device(bt05Device);
      } else {
        // Device not bonded, need to scan first
        _notificationService.showMessage(
          'BT05 Not Paired',
          'BT05 device is not paired. Please use scan to discover and pair first.'
        );
        await startScanForBT05();
      }
    } catch (e) {
      _notificationService.showMessage(
        'Direct Connection Error',
        'Failed to connect directly to BT05: $e'
      );
    }
  }

  /// Sends an AT command to the connected BT05 device
  /// 
  /// This method formats the command properly and sends it via BLE
  Future<void> sendATCommand(String command) async {
    if (!_isConnected || _inhalerCharacteristic == null) {
      throw Exception('Not connected to BT05 device');
    }

    try {
      // Format the command with proper line endings (as per Python script)
      String formattedCommand = command.trim();
      if (!formattedCommand.endsWith('\r\n')) {
        formattedCommand += '\r\n';
      }

      // Convert to bytes
      List<int> commandBytes = utf8.encode(formattedCommand);

      // Send the command via BLE characteristic
      await _inhalerCharacteristic!.write(commandBytes);
      
      print('AT Command sent: $command');
    } catch (e) {
      throw Exception('Failed to send AT command: $e');
    }
  }

  /// Connects to a discovered BT05 device
  /// 
  /// This private method:
  /// 1. Establishes connection to the BT05 device
  /// 2. Discovers services and characteristics
  /// 3. Sets up notifications for data reception
  /// 4. Updates connection state for the app
  Future<void> _connectToBT05Device(fbp.BluetoothDevice device) async {
    try {
      // Attempt to connect to the device
      await device.connect();
      
      // Update connection state
      _connectedDevice = device;
      _isConnected = true;
      _isConnectedStreamController.add(true);
      
      // Notify the user about successful connection
      _notificationService.showMessage(
        'Connected',
        'Connected to BT05 (${device.remoteId})'
      );
      
      // Discover services offered by the device
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      // Find the specific service and characteristic for BT05 communication
      for (fbp.BluetoothService service in services) {
        // Check if this service matches our target BT05 service UUID
        if (service.uuid.str.toUpperCase().contains(bt05ServiceUuid.toUpperCase().replaceAll('-', ''))) {
          for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
            // Check if this characteristic matches our target BT05 characteristic UUID
            if (characteristic.uuid.str.toUpperCase().contains(bt05CharacteristicUuid.toUpperCase().replaceAll('-', ''))) {
              _inhalerCharacteristic = characteristic;
              
              // Set up notifications from the characteristic
              await characteristic.setNotifyValue(true);
              
              // Listen for incoming data from the BT05
              characteristic.onValueReceived.listen(_onBT05DataReceived);
              
              print('BT05 characteristic setup complete: ${characteristic.uuid}');
              break;
            }
          }
          if (_inhalerCharacteristic != null) break; // Break outer loop if characteristic found
        }
      }
      
      // If we didn't find the specific BT05 characteristic, try to find any writable characteristic
      if (_inhalerCharacteristic == null) {
        for (fbp.BluetoothService service in services) {
          for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
              _inhalerCharacteristic = characteristic;
              
              // Try to set up notifications if supported
              if (characteristic.properties.notify) {
                try {
                  await characteristic.setNotifyValue(true);
                  characteristic.onValueReceived.listen(_onBT05DataReceived);
                } catch (e) {
                  print('Could not set up notifications: $e');
                }
              }
              
              print('Using fallback characteristic: ${characteristic.uuid}');
              break;
            }
          }
          if (_inhalerCharacteristic != null) break;
        }
      }
      
      // Check if we successfully found a usable characteristic
      if (_inhalerCharacteristic == null) {
        _notificationService.showMessage(
          'Device Error',
          'Could not find a suitable characteristic for BT05 communication.'
        );
      } else {
        // Send initial AT command to test communication
        try {
          await sendATCommand('AT');
        } catch (e) {
          print('Initial AT command failed: $e');
        }
      }
    } catch (e) {
      // Handle connection errors
      _isConnected = false;
      _isConnectedStreamController.add(false);
      _notificationService.showMessage(
        'Connection Error',
        'Failed to connect to BT05: $e'
      );
    }
  }

  /// Processes data received from the BT05 device
  /// 
  /// This is called automatically when the BLE characteristic sends a notification
  /// The data format follows the AT command response protocol
  void _onBT05DataReceived(List<int> data) {
    try {
      // Convert bytes to string (BT05 sends text responses)
      String response = utf8.decode(data, allowMalformed: true).trim();
      
      print('BT05 Response: $response');
      
      // Create structured data for the app
      Map<String, dynamic> parsedData = {
        'timestamp': DateTime.now().toIso8601String(),
        'response': response,
        'rawData': data,
        'dataType': 'at_response',
      };
      
      // Check if this is a usage detection response
      if (response.toLowerCase().contains('usage') || 
          response.toLowerCase().contains('trigger') ||
          response.toLowerCase().contains('sensor')) {
        parsedData['usageDetected'] = true;
        _logMedicationUsage(parsedData);
      }
      
      // Broadcast the parsed data to any listeners
      _inhalerDataStreamController.add(parsedData);
    } catch (e) {
      // Handle data parsing errors
      print('Error parsing BT05 data: $e');
    }
  }

  /// Starts scanning for nearby Smart Inhalers
  /// 
  /// The method will:
  /// 1. Check if Bluetooth is enabled
  /// 2. Start scanning with a 30-second timeout
  /// 3. Listen for devices matching the Smart Inhaler name prefix
  /// 4. Automatically connect to the first matching device found
  Future<void> startScan() async {
    // Prevent starting multiple scans simultaneously
    if (_isScanning) return;
    
    try {
      _isScanning = true;
      
      // Check if Bluetooth is enabled on the device
      if (await fbp.FlutterBluePlus.adapterState.first != fbp.BluetoothAdapterState.on) {
        _notificationService.showMessage(
          'Bluetooth is turned off',
          'Please turn on Bluetooth to connect to your inhaler.'
        );
        _isScanning = false;
        return;
      }
      
      // Begin scanning for devices with a 30-second timeout
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
      
      // Listen for scan results and look for matching devices
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (fbp.ScanResult result in results) {
          // Check if the device name matches our inhaler name prefix
          if (result.device.platformName.startsWith(_inhalerNamePrefix)) {
            // Found a matching device, attempt to connect
            _connectToDevice(result.device);
            stopScan(); // Stop scanning once we find a device
            break;
          }
        }
      }, onError: (e) {
        // Handle scan errors
        _isScanning = false;
        _notificationService.showMessage(
          'Scan Error',
          'Error scanning for devices: $e'
        );
      });
    } catch (e) {
      // Handle any exceptions during scan start
      _isScanning = false;
      _notificationService.showMessage(
        'Bluetooth Error',
        'Error starting scan: $e'
      );
    }
  }

  /// Stops an ongoing BLE scan
  /// 
  /// This should be called:
  /// - When a device is found
  /// - When the user cancels scanning
  /// - When navigating away from the connection screen
  Future<void> stopScan() async {
    if (!_isScanning) return;
    
    try {
      // Stop the Bluetooth scan
      await fbp.FlutterBluePlus.stopScan();
      
      // Clean up the scan results subscription
      _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
    } catch (e) {
      // Handle errors during scan stop
      _notificationService.showMessage(
        'Bluetooth Error',
        'Error stopping scan: $e'
      );
    }
  }

  /// Connects to a discovered Smart Inhaler device (legacy method)
  /// 
  /// This private method:
  /// 1. Establishes connection to the device
  /// 2. Discovers services and characteristics
  /// 3. Sets up notifications for inhaler usage data
  /// 4. Updates connection state for the app
  Future<void> _connectToDevice(fbp.BluetoothDevice device) async {
    try {
      // Attempt to connect to the device
      await device.connect();
      
      // Update connection state
      _connectedDevice = device;
      _isConnected = true;
      _isConnectedStreamController.add(true);
      
      // Notify the user about successful connection
      _notificationService.showMessage(
        'Connected',
        'Connected to ${device.platformName}'
      );
      
      // Discover services offered by the device
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      // Find the specific service and characteristic for inhaler data
      for (fbp.BluetoothService service in services) {
        // Check if this service matches our target inhaler service UUID
        if (service.uuid.str.toUpperCase().contains(_inhalerServiceUuid)) {
          for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
            // Check if this characteristic matches our target inhaler characteristic UUID
            if (characteristic.uuid.str.toUpperCase().contains(_inhalerCharacteristicUuid)) {
              _inhalerCharacteristic = characteristic;
              
              // Set up notifications from the characteristic
              await characteristic.setNotifyValue(true);
              
              // Listen for incoming data from the inhaler
              characteristic.onValueReceived.listen(_onInhalerDataReceived);
              
              break;
            }
          }
          if (_inhalerCharacteristic != null) break; // Break outer loop if characteristic found
        }
      }
      
      // Check if we successfully found the required characteristic
      if (_inhalerCharacteristic == null) {
        _notificationService.showMessage(
          'Device Error',
          'Could not find the required inhaler service or characteristic.'
        );
      }
    } catch (e) {
      // Handle connection errors
      _isConnected = false;
      _isConnectedStreamController.add(false);
      _notificationService.showMessage(
        'Connection Error',
        'Failed to connect to ${device.platformName}: $e'
      );
    }
  }

  /// Disconnects from the currently connected inhaler
  /// 
  /// This should be called:
  /// - When manually disconnecting from settings
  /// - When closing the app
  /// - Before connecting to a different device
  Future<void> disconnect() async {
    if (_connectedDevice == null) return;
    
    try {
      // Disconnect from the device
      await _connectedDevice!.disconnect();
      
      // Clean up connection state
      _connectedDevice = null;
      _inhalerCharacteristic = null;
      _isConnected = false;
      _isConnectedStreamController.add(false);
      
      // Notify the user about disconnection
      _notificationService.showMessage(
        'Disconnected',
        'Disconnected from device'
      );
    } catch (e) {
      // Handle disconnection errors
      _notificationService.showMessage(
        'Disconnect Error',
        'Error disconnecting: $e'
      );
    }
  }

  /// Processes data received from the inhaler (legacy method)
  /// 
  /// This is called automatically when the BLE characteristic sends a notification
  /// The raw data format will depend on the specific inhaler device implementation
  /// This method:
  /// 1. Parses the raw BLE data
  /// 2. Creates a structured map of the inhaler usage data
  /// 3. Broadcasts the data to listeners
  /// 4. Logs the medication usage
  void _onInhalerDataReceived(List<int> data) {
    try {
      // This is a placeholder for actual data parsing
      // The exact parsing logic will depend on the inhaler's protocol
      // Replace with actual parsing logic based on device documentation
      Map<String, dynamic> parsedData = {
        'timestamp': DateTime.now().toIso8601String(),
        'usageDetected': true,  // This would be determined from actual data
        'batteryLevel': data.isNotEmpty ? data[0] : 0,  // Example parsing
        'rawData': data,  // Store raw data for debugging
      };
      
      // Broadcast the parsed data to any listeners
      _inhalerDataStreamController.add(parsedData);
      
      // Log medication usage in the system
      _logMedicationUsage(parsedData);
    } catch (e) {
      // Handle data parsing errors
      print('Error parsing inhaler data: $e');
    }
  }

  /// Logs medication usage when inhaler usage is detected
  /// 
  /// This method:
  /// 1. Verifies that usage was detected
  /// 2. Logs the usage in the medication tracking system
  /// 3. Shows a notification to the user
  /// 
  /// Would eventually connect to a medication tracking service
  void _logMedicationUsage(Map<String, dynamic> data) {
    // Check if usage was detected in the data
    if (data['usageDetected'] == true) {
      // This would connect to your medication tracking system
      // TODO: Implement actual medication usage logging with persistent storage
      
      // For now, just show a notification
      _notificationService.showMessage(
        'Inhaler Used',
        'Your inhaler usage has been logged.'
      );
    }
  }

  /// Check if the device is currently connected
  bool get isConnected => _isConnected;
  
  /// Check if a scan is currently in progress
  bool get isScanning => _isScanning;
  
  /// Get the currently connected device (if any)
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Clean up resources used by this service
  /// 
  /// Should be called when the app is closing or the service is no longer needed
  void dispose() {
    // Cancel any ongoing scan
    _scanSubscription?.cancel();
    
    // Disconnect from the device
    disconnect();
    
    // Close stream controllers
    _isConnectedStreamController.close();
    _inhalerDataStreamController.close();
  }
} 