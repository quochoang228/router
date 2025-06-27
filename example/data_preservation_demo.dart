import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:router/router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routerService = RouterService();

    // Đăng ký routes với data examples
    routerService.registerRoutes([
      RouteEntry(
        path: '/',
        builder: (context, state) => HomePage(),
      ),
      RouteEntry(
        path: '/login',
        builder: (context, state) => LoginPage(),
      ),
      RouteEntry(
        path: '/profile/:userId',
        builder: (context, state) => ProfilePage(
          userId: state.pathParameters['userId'] ?? '',
          extra: state.extra,
        ),
        protected: true, // Protected route
      ),
      RouteEntry(
        path: '/settings',
        builder: (context, state) => SettingsPage(
          tab: state.uri.queryParameters['tab'] ?? 'general',
          extra: state.extra,
        ),
        protected: true,
      ),
      RouteEntry(
        path: '/orders/:orderId',
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['orderId'] ?? '',
          extra: state.extra,
        ),
        protected: true,
      ),
    ]);

    return MaterialApp.router(
      title: 'Router với Data Preservation Demo',
      routerConfig: routerService.router,
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Demo các route với data sẽ được preserve khi redirect:'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Route với path parameter
                context.go('/profile/user123');
              },
              child: Text('Profile User 123 (Path Parameter)'),
            ),
            ElevatedButton(
              onPressed: () {
                // Route với query parameters
                context.go('/settings?tab=privacy&theme=dark');
              },
              child: Text('Settings với Query Params'),
            ),
            ElevatedButton(
              onPressed: () {
                // Route với extra data
                context.go('/orders/order456', extra: {
                  'customerName': 'Nguyễn Văn A',
                  'total': 150000,
                  'items': ['Sản phẩm 1', 'Sản phẩm 2']
                });
              },
              child: Text('Order Detail với Extra Data'),
            ),
            SizedBox(height: 30),
            Text('Thông tin saved route:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                final savedInfo = RouterService.getSavedRouteInfo();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Saved Route Info'),
                    content: Text(
                        savedInfo?.toString() ?? 'Không có route nào được lưu'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Xem Saved Route Info'),
            ),
            ElevatedButton(
              onPressed: () {
                RouterService.clearSavedRoute();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa saved route')),
                );
              },
              child: Text('Clear Saved Route'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Trang đăng nhập'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simulate login thành công
                _simulateLogin(context);
              },
              child: Text('Đăng nhập thành công'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final savedInfo = RouterService.getSavedRouteInfo();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Route sẽ được khôi phục'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Path: ${savedInfo?['path'] ?? 'N/A'}'),
                        Text(
                            'Path Params: ${savedInfo?['pathParameters'] ?? 'N/A'}'),
                        Text(
                            'Query Params: ${savedInfo?['queryParameters'] ?? 'N/A'}'),
                        Text('Extra Data: ${savedInfo?['extra'] ?? 'N/A'}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Xem route sẽ được khôi phục'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateLogin(BuildContext context) {
    // Simulate đăng nhập thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đăng nhập thành công! Đang khôi phục route...')),
    );

    // Delay một chút để user thấy message
    Future.delayed(Duration(milliseconds: 1500), () {
      // Khôi phục route với toàn bộ data
      RouterService.restoreSavedRoute();
    });
  }
}

class ProfilePage extends StatelessWidget {
  final String userId;
  final Object? extra;

  const ProfilePage({required this.userId, this.extra});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: $userId', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Extra Data: ${extra?.toString() ?? 'Không có'}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Về Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final String tab;
  final Object? extra;

  const SettingsPage({required this.tab, this.extra});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Tab: $tab', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
                'Query Params: ${GoRouterState.of(context).uri.queryParameters}'),
            SizedBox(height: 10),
            Text('Extra Data: ${extra?.toString() ?? 'Không có'}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Về Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  final Object? extra;

  const OrderDetailPage({required this.orderId, this.extra});

  @override
  Widget build(BuildContext context) {
    final orderData = extra as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: Text('Order Detail')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: $orderId', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            if (orderData != null) ...[
              Text('Customer: ${orderData['customerName']}'),
              Text('Total: ${orderData['total']} VND'),
              Text('Items: ${orderData['items']?.join(', ')}'),
            ] else
              Text('Không có dữ liệu đơn hàng'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Về Home'),
            ),
          ],
        ),
      ),
    );
  }
}
