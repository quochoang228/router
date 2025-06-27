import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:router/router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Khởi tạo RouterService và đăng ký routes
    final routerService = RouterService();

    // Đăng ký một số routes demo
    routerService.registerRoutes([
      RouteEntry(
        path: '/',
        builder: (context, state) => HomePage(),
      ),
      RouteEntry(
        path: '/settings',
        builder: (context, state) => SettingsPage(),
      ),
      RouteEntry(
        path: '/profile',
        builder: (context, state) => ProfilePage(),
        protected: true, // Route này cần authentication
      ),
    ]);

    return MaterialApp.router(
      title: 'Router Demo',
      routerConfig: routerService.router,
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Page'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Sử dụng GoRouter với context
                context.go('/settings');
              },
              child: Text('Go to Settings (với context)'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Sử dụng GlobalKey - không cần context!
                RouterService.navigateTo('/profile');
              },
              child: Text('Go to Profile (không cần context)'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Demo navigation từ ngoài widget tree
                _navigateFromOutsideWidget();
              },
              child: Text('Navigate từ bên ngoài widget'),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm này có thể được gọi từ bất kỳ đâu, không cần BuildContext
  void _navigateFromOutsideWidget() {
    // Có thể gọi từ Service, Repository, hoặc bất kỳ class nào
    RouterService.pushTo('/settings');
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Settings Page'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Sử dụng GlobalKey để pop
                RouterService.pop();
              },
              child: Text('Back (sử dụng GlobalKey)'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Profile Page (Protected Route)'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => RouterService.navigateTo('/'),
              child: Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Example: Sử dụng từ một Service class (không có BuildContext)
class NotificationService {
  static void showNotificationAndNavigate(String message) {
    // Hiển thị notification
    print('Notification: $message');

    // Navigate mà không cần BuildContext
    RouterService.navigateTo('/settings');
  }

  static void showDialog() {
    final context = RouterService.currentContext;
    if (context != null) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          height: 200,
          child: Center(
            child: Text('Dialog từ Service class!'),
          ),
        ),
      );
    }
  }
}
