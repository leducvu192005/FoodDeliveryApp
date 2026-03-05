import 'package:flutter/material.dart';
import '/services/shipper_services.dart';
import '/services/auth_services.dart';

class ShipperHome extends StatefulWidget {
  const ShipperHome({super.key});

  @override
  State<ShipperHome> createState() => _ShipperHomeState();
}

class _ShipperHomeState extends State<ShipperHome> {
  bool isLoading = false;
  bool isOnline = false;
  ShipperServices? shipperService;

  @override
  void initState() {
    super.initState();
    initService();
  }

  // Lấy token từ SecureStorage
  Future<void> initService() async {
    final token = await AuthService.getToken();

    if (token != null) {
      shipperService = ShipperServices(token: token);
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> handleToggle() async {
    if (shipperService == null) return;

    setState(() => isLoading = true);

    try {
      final newStatus = await shipperService!.toggleOnline();

      setState(() {
        isOnline = newStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Welcome to Shipper Home"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnline ? Colors.green : Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: isLoading ? null : handleToggle,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isOnline ? 'Đang nhận đơn' : 'Bật nhận đơn',
                      style: const TextStyle(fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text("This is Shipper Home Screen"),
      ),
    );
  }
}
