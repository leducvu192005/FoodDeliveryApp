import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  OrderCard({
    super.key,
    required this.order,
    this.showAcceptButton = false,
    this.onAccept,
    this.onTap,
  });

  final OrderModel order;
  final bool showAcceptButton;
  final VoidCallback? onAccept;
  final VoidCallback? onTap;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.restaurant?.name ?? 'Nhà hàng',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (order.paymentMethod.toLowerCase() == 'cod')
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'COD',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.restaurant?.address ?? 'Chưa có địa chỉ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Giao toi: ${order.deliveryAddressDisplay}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _MetaItem(label: 'Số món', value: '${order.itemCount}'),
                  _MetaItem(
                    label: 'Khoảng cách',
                    value: '${order.distanceKm.toStringAsFixed(1)} km',
                  ),
                  _MetaItem(
                    label: 'Tiền ship',
                    value: _currency.format(order.shippingFee),
                  ),
                ],
              ),
              if (showAcceptButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onAccept,
                    child: const Text('Nhận đơn'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = switch (status) {
      OrderStatus.pending => (const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
      OrderStatus.confirmed => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0)
        ),
      OrderStatus.accepted => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32)
        ),
      OrderStatus.pickedUp => (
          const Color(0xFFE0F7FA),
          const Color(0xFF00838F)
        ),
      OrderStatus.delivered => (
          const Color(0xFFE8F5E9),
          const Color(0xFF1B5E20)
        ),
      OrderStatus.cancelled => (
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828)
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.labelVi,
        style: theme.textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
