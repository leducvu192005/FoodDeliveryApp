import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

class AddCategory extends StatefulWidget {
  @override
  _AddCategoryState createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập tên danh mục'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
    
      final response = await http.post(
        Uri.parse(ApiConfig.categoryUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': _nameController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Thêm danh mục thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); 
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['detail'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thêm danh mục',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text("Tên", style: TextStyle(fontSize: 16)),
                Text("*", style: TextStyle(color: Colors.red)),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: "VD: Đồ uống",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[300]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Lưu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
