import 'package:flutter/material.dart';

import '../../models/shipper/driver_order.dart';

class DriverMapWidget extends StatelessWidget {
  const DriverMapWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.nearbyOrders,
  });

  final double? lat;
  final double? lng;
  final List<DriverOrder> nearbyOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE6CF), Color(0xFFFFF4E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text('Map widget', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Driver: ${lat?.toStringAsFixed(5) ?? '--'}, ${lng?.toStringAsFixed(5) ?? '--'}'),
          const SizedBox(height: 6),
          Text('Pickup points: ${nearbyOrders.length} order(s) nearby'),
        ],
      ),
    );
  }
}
