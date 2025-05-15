import 'dart:async';
import 'dart:io'; // For Platform.isAndroid etc.
import 'package:flutter/material.dart';
// Import flutter_blue_plus_windows, which should re-export necessary symbols
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:permission_handler/permission_handler.dart'; // Keep this import direct

// UUIDs for the BLE service and characteristic
// Standard Serial Port Service (FFE0) and Characteristic (FFE1) for many BLE modules
final Guid TARGET_SERVICE_UUID = Guid("0000ffe0-0000-1000-8000-00805f9b34fb");
final Guid NOTIFY_CHARACTERISTIC_UUID = Guid("0000ffe1-0000-1000-8000-00805f9b34fb");

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({Key? key}) : super(key: key);

  @override
  State<BleScannerPage> createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  // Types should now be directly available due to 'show' in import
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  BluetoothDevice? _connectingDevice;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  StreamSubscription<List<int>>? _valueSubscription;
  final List<String> _receivedData = [];

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color:true); // for verbose logging from fbp
    // Listen to adapter state changes
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (mounted) {
        setState(() {
          _adapterState = state;
        });
        print('[FBP] Adapter State Changed: $state');
      }
    });

    // Listen to scan state changes
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          _isScanning = state;
        });
      }
    });

    // Listen to scan results
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        // Filter out devices with empty names, customize as needed
        _scanResults = results.where((result) => result.device.platformName.isNotEmpty).toList();
        setState(() {});
      }
    }, onError: (e) {
      print('[FBP] Error listening to scan results: $e');
      _showErrorDialog('Error listening to scan results: $e');
    });

    // Initial permission request
    _requestPermissions();
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _valueSubscription?.cancel();
    if (_connectedDevice != null && _connectionState == BluetoothConnectionState.connected) {
      _connectedDevice!.disconnect();
    }
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    print('[FBP] Requesting Bluetooth permissions...');
    // Ensure Permission type is used directly from the imported package
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,       // These should be resolved by the import
      Permission.bluetoothConnect,
      // Permission.locationWhenInUse, // Optional for Android SDK 31+
    ].request(); // .request() is an extension method on List<Permission>

    statuses.forEach((permission, status) {
      print('[FBP] Permission ${permission.toString()} status: $status');
    });

    if (statuses[Permission.bluetoothScan]!.isDenied ||
        statuses[Permission.bluetoothConnect]!.isDenied) {
      print('[FBP] Bluetooth permissions denied.');
      _showErrorDialog('Bluetooth permissions are required to scan for devices.');
    } else {
      print('[FBP] Bluetooth permissions granted.');
    }
  }

  Future<void> _startScan() async {
    // First, ensure permissions are granted.
    // Although called in initState, good to have a check before manual scan start.
    await _requestPermissions(); 

    print('[FBP] Current Adapter State before scan: $_adapterState');
    if (_adapterState != BluetoothAdapterState.on) {
      print('[FBP] Bluetooth is off. Cannot start scan.');
      _showErrorDialog('Bluetooth is turned off. Please turn it on to scan.');
      return;
    }

    if (_isScanning) {
      print('[FBP] Scan already in progress.');
      return;
    }

    try {
      print('[FBP] Starting scan...');
      // Clear previous results
      setState(() {
        _scanResults = [];
      });
      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      print('[FBP] Scan started successfully.');
    } catch (e) {
      print('[FBP] Error starting scan: $e');
      _showErrorDialog('Error starting scan: $e');
    }
  }

  void _stopScan() {
    print('[FBP] Stopping scan...');
    try {
      FlutterBluePlus.stopScan();
      print('[FBP] Scan stopped successfully.');
    } catch (e) {
      print('[FBP] Error stopping scan: $e');
      _showErrorDialog('Error stopping scan: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildScanButton() {
    return ElevatedButton(
      onPressed: _isScanning ? _stopScan : _startScan,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isScanning ? Colors.red : Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      child: Text(
        _isScanning ? 'Stop Scan' : 'Start Scan',
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
    }
    print('[FBP] Connecting to ${device.remoteId}...');
    if (mounted) {
      setState(() {
        _connectingDevice = device;
        _connectionState = BluetoothConnectionState.connecting;
        _receivedData.clear(); // Clear previous data on new connection attempt
      });
    }

    // Cancel any existing connection subscription
    await _connectionStateSubscription?.cancel();

    _connectionStateSubscription = device.connectionState.listen((BluetoothConnectionState state) async {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
        print('[FBP] Device ${device.remoteId} connection state: $state');
        if (state == BluetoothConnectionState.connected) {
          setState(() {
            _connectedDevice = device;
            _connectingDevice = null; // No longer attempting to connect to this one
          });
          print('[FBP] Connected to ${device.remoteId}. Discovering services...');
          List<BluetoothService> services = await device.discoverServices();
          print('[FBP] Discovered ${services.length} services for ${device.remoteId}.');
          // After discovering services, attempt to subscribe to the characteristic
          _subscribeToCharacteristic(device);
        } else if (state == BluetoothConnectionState.disconnected) {
          print('[FBP] Disconnected from ${device.remoteId}.');
          setState(() {
            if (_connectedDevice?.remoteId == device.remoteId) {
              _connectedDevice = null; // Clear connected device if this was the one
            }
            if (_connectingDevice?.remoteId == device.remoteId) {
              _connectingDevice = null; // Clear connecting device if this was the one
            }
            _receivedData.clear(); // Clear data when disconnected
          });
        }
      }
    }, onError: (dynamic error) {
      print('[FBP] Connection state error: $error');
      if (mounted) {
        setState(() {
          _showErrorDialog('Connection error: $error');
          if (_connectingDevice?.remoteId == device.remoteId) _connectingDevice = null;
          if (_connectedDevice?.remoteId == device.remoteId) _connectedDevice = null;
           _connectionState = BluetoothConnectionState.disconnected;
        });
      }
    });

    try {
      await device.connect(timeout: const Duration(seconds: 15));
    } catch (e) {
      print('[FBP] Error connecting to device ${device.remoteId}: $e');
      if (mounted) {
        _showErrorDialog('Failed to connect: ${e.toString()}');
        setState(() {
          if (_connectingDevice?.remoteId == device.remoteId) _connectingDevice = null;
          _connectionState = BluetoothConnectionState.disconnected;
        });
      }
    }
  }

  Future<void> _subscribeToCharacteristic(BluetoothDevice device) async {
    print('[FBP] Attempting to subscribe to characteristic for ${device.remoteId}...');
    await _valueSubscription?.cancel(); // Cancel any previous subscription

    List<BluetoothService> services = await device.discoverServices(); // Re-discover or use cached
    BluetoothService? targetService;
    for (BluetoothService service in services) {
      if (service.uuid == TARGET_SERVICE_UUID) {
        targetService = service;
        break;
      }
    }

    if (targetService == null) {
      print('[FBP] Target service $TARGET_SERVICE_UUID not found on ${device.remoteId}.');
      _showErrorDialog('Required BLE service not found.');
      return;
    }

    print('[FBP] Found target service: ${targetService.uuid}');
    print('[FBP] Characteristics in target service:');
    for (BluetoothCharacteristic char in targetService.characteristics) {
      print('  [FBP] Char UUID: ${char.uuid}, Properties: read=${char.properties.read}, write=${char.properties.write}, notify=${char.properties.notify}, indicate=${char.properties.indicate}');
    }

    BluetoothCharacteristic? notifyCharacteristic;
    for (BluetoothCharacteristic char in targetService.characteristics) {
      if (char.uuid == NOTIFY_CHARACTERISTIC_UUID) {
        notifyCharacteristic = char;
        break;
      }
    }

    if (notifyCharacteristic == null) {
      print('[FBP] Notify characteristic $NOTIFY_CHARACTERISTIC_UUID not found in service $TARGET_SERVICE_UUID.');
      _showErrorDialog('Required BLE characteristic not found.');
      return;
    }

    if (!notifyCharacteristic.properties.notify && !notifyCharacteristic.properties.indicate) {
      print('[FBP] Characteristic $NOTIFY_CHARACTERISTIC_UUID does not support notifications or indications.');
      _showErrorDialog('Characteristic does not support notifications.');
      return;
    }

    try {
      await notifyCharacteristic.setNotifyValue(true);
      print('[FBP] Subscribed to ${notifyCharacteristic.uuid} successfully.');

      _valueSubscription = notifyCharacteristic.onValueReceived.listen((List<int> value) {
        // Using onValueReceived for notifications/indications
        final String receivedString = String.fromCharCodes(value).trim();
        print('[FBP] Received data: $value -> ASCII: $receivedString');
        if (mounted) {
          setState(() {
            _receivedData.add(receivedString);
            // Keep only the last few messages, e.g., 5, to prevent UI overflow
            if (_receivedData.length > 5) {
              _receivedData.removeAt(0);
            }
          });
        }
      }, onError: (dynamic error) {
        print('[FBP] Error receiving characteristic value: $error');
        _showErrorDialog('Error receiving data: $error');
      });
    } catch (e) {
      print('[FBP] Error subscribing to characteristic ${notifyCharacteristic.uuid}: $e');
      _showErrorDialog('Failed to subscribe: ${e.toString()}');
    }
  }

  Widget _buildDeviceList() {
    if (!_isScanning && _scanResults.isEmpty && _connectedDevice == null && _connectingDevice == null) {
      return const Center(child: Text('No devices found. Press "Start Scan".'));
    }
    if (_isScanning && _scanResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Scanning for devices...'),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            title: Text(result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device'),
            subtitle: Text(result.device.remoteId.toString()),
            trailing: Text('${result.rssi} dBm'),
            onTap: () {
              _connectToDevice(result.device);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanner'),
        actions: const [
          // Optional: Add a button to manually request permissions if needed
          // IconButton(icon: Icon(Icons.shield_outlined), onPressed: _requestPermissions)
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                 Text('Adapter State: ${_adapterState.toString().split('.').last.toUpperCase()}'),
                const SizedBox(height: 10),
                _buildScanButton(),
                const SizedBox(height: 10),
                if (_connectingDevice != null)
                  Text('Connecting to: ${_connectingDevice!.platformName.isNotEmpty ? _connectingDevice!.platformName : _connectingDevice!.remoteId}')
                else if (_connectedDevice != null)
                  Text('Connected to: ${_connectedDevice!.platformName.isNotEmpty ? _connectedDevice!.platformName : _connectedDevice!.remoteId}')
                else
                  const Text('Not connected to any device.'),
                Text('Connection State: ${_connectionState.toString().split('.').last.toUpperCase()}'),
              ],
            ),
          ),
          Expanded(child: _buildDeviceList()),
          // Placeholder for displaying received data
          if (_receivedData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Received Data: ${_receivedData.last}'),
            ),
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
//
// 4. Test on a physical Android device. Emulators often have limited/no Bluetooth support. 