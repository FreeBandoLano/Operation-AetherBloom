import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/medication.dart';
import 'notification_service.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._();
  factory BluetoothService() => _instance;

  BluetoothService._();

  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Inhaler device details
  final String _inhalerNamePrefix = 'SmartInhaler';
  final String _inhalerServiceUuid = '1809'; // Health Thermometer service as example, replace with actual UUID
  final String _inhalerCharacteristicUuid = '2A1C'; // Temperature Measurement characteristic as example, replace with actual UUID
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _inhalerCharacteristic;

  bool _isScanning = false;
  bool _isConnected = false;
  
  // Streams to expose state
  final _isConnectedStreamController = StreamController<bool>.broadcast();
  Stream<bool> get isConnectedStream => _isConnectedStreamController.stream;
  
  final _inhalerDataStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get inhalerDataStream => _inhalerDataStreamController.stream;

  /// Start scanning for smart inhalers
  Future<void> startScan() async {
    if (_isScanning) return;
    
    try {
      _isScanning = true;
      
      // Check if Bluetooth is on
      if (await _flutterBlue.isOn == false) {
        _notificationService.showMessage(
          'Bluetooth is turned off',
          'Please turn on Bluetooth to connect to your inhaler.'
        );
        _isScanning = false;
        return;
      }
      
      // Start scanning
      await _flutterBlue.startScan(timeout: Duration(seconds: 30));
      
      _scanSubscription = _flutterBlue.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.name.startsWith(_inhalerNamePrefix)) {
            _connectToDevice(result.device);
            stopScan();
            break;
          }
        }
      }, onError: (e) {
        _isScanning = false;
        _notificationService.showMessage(
          'Scan Error',
          'Error scanning for devices: $e'
        );
      });
    } catch (e) {
      _isScanning = false;
      _notificationService.showMessage(
        'Bluetooth Error',
        'Error starting scan: $e'
      );
    }
  }

  /// Stop scanning for devices
  Future<void> stopScan() async {
    if (!_isScanning) return;
    
    try {
      await _flutterBlue.stopScan();
      _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
    } catch (e) {
      _notificationService.showMessage(
        'Bluetooth Error',
        'Error stopping scan: $e'
      );
    }
  }

  /// Connect to the smart inhaler device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      _isConnected = true;
      _isConnectedStreamController.add(true);
      
      _notificationService.showMessage(
        'Connected',
        'Connected to ${device.name}'
      );
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Find the inhaler service and characteristic
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase().contains(_inhalerServiceUuid)) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase().contains(_inhalerCharacteristicUuid)) {
              _inhalerCharacteristic = characteristic;
              
              // Set up notifications
              await characteristic.setNotifyValue(true);
              characteristic.value.listen(_onInhalerDataReceived);
              
              break;
            }
          }
        }
      }
      
      if (_inhalerCharacteristic == null) {
        _notificationService.showMessage(
          'Device Error',
          'Could not find the required inhaler service or characteristic.'
        );
      }
    } catch (e) {
      _isConnected = false;
      _isConnectedStreamController.add(false);
      _notificationService.showMessage(
        'Connection Error',
        'Failed to connect to ${device.name}: $e'
      );
    }
  }

  /// Disconnect from the device
  Future<void> disconnect() async {
    if (_connectedDevice == null) return;
    
    try {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _inhalerCharacteristic = null;
      _isConnected = false;
      _isConnectedStreamController.add(false);
      
      _notificationService.showMessage(
        'Disconnected',
        'Disconnected from device'
      );
    } catch (e) {
      _notificationService.showMessage(
        'Disconnect Error',
        'Error disconnecting: $e'
      );
    }
  }

  /// Process data received from the inhaler
  void _onInhalerDataReceived(List<int> data) {
    try {
      // This is a placeholder for actual data parsing
      // The exact parsing will depend on the inhaler's protocol
      Map<String, dynamic> parsedData = {
        'timestamp': DateTime.now().toIso8601String(),
        'usageDetected': true,
        'batteryLevel': data.isNotEmpty ? data[0] : 0,
        'rawData': data,
      };
      
      // Broadcast the data
      _inhalerDataStreamController.add(parsedData);
      
      // Log medication usage
      _logMedicationUsage(parsedData);
    } catch (e) {
      print('Error parsing inhaler data: $e');
    }
  }

  /// Log medication usage when inhaler is used
  void _logMedicationUsage(Map<String, dynamic> data) {
    // This would connect to your medication tracking system
    // For now, just show a notification
    if (data['usageDetected'] == true) {
      _notificationService.showMessage(
        'Inhaler Used',
        'Your inhaler usage has been logged.'
      );
    }
  }

  /// Check if the device is connected
  bool get isConnected => _isConnected;
  
  /// Check if scanning is in progress
  bool get isScanning => _isScanning;
  
  /// Get the connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Clean up resources
  void dispose() {
    _scanSubscription?.cancel();
    disconnect();
    _isConnectedStreamController.close();
    _inhalerDataStreamController.close();
  }
} 