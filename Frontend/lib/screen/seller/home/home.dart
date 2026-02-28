import 'package:flutter/material.dart';
import '../menu/menu.dart';
import '../order/order.dart';

class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kitty Food',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '10',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiệu suất bán hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatusCard(
                  'Bình thường',
                  '0',
                  'Đang chuẩn bị',
                  Colors.green,
                ),
                SizedBox(width: 12),
                _buildIncomeCard('Thu nhập hôm nay', '114,959', '3 đơn hàng'),
              ],
            ),
            SizedBox(height: 24),

            SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 20,
              children: [
                _buildMenuIcon(context, Icons.receipt_long, 'Đơn hàng', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderScreen()),
                  );
                }),
                _buildMenuIcon(context, Icons.menu_book, 'Thực đơn', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MenuScreen()),
                  );
                }),
                _buildMenuIcon(context, Icons.people_outline, 'GFin', null),
                _buildMenuIcon(
                  context,
                  Icons.comment_outlined,
                  'Phản hồi',
                  null,
                ),
                _buildMenuIcon(context, Icons.storefront, 'Quán', null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: Colors.white),
                SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.white)),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(sub, style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(String title, String amount, String orders) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              'đ $amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              orders,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 28),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
