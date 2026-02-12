import 'package:flutter/material.dart';

<<<<<<< HEAD
class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
=======
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
>>>>>>> 392c371 (làm giao diện giỏ hàng và xử lí thanh toán)
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
<<<<<<< HEAD
        title: const Text('Profile'),
      ),
      body: const Center(child: Text('This is the Profile Screen')),
=======
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
                    Text("nguyenvana@gmail.com")
                  ],
                )
              ],
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.person),
                Text(
                  "Thông tin cá nhân",
                  style: TextStyle(fontSize: 20),
                ),
                Card(
                  child: ListTile(
                    title: Text("Địa chỉ"),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                )
              ],
            )
          ],
        ),
      ),
>>>>>>> 392c371 (làm giao diện giỏ hàng và xử lí thanh toán)
    );
  }
}
