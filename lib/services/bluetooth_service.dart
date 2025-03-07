import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/medication.dart';
import 'notification_service.dart';

/// BluetoothService manages all interactions with the BLE Smart Inhaler
/// 
/// This service is responsible for:
/// - Scanning for nearby BLE devices
/// - Connecting to Smart Inhalers
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
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;  // BLE plugin
  final NotificationService _notificationService = NotificationService();  // For user alerts
  
  // Configuration for Smart Inhaler device identification
  /// Name prefix used to identify Smart Inhalers during scanning
  /// Change this to match the actual device naming convention
  final String _inhalerNamePrefix = 'SmartInhaler';
  
  /// Service UUID for the inhaler functionality
  /// This is a placeholder - replace with actual UUID from device documentation
  final String _inhalerServiceUuid = '1809';  // Health Thermometer service example
  
  /// Characteristic UUID for reading inhaler usage data
  /// This is a placeholder - replace with actual UUID from device documentation
  final String _inhalerCharacteristicUuid = '2A1C';  // Temperature Measurement characteristic example
  
  // State tracking variables
  StreamSubscription<List<ScanResult>>? _scanSubscription;  // Manages the scan result stream
  BluetoothDevice? _connectedDevice;  // Currently connected inhaler device
  BluetoothCharacteristic? _inhalerCharacteristic;  // Characteristic for inhaler usage data
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
      if (await _flutterBlue.isOn == false) {
        _notificationService.showMessage(
          'Bluetooth is turned off',
          'Please turn on Bluetooth to connect to your inhaler.'
        );
        _isScanning = false;
        return;
      }
      
      // Begin scanning for devices with a 30-second timeout
      await _flutterBlue.startScan(timeout: Duration(seconds: 30));
      
      // Listen for scan results and look for matching devices
      _scanSubscription = _flutterBlue.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Check if the device name matches our inhaler name prefix
          if (result.device.name.startsWith(_inhalerNamePrefix)) {
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
      await _flutterBlue.stopScan();
      
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

  /// Connects to a discovered Smart Inhaler device
  /// 
  /// This private method:
  /// 1. Establishes connection to the device
  /// 2. Discovers services and characteristics
  /// 3. Sets up notifications for inhaler usage data
  /// 4. Updates connection state for the app
  Future<void> _connectToDevice(BluetoothDevice device) async {
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
        'Connected to ${device.name}'
      );
      
      // Discover services offered by the device
      List<BluetoothService> services = await device.discoverServices();
      
      // Find the specific service and characteristic for inhaler data
      for (BluetoothService service in services) {
        // Check if this service matches our target inhaler service UUID
        if (service.uuid.toString().toUpperCase().contains(_inhalerServiceUuid)) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            // Check if this characteristic matches our target inhaler characteristic UUID
            if (characteristic.uuid.toString().toUpperCase().contains(_inhalerCharacteristicUuid)) {
              _inhalerCharacteristic = characteristic;
              
              // Set up notifications from the characteristic
              await characteristic.setNotifyValue(true);
              
              // Listen for incoming data from the inhaler
              characteristic.value.listen(_onInhalerDataReceived);
              
              break;
            }
          }
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
        'Failed to connect to ${device.name}: $e'
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

  /// Processes data received from the inhaler
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
  BluetoothDevice? get connectedDevice => _connectedDevice;

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