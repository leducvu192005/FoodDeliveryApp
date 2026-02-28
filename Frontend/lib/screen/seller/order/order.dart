import 'package:flutter/material.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Đơn hàng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.green[700],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green[700],
            tabs: [
              Tab(text: 'Đang chuẩn bị'),
              Tab(text: 'Đã làm xong'),
              Tab(text: 'Sắp tới'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(child: Text('Trống')),
            _buildDoneTab(),
            Center(child: Text('Trống')),
            Center(child: Text('Trống')),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin_circle_outlined, size: 120, color: Colors.orange[200]),
          SizedBox(height: 20),
          Text('Đừng quên đánh dấu đơn hàng là đã sẵn sàng!', 
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 12),
          Text('Việc này sẽ giúp nâng cao chất lượng dịch vụ giao hàng cũng như mang đến trải nghiệm tốt hơn cho khách.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}