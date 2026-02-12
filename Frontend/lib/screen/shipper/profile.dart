import 'package:flutter/material.dart';
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        toolbarHeight: 100,
        title: Column(
          children: [
            Row(
              children: [
                Icon(Icons.person),
                Column(
                  children: [
                    Text("Nguyen van A"),
                    Text("0364188807"),
                    Text("Shipper"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("this is profile screen"),
          ],
        ),
      ),
    );
  }
}