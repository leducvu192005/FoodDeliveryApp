import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tài chính', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.qr_code_scanner, color: Colors.black), onPressed: () {}),
          IconButton(icon: Icon(Icons.help_outline, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTabHeader(),
            SizedBox(height: 20),
            _buildPeriodSelector(),
            SizedBox(height: 30),
            _buildMainIncome(),
            SizedBox(height: 40),
            _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(children: [Text('Tóm tắt', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), Container(height: 2, width: 40, color: Colors.green, margin: EdgeInsets.only(top: 4))]),
        Text('Giao dịch', style: TextStyle(color: Colors.grey)),
        Text('Số tiền thu về', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip('Hôm nay', true),
        SizedBox(width: 8),
        _chip('Hôm qua', false),
        SizedBox(width: 8),
        _chip('Tuần này', false),
      ],
    );
  }

  Widget _chip(String label, bool active) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.green[50] : Colors.white,
        border: Border.all(color: active ? Colors.green : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: active ? Colors.green[700] : Colors.black)),
    );
  }

  Widget _buildMainIncome() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text('Doanh thu ròng', style: TextStyle(color: Colors.grey)),
            Text('+162.000đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Thu nhập', style: TextStyle(color: Colors.grey)),
            Text('+114.959đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(width: 20),
        Icon(Icons.account_balance_wallet, size: 100, color: Colors.green),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tóm tắt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _row('Doanh thu ròng', '162.000', isBold: false),
                _row('Khấu trừ', '-39.751', isNegative: true),
                _row('Thuế GTGT', '-4.860', isSmall: true),
                _row('Thuế TNCN', '-2.430', isSmall: true),
                Divider(),
                _row('Thu nhập ròng', '+114.959đ', isBold: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _row(String label, String val, {bool isNegative = false, bool isSmall = false, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isSmall ? 13 : 15, color: isSmall ? Colors.grey[600] : Colors.black)),
          Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 17 : 15)),
        ],
      ),
    );
  }
}