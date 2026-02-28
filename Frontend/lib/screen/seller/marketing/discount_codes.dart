import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/discount_services.dart';

class DiscountCodesScreen extends StatefulWidget {
  const DiscountCodesScreen({super.key});

  @override
  _DiscountCodesScreenState createState() => _DiscountCodesScreenState();
}

class _DiscountCodesScreenState extends State<DiscountCodesScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final coupons = await DiscountService.getAllDiscountCodes();
      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? coupon}) {
    final isEdit = coupon != null;
    final codeController = TextEditingController(text: coupon?['code']);
    final titleController = TextEditingController(text: coupon?['title']);
    final descController = TextEditingController(text: coupon?['description']);
    final discountValueController =
        TextEditingController(text: coupon?['discount_value']?.toString());
    final minOrderController =
        TextEditingController(text: coupon?['min_order_value']?.toString());
    final userIdController =
        TextEditingController(text: coupon?['user_id']?.toString());

    String discountType = coupon?['discount_type'] ?? 'percent';
    DateTime? startAt = coupon?['start_at'] != null
        ? DateTime.parse(coupon!['start_at'])
        : null;
    DateTime? endAt =
        coupon?['end_at'] != null ? DateTime.parse(coupon!['end_at']) : null;
    bool active = coupon?['active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Sửa mã giảm giá' : 'Thêm mã giảm giá'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã code *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: discountType,
                  decoration: const InputDecoration(
                    labelText: 'Loại giảm giá *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'percent', child: Text('Phần trăm (%)')),
                    DropdownMenuItem(
                        value: 'fixed', child: Text('Số tiền cố định')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      discountType = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountValueController,
                  decoration: InputDecoration(
                    labelText: discountType == 'percent'
                        ? 'Giá trị giảm (%) *'
                        : 'Giá trị giảm (VNĐ) *',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Giá trị đơn tối thiểu (VNĐ)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID (để trống = áp dụng cho tất cả)',
                    border: OutlineInputBorder(),
                    helperText: 'Nhập ID user cụ thể hoặc để trống',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(startAt != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(startAt!)
                      : 'Chưa chọn'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startAt ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime:
                            TimeOfDay.fromDateTime(startAt ?? DateTime.now()),
                      );
                      if (time != null) {
                        setDialogState(() {
                          startAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  title: const Text('Ngày kết thúc'),
                  subtitle: Text(endAt != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(endAt!)
                      : 'Chưa chọn'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endAt ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime:
                            TimeOfDay.fromDateTime(endAt ?? DateTime.now()),
                      );
                      if (time != null) {
                        setDialogState(() {
                          endAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                if (isEdit)
                  SwitchListTile(
                    title: const Text('Kích hoạt'),
                    value: active,
                    onChanged: (value) {
                      setDialogState(() {
                        active = value;
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isEmpty ||
                    discountValueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng điền đầy đủ thông tin *')),
                  );
                  return;
                }

                try {
                  final discountValue =
                      double.parse(discountValueController.text);
                  final minOrderValue = minOrderController.text.isEmpty
                      ? 0.0
                      : double.parse(minOrderController.text);
                  final userId = userIdController.text.isEmpty
                      ? null
                      : int.parse(userIdController.text);

                  if (isEdit) {
                    await DiscountService.updateDiscountCode(
                      discountCodeId: coupon['id'],
                      code: codeController.text,
                      title: titleController.text.isEmpty
                          ? null
                          : titleController.text,
                      description: descController.text.isEmpty
                          ? null
                          : descController.text,
                      discountType: discountType,
                      discountValue: discountValue,
                      minOrderValue: minOrderValue,
                      startAt: startAt,
                      endAt: endAt,
                      active: active,
                      userId: userId,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật thành công!')),
                      );
                    }
                  } else {
                    await DiscountService.createDiscountCode(
                      code: codeController.text,
                      title: titleController.text.isEmpty
                          ? null
                          : titleController.text,
                      description: descController.text.isEmpty
                          ? null
                          : descController.text,
                      discountType: discountType,
                      discountValue: discountValue,
                      minOrderValue: minOrderValue,
                      startAt: startAt,
                      endAt: endAt,
                      userId: userId,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thêm mới thành công!')),
                      );
                    }
                  }

                  Navigator.pop(context);
                  _loadCoupons();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCoupon(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa mã giảm giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DiscountService.deleteDiscountCode(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa thành công!')),
          );
        }
        _loadCoupons();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Quản lý mã giảm giá',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCoupons,
              child: _coupons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có mã giảm giá nào',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _coupons.length,
                      itemBuilder: (context, index) {
                        final coupon = _coupons[index];
                        return _buildCouponCard(coupon);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm mã'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final isActive = coupon['active'] == true;
    final discountType = coupon['discount_type'];
    final discountValue = coupon['discount_value'];
    final userId = coupon['user_id'];

    String discountText;
    if (discountType == 'percent') {
      discountText = '${discountValue.toStringAsFixed(0)}%';
    } else {
      discountText = '${NumberFormat('#,###').format(discountValue)}đ';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coupon['code'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Hoạt động' : 'Tắt',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (coupon['title'] != null)
              Text(
                coupon['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (coupon['description'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  coupon['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.discount, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Giảm: $discountText',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Đơn tối thiểu: ${NumberFormat('#,###').format(coupon['min_order_value'])}đ',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (userId != null)
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Cho User ID: $userId',
                    style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Áp dụng cho tất cả user',
                    style: TextStyle(fontSize: 13, color: Colors.green[800]),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (coupon['start_at'] != null || coupon['end_at'] != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateRange(coupon['start_at'], coupon['end_at']),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddEditDialog(coupon: coupon),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteCoupon(coupon['id']),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(String? start, String? end) {
    final formatter = DateFormat('dd/MM/yyyy');
    if (start != null && end != null) {
      return '${formatter.format(DateTime.parse(start))} - ${formatter.format(DateTime.parse(end))}';
    } else if (start != null) {
      return 'Từ ${formatter.format(DateTime.parse(start))}';
    } else if (end != null) {
      return 'Đến ${formatter.format(DateTime.parse(end))}';
    } else {
      return 'Không giới hạn';
    }
  }
}
