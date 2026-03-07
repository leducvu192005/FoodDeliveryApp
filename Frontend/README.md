# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android that va loi SocketException khi login

- `10.0.2.2` chi dung cho Android emulator, khong dung duoc tren Android that.
- App da co nut `API URL` o man hinh login de cau hinh API backend (vi du `192.168.1.10:8000`).
- Backend can chay trong LAN (vi du host `0.0.0.0`, port `8000`).
- Android va may chay backend phai cung mang Wi-Fi/LAN.

Ban cung co the truyen luc build/chay:

```bash
flutter run --dart-define=API_BASE_URL_ANDROID_DEVICE=http://192.168.1.10:8000
```
