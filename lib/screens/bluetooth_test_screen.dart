import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../services/bluetooth_service.dart';

class BluetoothTestScreen extends StatefulWidget {
  const BluetoothTestScreen({super.key});

  @override
  State<BluetoothTestScreen> createState() => _BluetoothTestScreenState();
}

class _BluetoothTestScreenState extends State<BluetoothTestScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final TextEditingController _commandController = TextEditingController();
  final List<String> _logMessages = [];
  final ScrollController _scrollController = ScrollController();
  
  // BT05 Specific Configuration
  static const String bt05MacAddress = "04:A3:16:A8:94:D2";
  static const String bt05UUID = "0000ffe1-0000-1000-8000-00805f9b34fb";
  
  bool _isConnected = false;
  bool _isScanning = false;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBluetoothListeners();
    _checkBluetoothSupport();
  }

  void _initializeBluetoothListeners() {
    // Listen to connection status changes
    _connectionSubscription = _bluetoothService.isConnectedStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
        _addLogMessage(connected ? "✅ Connected to BT05" : "❌ Disconnected from BT05");
      }
    });

    // Listen to incoming data from BT05
    _dataSubscription = _bluetoothService.inhalerDataStream.listen((data) {
      if (mounted) {
        _addLogMessage("📥 Received: ${data.toString()}");
      }
    });
  }

  void _addLogMessage(String message) {
    setState(() {
      _logMessages.add("${DateTime.now().toString().substring(11, 19)} - $message");
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
    });
    _addLogMessage("🔍 Starting scan for BT05 device...");
    
    try {
      await _bluetoothService.startScanForBT05();
    } catch (e) {
      _addLogMessage("❌ Scan error: $e");
    }
    
    // Stop scanning after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        if (!_isConnected) {
          _addLogMessage("⏰ Scan timeout - BT05 not found");
        }
      }
    });
  }

  Future<void> _connectToBT05() async {
    _addLogMessage("🔗 Attempting direct connection to BT05...");
    try {
      await _bluetoothService.connectToBT05Direct();
    } catch (e) {
      _addLogMessage("❌ Connection error: $e");
    }
  }

  Future<void> _disconnect() async {
    _addLogMessage("🔌 Disconnecting from BT05...");
    await _bluetoothService.disconnect();
  }

  Future<void> _sendATCommand(String command) async {
    if (!_isConnected) {
      _addLogMessage("❌ Not connected to BT05");
      return;
    }

    _addLogMessage("📤 Sending: $command");
    try {
      await _bluetoothService.sendATCommand(command);
    } catch (e) {
      _addLogMessage("❌ Send error: $e");
    }
  }

  Future<void> _sendPredefinedCommand(String command) async {
    await _sendATCommand(command);
    _commandController.clear();
  }

  Future<void> _testBT05Configuration() async {
    _addLogMessage("🧪 Starting BT05 configuration test...");
    
    const commands = [
      "AT",
      "AT+BAUD4",
      "AT+NOTI1", 
      "AT+ROLE0"
    ];

    for (String cmd in commands) {
      await _sendATCommand(cmd);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    _addLogMessage("✅ Configuration test complete");
  }

  void _clearLog() {
    setState(() {
      _logMessages.clear();
    });
  }

  Future<void> _checkBluetoothSupport() async {
    _addLogMessage("�� Checking Bluetooth support...");
    
    try {
      // Check if Bluetooth is supported
      bool isSupported = await fbp.FlutterBluePlus.isSupported;
      if (!isSupported) {
        _addLogMessage("❌ Bluetooth not supported on this device/emulator");
        _addLogMessage("💡 Try running on a physical Android device");
        return;
      }
      
      // Check adapter state
      fbp.BluetoothAdapterState adapterState = await fbp.FlutterBluePlus.adapterState.first;
      switch (adapterState) {
        case fbp.BluetoothAdapterState.unknown:
          _addLogMessage("❓ Bluetooth adapter state unknown");
          break;
        case fbp.BluetoothAdapterState.unavailable:
          _addLogMessage("❌ Bluetooth adapter unavailable (common in emulators)");
          _addLogMessage("💡 Use a physical Android device for real BT05 testing");
          break;
        case fbp.BluetoothAdapterState.unauthorized:
          _addLogMessage("🔒 Bluetooth permission denied");
          break;
        case fbp.BluetoothAdapterState.turningOn:
          _addLogMessage("🔄 Bluetooth turning on...");
          break;
        case fbp.BluetoothAdapterState.on:
          _addLogMessage("✅ Bluetooth adapter is ON and ready");
          _addLogMessage("🔍 Ready to scan for BT05 (${bt05MacAddress})");
          break;
        case fbp.BluetoothAdapterState.turningOff:
          _addLogMessage("🔄 Bluetooth turning off...");
          break;
        case fbp.BluetoothAdapterState.off:
          _addLogMessage("📱 Bluetooth is OFF - please enable it");
          break;
      }
      
      // Check for physical vs emulator
      _addLogMessage("📱 Environment: ${await _getDeviceType()}");
      
    } catch (e) {
      _addLogMessage("❌ Error checking Bluetooth: $e");
    }
  }

  Future<String> _getDeviceType() async {
    try {
      // This is a simple heuristic - emulators often have "sdk" in their model
      return "Checking device type...";
    } catch (e) {
      return "Unknown device";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BT05 Bluetooth Test'),
        backgroundColor: _isConnected ? Colors.green : Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLog,
            tooltip: 'Clear Log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _isConnected ? Colors.green : Colors.blue,
                width: 2.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      color: _isConnected ? Colors.green : Colors.blue,
                      size: 32.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      _isConnected ? 'Connected to BT05' : 'Not Connected',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: _isConnected ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  'MAC: $bt05MacAddress',
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
                Text(
                  'UUID: $bt05UUID',
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Control Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan for BT05'),
                ),
                ElevatedButton.icon(
                  onPressed: _isConnected ? null : _connectToBT05,
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('Direct Connect'),
                ),
                ElevatedButton.icon(
                  onPressed: _isConnected ? _disconnect : null,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: _isConnected ? _testBT05Configuration : null,
                  icon: const Icon(Icons.settings),
                  label: const Text('Test Config'),
                ),
              ],
            ),
          ),

          // AT Command Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send AT Command:',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commandController,
                        decoration: const InputDecoration(
                          hintText: 'Enter AT command (e.g., AT)',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _isConnected ? (value) {
                          if (value.isNotEmpty) {
                            _sendATCommand(value);
                            _commandController.clear();
                          }
                        } : null,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: _isConnected && _commandController.text.isNotEmpty 
                        ? () => _sendATCommand(_commandController.text)
                        : null,
                      child: const Text('Send'),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                // Quick AT Command Buttons
                Wrap(
                  spacing: 8.0,
                  children: [
                    _QuickCommandButton(
                      label: 'AT',
                      command: 'AT',
                      onPressed: _isConnected ? _sendPredefinedCommand : null,
                    ),
                    _QuickCommandButton(
                      label: 'BAUD4',
                      command: 'AT+BAUD4',
                      onPressed: _isConnected ? _sendPredefinedCommand : null,
                    ),
                    _QuickCommandButton(
                      label: 'NOTI1',
                      command: 'AT+NOTI1',
                      onPressed: _isConnected ? _sendPredefinedCommand : null,
                    ),
                    _QuickCommandButton(
                      label: 'ROLE0',
                      command: 'AT+ROLE0',
                      onPressed: _isConnected ? _sendPredefinedCommand : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Log Display
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug Log:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _logMessages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _logMessages[index],
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                              fontSize: 12.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _QuickCommandButton extends StatelessWidget {
  final String label;
  final String command;
  final void Function(String)? onPressed;

  const _QuickCommandButton({
    required this.label,
    required this.command,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed != null ? () => onPressed!(command) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.0),
      ),
    );
  }
} 