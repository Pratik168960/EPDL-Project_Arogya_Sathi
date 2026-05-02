import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════
//  PAIR HARDWARE SCREEN
//  BLE provisioning: sends SSID|PASSWORD|UID
// ═══════════════════════════════════════════════

// BLE UUIDs — must match the ESP32 firmware
const String _serviceUUID    = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String _scanCharUUID   = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String _credsCharUUID  = "1c95d5e3-d8f7-413a-bf3d-7a2e5d7be87e";
const String _statusCharUUID = "d8a0d2a5-4c5f-4e7e-b5a7-3f1d9e8c6b4a";

class WifiProvisionScreen extends StatefulWidget {
  const WifiProvisionScreen({super.key});

  @override
  State<WifiProvisionScreen> createState() => _WifiProvisionScreenState();
}

enum _ProvisionStep { scanning, connecting, wifiList, sendingCreds, done, error }

class _WifiProvisionScreenState extends State<WifiProvisionScreen> with TickerProviderStateMixin {
  _ProvisionStep _step = _ProvisionStep.scanning;
  String _statusMessage = 'Scanning for ArogyaSathi Dispenser...';
  String _errorMessage = '';

  // BLE state
  BluetoothDevice? _device;
  BluetoothCharacteristic? _scanChar;
  BluetoothCharacteristic? _credsChar;
  BluetoothCharacteristic? _statusChar;
  StreamSubscription? _scanSub;
  StreamSubscription? _statusSub;

  // WiFi networks from ESP32
  List<_WifiNetwork> _networks = [];
  _WifiNetwork? _selectedNetwork;
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSending = false;

  // Animation
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startBLEScan();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanSub?.cancel();
    _statusSub?.cancel();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  //  STEP 1: Scan for BLE devices
  // ═══════════════════════════════════════════════
  Future<void> _startBLEScan() async {
    setState(() {
      _step = _ProvisionStep.scanning;
      _statusMessage = 'Scanning for ArogyaSathi Dispenser...';
    });

    // Check BLE adapter
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      setState(() {
        _step = _ProvisionStep.error;
        _errorMessage = 'Please enable Bluetooth on your phone.';
      });
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName;
        if (name.startsWith('ArogyaSathi')) {
          FlutterBluePlus.stopScan();
          _scanSub?.cancel();
          _connectToDevice(r.device);
          return;
        }
      }
    });

    // Start scan with timeout
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      withServices: [Guid(_serviceUUID)],
    );

    // If scan ends without finding device
    await Future.delayed(const Duration(seconds: 16));
    if (_step == _ProvisionStep.scanning && mounted) {
      setState(() {
        _step = _ProvisionStep.error;
        _errorMessage = 'Could not find ArogyaSathi Dispenser.\n\n'
            'Make sure the ESP32 is powered on and in Setup Mode '
            '(red LED should be blinking).';
      });
    }
  }

  // ═══════════════════════════════════════════════
  //  STEP 2: Connect to ESP32
  // ═══════════════════════════════════════════════
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _step = _ProvisionStep.connecting;
      _statusMessage = 'Connecting to ${device.platformName}...';
      _device = device;
    });

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();

      // Find our provisioning service
      BluetoothService? provService;
      for (final s in services) {
        if (s.uuid == Guid(_serviceUUID)) {
          provService = s;
          break;
        }
      }

      if (provService == null) {
        setState(() {
          _step = _ProvisionStep.error;
          _errorMessage = 'Connected but provisioning service not found.\n'
              'Make sure the ESP32 firmware is updated.';
        });
        return;
      }

      // Get characteristics
      for (final c in provService.characteristics) {
        if (c.uuid == Guid(_scanCharUUID)) _scanChar = c;
        if (c.uuid == Guid(_credsCharUUID)) _credsChar = c;
        if (c.uuid == Guid(_statusCharUUID)) _statusChar = c;
      }

      if (_scanChar == null || _credsChar == null || _statusChar == null) {
        setState(() {
          _step = _ProvisionStep.error;
          _errorMessage = 'BLE characteristics not found. Firmware may need update.';
        });
        return;
      }

      // Subscribe to status notifications
      await _statusChar!.setNotifyValue(true);
      _statusSub = _statusChar!.onValueReceived.listen((value) {
        final status = utf8.decode(value);
        debugPrint('BLE Status: $status');
        _handleStatusUpdate(status);
      });

      // Request WiFi scan
      await _requestWifiScan();
    } catch (e) {
      setState(() {
        _step = _ProvisionStep.error;
        _errorMessage = 'Connection failed: ${e.toString()}';
      });
    }
  }

  // ═══════════════════════════════════════════════
  //  STEP 3: Request WiFi scan from ESP32
  // ═══════════════════════════════════════════════
  Future<void> _requestWifiScan() async {
    setState(() {
      _statusMessage = 'Scanning for WiFi networks...';
    });

    try {
      // Reading the scan characteristic triggers a WiFi scan on the ESP32
      final value = await _scanChar!.read();
      final rawData = utf8.decode(value);
      debugPrint('WiFi scan result: $rawData');

      if (rawData == 'NO_NETWORKS' || rawData == 'READY') {
        // The first read returns READY; read again after a delay
        await Future.delayed(const Duration(seconds: 3));
        final value2 = await _scanChar!.read();
        final rawData2 = utf8.decode(value2);
        _parseNetworks(rawData2);
      } else {
        _parseNetworks(rawData);
      }
    } catch (e) {
      setState(() {
        _step = _ProvisionStep.error;
        _errorMessage = 'WiFi scan failed: ${e.toString()}';
      });
    }
  }

  void _parseNetworks(String rawData) {
    if (rawData == 'NO_NETWORKS' || rawData.isEmpty) {
      setState(() {
        _step = _ProvisionStep.error;
        _errorMessage = 'No WiFi networks found. Make sure your router is on.';
      });
      return;
    }

    // Format: SSID1,RSSI1,encrypted1|SSID2,RSSI2,encrypted2|...
    final networks = <_WifiNetwork>[];
    final entries = rawData.split('|');
    for (final entry in entries) {
      final parts = entry.split(',');
      if (parts.length >= 2) {
        networks.add(_WifiNetwork(
          ssid: parts[0],
          rssi: int.tryParse(parts[1]) ?? -100,
          isSecured: parts.length > 2 ? parts[2] == '1' : true,
        ));
      }
    }

    // Sort by signal strength
    networks.sort((a, b) => b.rssi.compareTo(a.rssi));

    setState(() {
      _networks = networks;
      _step = _ProvisionStep.wifiList;
    });
  }

  // ═══════════════════════════════════════════════
  //  STEP 4: Send credentials to ESP32
  // ═══════════════════════════════════════════════
  Future<void> _sendCredentials() async {
    if (_selectedNetwork == null) return;

    final ssid = _selectedNetwork!.ssid;
    final password = _passwordCtrl.text;

    if (_selectedNetwork!.isSecured && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the WiFi password')),
      );
      return;
    }

    setState(() {
      _step = _ProvisionStep.sendingCreds;
      _statusMessage = 'Sending credentials to dispenser...';
      _isSending = true;
    });

    try {
      // Format: SSID|PASSWORD|UID — ESP32 saves all three to NVS
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final payload = '$ssid|$password|$uid';
      await _credsChar!.write(utf8.encode(payload), withoutResponse: false);
      debugPrint('Credentials sent: $ssid|****|${uid.substring(0, 8)}...');

      setState(() {
        _statusMessage = 'Connecting ESP32 to $ssid...';
      });
    } catch (e) {
      setState(() {
        _step = _ProvisionStep.error;
        _errorMessage = 'Failed to send credentials: ${e.toString()}';
        _isSending = false;
      });
    }
  }

  void _handleStatusUpdate(String status) {
    if (!mounted) return;

    if (status == 'CONNECTING') {
      setState(() {
        _statusMessage = 'ESP32 is connecting to WiFi...';
      });
    } else if (status == 'SUCCESS') {
      setState(() {
        _step = _ProvisionStep.done;
        _statusMessage = 'WiFi configured successfully!';
        _isSending = false;
      });
    } else if (status.startsWith('FAILED')) {
      setState(() {
        _step = _ProvisionStep.wifiList;
        _statusMessage = '';
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed. Please check the password and try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } else if (status.startsWith('ERROR')) {
      setState(() {
        _step = _ProvisionStep.error;
        _errorMessage = status.replaceFirst('ERROR:', '');
        _isSending = false;
      });
    }
  }

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text('Pair Hardware',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: switch (_step) {
          _ProvisionStep.scanning    => _buildScanningUI(),
          _ProvisionStep.connecting  => _buildConnectingUI(),
          _ProvisionStep.wifiList    => _buildWifiListUI(),
          _ProvisionStep.sendingCreds => _buildSendingUI(),
          _ProvisionStep.done        => _buildDoneUI(),
          _ProvisionStep.error       => _buildErrorUI(),
        },
      ),
    );
  }

  // ── Scanning for ESP32 ──
  Widget _buildScanningUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withValues(alpha: 0.1 + _pulseCtrl.value * 0.1),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3 + _pulseCtrl.value * 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.bluetooth_searching, size: 48, color: AppColors.teal),
              ),
            ),
            const SizedBox(height: 32),
            Text('Searching for Dispenser',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(_statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.teal),
          ],
        ),
      ),
    );
  }

  // ── Connecting to device ──
  Widget _buildConnectingUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.bluetooth_connected, size: 44, color: AppColors.teal),
            ),
            const SizedBox(height: 32),
            Text('Connecting...',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(_statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.teal),
          ],
        ),
      ),
    );
  }

  // ── WiFi network list ──
  Widget _buildWifiListUI() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: AppColors.navy,
          child: Column(
            children: [
              const Icon(Icons.wifi, color: AppColors.tealLight, size: 28),
              const SizedBox(height: 8),
              Text('Select WiFi Network',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Choose the network for your dispenser',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            ],
          ),
        ),
        // Network list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _networks.length,
            itemBuilder: (context, index) {
              final net = _networks[index];
              final isSelected = _selectedNetwork == net;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedNetwork = net);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.teal.withValues(alpha: 0.08) : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.teal : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _signalIcon(net.rssi),
                        color: isSelected ? AppColors.teal : AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(net.ssid,
                                style: GoogleFonts.outfit(
                                  fontSize: 15, fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.teal : AppColors.textPrimary,
                                )),
                            Text('${net.rssi} dBm',
                                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      if (net.isSecured)
                        Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.teal, size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Password input + send button
        if (_selectedNetwork != null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, -4))],
            ),
            child: Column(
              children: [
                if (_selectedNetwork!.isSecured)
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Enter WiFi password',
                      hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textMuted),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.teal, width: 2),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isSending ? null : _sendCredentials,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text('Connect Dispenser',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        // Refresh button
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextButton.icon(
            onPressed: _requestWifiScan,
            icon: const Icon(Icons.refresh, size: 18, color: AppColors.teal),
            label: Text('Rescan Networks', style: GoogleFonts.outfit(color: AppColors.teal)),
          ),
        ),
      ],
    );
  }

  // ── Sending credentials / connecting ──
  Widget _buildSendingUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.wifi_protected_setup, size: 44, color: AppColors.teal),
            ),
            const SizedBox(height: 32),
            Text('Configuring WiFi',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(_statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.teal),
            const SizedBox(height: 16),
            Text('The dispenser will reboot automatically',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── Success ──
  Widget _buildDoneUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_circle_outline, size: 52, color: AppColors.success),
            ),
            const SizedBox(height: 32),
            Text('Hardware Paired!',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.success)),
            const SizedBox(height: 12),
            Text('Your dispenser is now connected to WiFi\n'
                'and linked to your account.\n'
                'It will reboot and start operating normally.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Done', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──
  Widget _buildErrorUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            ),
            const SizedBox(height: 32),
            Text('Setup Failed',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.danger)),
            const SizedBox(height: 12),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  _device?.disconnect();
                  _startBLEScan();
                },
                icon: const Icon(Icons.refresh, size: 20),
                label: Text('Try Again', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _signalIcon(int rssi) {
    if (rssi > -50) return Icons.signal_wifi_4_bar;
    if (rssi > -60) return Icons.network_wifi_3_bar;
    if (rssi > -70) return Icons.network_wifi_2_bar;
    if (rssi > -80) return Icons.network_wifi_1_bar;
    return Icons.signal_wifi_0_bar;
  }
}

class _WifiNetwork {
  final String ssid;
  final int rssi;
  final bool isSecured;

  _WifiNetwork({required this.ssid, required this.rssi, required this.isSecured});
}
