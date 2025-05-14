import 'dart:async';
import 'dart:io'; // For Platform.isAndroid etc.
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // We'll add this to pubspec.yaml next

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({Key? key}) : super(key: key);

  @override
  State<BleScannerPage> createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to scan state changes
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          _isScanning = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _stopScan();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissionsAndStartScan() async {
    bool permissionsGranted = await _handlePermissions();
    if (!permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions not granted. Cannot scan.')),
      );
      return;
    }

    if (FlutterBluePlus.adapterState == BluetoothAdapterState.on) {
      _startScan();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth is off. Please turn it on.')),
      );
      // Optionally, listen for adapter state changes to start scan when it's on
      // FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      //   if (state == BluetoothAdapterState.on) {
      //     _startScan();
      //   }
      // });
    }
  }

  Future<bool> _handlePermissions() async {
    Map<Permission, PermissionStatus> statuses = {};
    if (Platform.isAndroid) {
      // For Android 12 (API 31) and above
      // As of flutter_blue_plus 1.15.0, it seems to handle some of this internally
      // but explicit requests are safer.
      statuses.addAll(await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // ACCESS_FINE_LOCATION
      ].request());
    } else if (Platform.isIOS) {
      // For iOS (permissions are typically handled by Info.plist descriptions)
      // but explicit request can be good for location if needed.
      // statuses.addAll(await [Permission.bluetooth, Permission.locationWhenInUse].request());
      // Note: Permission.bluetooth for iOS with permission_handler might not be needed if Info.plist is set up.
      // flutter_blue_plus generally handles iOS BT permission prompt based on Info.plist.
      // Location permission might still need explicit request if scanning requires it.
      return true; // Assuming Info.plist handles BT, location might be separate
    }

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
        debugPrint("Permission ${permission.toString()} not granted: $status");
      }
    });
    return allGranted;
  }

  void _startScan() {
    if (_isScanning) return;

    _scanResults.clear(); // Clear previous results
    
    // Listen to scan results
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        // Filter out devices with no name for cleaner list, or devices already found
        // Using a Set to keep track of unique device IDs to avoid duplicates in the list
        final newResults = results.where((r) => r.device.platformName.isNotEmpty).toList();
        final existingIds = _scanResults.map((r) => r.device.remoteId.toString()).toSet();
        
        setState(() {
          for (var result in newResults) {
            if (!existingIds.contains(result.device.remoteId.toString())) {
              _scanResults.add(result);
            }
          }
          // Sort by RSSI (signal strength) if desired
          // _scanResults.sort((a, b) => b.rssi.compareTo(a.rssi));
        });
      }
    }, onError: (e) {
      debugPrint("Scan Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan Error: $e')),
      );
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
     if (mounted) {
        setState(() {}); // Update UI to reflect scanning state if not already handled by listener
     }
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
  }

  Widget _buildDeviceList() {
    if (_scanResults.isEmpty) {
      return Center(
        child: _isScanning 
            ? const CircularProgressIndicator() 
            : const Text("No devices found. Tap 'Scan' to start."),
      );
    }
    return ListView.builder(
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        return ListTile(
          title: Text(result.device.platformName.isNotEmpty ? result.device.platformName : "Unknown Device"),
          subtitle: Text(result.device.remoteId.toString()), // This is the MAC address
          trailing: Text("${result.rssi} dBm"),
          onTap: () {
            _stopScan(); // Stop scanning before attempting to connect
            // TODO: Navigate to device detail page or connect directly
            // For now, just print MAC address
            print("Tapped on device: ${result.device.remoteId.toString()}"); 
            // This is where you'd use result.device.remoteId.toString() (the MAC address)
            // and the characteristic UUID "0000ffe1-0000-1000-8000-00805f9b34fb"
            // to connect and subscribe for notifications.
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped: ${result.device.platformName} (${result.device.remoteId})')),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Scanner"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isScanning ? _stopScan : _requestPermissionsAndStartScan,
              child: Text(_isScanning ? "Stop Scan" : "Start Scan"),
            ),
          ),
          Expanded(child: _buildDeviceList()),
        ],
      ),
    );
  }
}

// TODO: 
// 1. Add 'permission_handler' to pubspec.yaml:
//    dependencies:
//      flutter:
//        sdk: flutter
//      flutter_blue_plus: ^1.15.1
//      permission_handler: ^11.0.0 # Or latest version
//    Then run `flutter pub get`
//
// 2. Ensure you have a way to navigate to this BleScannerPage from your main app flow
//    (e.g., from a button in your home page or AppBar).
//
// 3. Android min SDK version: flutter_blue_plus might require a minimum SDK version.
//    Check app/build.gradle and ensure minSdkVersion is appropriate (e.g., 21 or higher).
//    FlutterBluePlus.setLogLevel(LogLevel.verbose, color:true); // for verbose logging from fbp
//
// 4. Test on a physical Android device. Emulators often have limited/no Bluetooth support. 