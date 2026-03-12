import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/screen/shipper/edit_profile_screen.dart';
import 'package:flutter_application_1/services/order_service.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';
import '../../config/api_config.dart';
import '../../services/auth_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.orderService,
  });

  final OrderService orderService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ShipperProfileModel> _profileFuture;
  bool _saving = false;
  bool _redirectingToLogin = false;
  double _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.orderService.getShipperProfile();
    _loadWallet();
  }

  Future<void> _reload() async {
    setState(() {
      _profileFuture = widget.orderService.getShipperProfile();
    });
    try {
      await _profileFuture;
    } catch (error, _) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.orderService.setShipperOnline(isOnline: false);
    } catch (_) {}

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _redirectToLoginIfNeeded() {
    if (!mounted || _redirectingToLogin) return;
    _redirectingToLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    });
  }

  Future<void> _openEditProfileScreen(ShipperProfileModel profile) async {
    final updatedProfile =
        await Navigator.of(context).push<ShipperProfileModel>(
      MaterialPageRoute(
        builder: (_) => EditShipperProfileScreen(
          orderService: widget.orderService,
          initialProfile: profile,
        ),
      ),
    );
    if (!mounted || updatedProfile == null) return;
    setState(() {
      _profileFuture = Future<ShipperProfileModel>.value(updatedProfile);
    });
    _showSnack('Cap nhat thong tin ca nhan thanh cong');
  }

  // ========== TẢI SỐ DƯ VÍ ==========
  Future<void> _loadWallet() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final resp = await http.get(
        Uri.parse(ApiConfig.path('/shipper/wallet')),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() =>
              _walletBalance = (data['balance'] as num?)?.toDouble() ?? 0);
        }
      }
    } catch (_) {}
  }

  // ========== MỞ MÀN HÌNH VÍ ==========
  void _openWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShipperWalletScreen(balance: _walletBalance),
      ),
    ).then((_) => _loadWallet());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ca nhan',
        ),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            onPressed: _saving ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<ShipperProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (snapshot.error.toString().contains("Vui long dang nhap lai")) {
              _redirectToLoginIfNeeded();
            }

            return const Center(child: Text("Session expired"));
          }

          final profile = snapshot.data!;
          final displayName = profile.fullName.trim().isEmpty
              ? 'Chua cap nhat ten'
              : profile.fullName;
          final displayPhone = profile.phone.trim().isEmpty
              ? 'Chua cap nhat so dien thoai'
              : profile.phone;
          final displayAddress = profile.address.trim().isEmpty
              ? 'Chua cap nhat dia chi'
              : profile.address;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFFE4BF),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayPhone,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayAddress,
                                style: const TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.55,
                  children: [
                    StatCard(
                      title: 'So don hoan thanh',
                      value: '${profile.completedOrders}',
                      icon: Icons.task_alt_outlined,
                    ),
                    StatCard(
                      title: 'Ty le hoan thanh',
                      value: '${profile.completionRate.toStringAsFixed(1)}%',
                      icon: Icons.percent_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _EditableInfoCard(
                  icon: Icons.badge_outlined,
                  title: 'Thong tin ca nhan',
                  subtitle: 'Nhan vao de mo man hinh chinh sua thong tin',
                  onTap: _saving ? null : () => _openEditProfileScreen(profile),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thong tin lien he',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(label: 'Email', value: profile.email),
                        _InfoRow(label: 'So dien thoai', value: displayPhone),
                        _InfoRow(label: 'Dia chi', value: displayAddress),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ===== VÍ SHIPPER =====
                _buildWalletCard(),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Dang xuat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========== CARD VÍ SHIPPER ==========
  Widget _buildWalletCard() {
    return GestureDetector(
      onTap: _openWallet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepOrange, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withAlpha(60),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vi cua ban',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatMoney(_walletBalance)} d',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 28),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return amount.toStringAsFixed(0);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Chua cap nhat' : value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInfoCard extends StatelessWidget {
  const _EditableInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

// ========== MÀN HÌNH VÍ SHIPPER ==========
class ShipperWalletScreen extends StatefulWidget {
  final double balance;
  const ShipperWalletScreen({super.key, required this.balance});

  @override
  State<ShipperWalletScreen> createState() => _ShipperWalletScreenState();
}

class _ShipperWalletScreenState extends State<ShipperWalletScreen> {
  double _balance = 0;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _balance = widget.balance;
    _loadData();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final headers = await _authHeaders();
      final walletResp = await http.get(
        Uri.parse(ApiConfig.path('/shipper/wallet')),
        headers: headers,
      );
      final historyResp = await http.get(
        Uri.parse(ApiConfig.path('/shipper/wallet/history')),
        headers: headers,
      );
      if (mounted) {
        if (walletResp.statusCode == 200) {
          final data = jsonDecode(walletResp.body);
          _balance = (data['balance'] as num?)?.toDouble() ?? 0;
        }
        if (historyResp.statusCode == 200) {
          _history =
              List<Map<String, dynamic>>.from(jsonDecode(historyResp.body));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showDepositDialog() {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nap tien qua chuyen khoan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'So du hien tai: ${_formatMoney(_balance)} d',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'So tien nap (d)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui long nhap so tien hop le')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _startSepayDeposit(amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                const Text('Tiep tuc', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _startSepayDeposit(double amount) async {
    try {
      final headers = await _authHeaders();
      final resp = await http.post(
        Uri.parse(ApiConfig.path('/api/sepay/shipper-deposit/create')),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );

      if (resp.statusCode != 200) {
        final err = jsonDecode(resp.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err['detail'] ?? 'Tao yeu cau nap tien that bai'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = jsonDecode(resp.body);
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _ShipperDepositQRDialog(
          qrUrl: data['qr_url'] ?? '',
          transactionId: data['transaction_id'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          transferContent: data['transfer_content'] ?? '',
          bankCode: data['bank_code'] ?? '',
          accountNumber: data['account_number'] ?? '',
          accountName: data['account_name'] ?? '',
          depositId: data['deposit_id'] as int,
        ),
      );

      if (result == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nap tien thanh cong: ${_formatMoney(amount)} d'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showWithdrawDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rut tien'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'So du hien tai: ${_formatMoney(_balance)} d',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'So tien rut (d)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chu (tuy chon)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui long nhap so tien hop le')),
                );
                return;
              }
              if (amount > _balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('So du khong du')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _doWithdraw(amount, noteCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child:
                const Text('Rut tien', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _doWithdraw(double amount, String note) async {
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.path('/shipper/wallet/withdraw')),
        headers: await _authHeaders(),
        body: jsonEncode({
          'amount': amount,
          if (note.isNotEmpty) 'note': note,
        }),
      );
      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rut tien thanh cong: ${_formatMoney(amount)} d'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadData();
      } else {
        final err = jsonDecode(resp.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err['detail'] ?? 'Rut tien that bai'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vi cua toi'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepOrange, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('So du',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatMoney(_balance)} d',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showDepositDialog,
                                icon: const Icon(Icons.arrow_upward),
                                label: const Text('Nap tien'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _balance > 0 ? _showWithdrawDialog : null,
                                icon: const Icon(Icons.arrow_downward),
                                label: const Text('Rut tien'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.deepOrange,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Lich su giao dich',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Chua co lich su giao dich',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._history.map((h) => _buildHistoryItem(h)),
                ],
              ),
            ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> h) {
    final type = (h['type'] ?? 'withdraw').toString();
    final isDeposit = type == 'deposit';
    final amount = (h['amount'] as num?)?.toDouble() ?? 0;
    final balanceAfter = (h['balance_after'] as num?)?.toDouble() ?? 0;
    final note = (h['note'] ?? '').toString();
    final createdAt = (h['created_at'] ?? '').toString();

    String dateDisplay = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateDisplay =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        dateDisplay = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDeposit
                  ? Colors.green.withAlpha(25)
                  : Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDeposit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isDeposit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? 'Nap tien' : 'Rut tien',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                if (note.isNotEmpty)
                  Text(note,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(dateDisplay,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDeposit ? '+' : '-'}${_formatMoney(amount)} d',
                style: TextStyle(
                  color: isDeposit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'Con lai: ${_formatMoney(balanceAfter)} d',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== DIALOG QR NẠP TIỀN SHIPPER ==========
class _ShipperDepositQRDialog extends StatefulWidget {
  final String qrUrl;
  final String transactionId;
  final double amount;
  final String transferContent;
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final int depositId;

  const _ShipperDepositQRDialog({
    required this.qrUrl,
    required this.transactionId,
    required this.amount,
    required this.transferContent,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    required this.depositId,
  });

  @override
  State<_ShipperDepositQRDialog> createState() =>
      _ShipperDepositQRDialogState();
}

class _ShipperDepositQRDialogState extends State<_ShipperDepositQRDialog> {
  bool _isChecking = false;
  bool _autoChecking = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _startAutoChecking();
    });
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _startAutoChecking() async {
    if (_autoChecking) return;
    setState(() => _autoChecking = true);

    try {
      for (int i = 0; i < 40; i++) {
        if (!mounted) return;

        final status = await _checkStatus();
        if (status == 'paid') {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('Auto check error: $e');
    } finally {
      if (mounted) setState(() => _autoChecking = false);
    }
  }

  Future<String> _checkStatus() async {
    final resp = await http.get(
      Uri.parse(ApiConfig.path(
          '/api/sepay/shipper-deposit/check-status/${widget.depositId}')),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['status']?.toString() ?? 'pending';
    }
    return 'pending';
  }

  Future<void> _checkPaymentStatus() async {
    setState(() => _isChecking = true);
    try {
      final status = await _checkStatus();
      if (status == 'paid') {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Chua nhan duoc xac nhan. Vui long doi them hoac thu lai.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _cancelDeposit() async {
    try {
      await http.post(
        Uri.parse(ApiConfig.path(
            '/api/sepay/shipper-deposit/cancel/${widget.depositId}')),
        headers: await _authHeaders(),
      );
    } catch (e) {
      debugPrint('Cancel error: $e');
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4CAF50);

    return AlertDialog(
      title: const Text(
        'Nap tien qua Chuyen khoan',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                widget.qrUrl,
                width: 250,
                height: 250,
                errorBuilder: (_, __, ___) => Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(Icons.qr_code, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _DepositInfoRow(label: 'Ngan hang:', value: widget.bankCode),
            _DepositInfoRow(
                label: 'So tai khoan:', value: widget.accountNumber),
            _DepositInfoRow(label: 'Ten tai khoan:', value: widget.accountName),
            _DepositInfoRow(
              label: 'So tien:',
              value: '${_formatMoney(widget.amount)} d',
              valueColor: accent,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Noi dung chuyen khoan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent),
              ),
              child: Text(
                widget.transferContent,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Luu y: Vui long nhap dung noi dung chuyen khoan de he thong tu dong xac nhan.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
            const SizedBox(height: 8),
            if (_autoChecking)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Dang tu dong kiem tra...',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isChecking ? null : _cancelDeposit,
          child: const Text('Huy'),
        ),
        ElevatedButton(
          onPressed: _isChecking ? null : _checkPaymentStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          child: _isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Da chuyen khoan'),
        ),
      ],
    );
  }
}

class _DepositInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DepositInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
