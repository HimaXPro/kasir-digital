import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../core/services/print_service.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrintService _printService = PrintService();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    setState(() => _loading = true);
    
    // Listen to bluetooth connection state
    _printService.bluetooth.onStateChanged().listen((state) {
      if (state == BlueThermalPrinter.CONNECTED) {
        setState(() => _connected = true);
      } else if (state == BlueThermalPrinter.DISCONNECTED) {
        setState(() => _connected = false);
      }
    });

    bool isConnected = await _printService.isConnected();
    List<BluetoothDevice> devices = await _printService.getDevices();
    
    if (mounted) {
      setState(() {
        _devices = devices;
        _connected = isConnected;
        _loading = false;
      });
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _loading = true);
    bool success = await _printService.connect(device);
    
    if (mounted) {
      setState(() {
        _selectedDevice = device;
        _connected = success;
        _loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Printer terhubung' : 'Gagal terhubung ke printer'),
          backgroundColor: success ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await _printService.disconnect();
    if (mounted) {
      setState(() {
        _connected = false;
        _selectedDevice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: _connected ? AppTheme.successLight : AppTheme.danger.withAlpha(20),
                child: Row(
                  children: [
                    Icon(
                      _connected ? Icons.print : Icons.print_disabled,
                      color: _connected ? AppTheme.success : AppTheme.danger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _connected ? 'Printer Terhubung' : 'Printer Tidak Terhubung',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: _connected ? AppTheme.success : AppTheme.danger,
                            ),
                          ),
                          if (_selectedDevice != null)
                            Text(
                              _selectedDevice!.name ?? 'Unknown Device',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    if (_connected)
                      TextButton(
                        onPressed: _disconnect,
                        child: const Text('Putuskan'),
                      )
                  ],
                ),
              ),
              Expanded(
                child: _devices.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada perangkat Bluetooth yang dipasangkan.\nSilakan pairing printer Anda di pengaturan Bluetooth HP.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(device.name ?? 'Unknown Device'),
                          subtitle: Text(device.address ?? ''),
                          trailing: ElevatedButton(
                            onPressed: _connected && _selectedDevice?.address == device.address 
                                ? null 
                                : () => _connect(device),
                            child: const Text('Hubungkan'),
                          ),
                        );
                      },
                    ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Perangkat'),
                    onPressed: _initPrinter,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              )
            ],
          ),
    );
  }
}
