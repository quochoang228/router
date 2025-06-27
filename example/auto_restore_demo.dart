import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:router/router.dart';

void main() {
  // Initialize auto-restore system
  AppRouterGuard.initializeAutoRestore();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routerService = RouterService();

    // Configure auto-restore behavior
    RouterService.configureAutoRestore(
      onAuthStateChanged: () {
        print('Route đã được auto-restore sau khi login!');
      },
    );

    // Đăng ký routes
    routerService.registerRoutes([
      RouteEntry(
        path: '/',
        builder: (context, state) => HomePage(),
      ),
      RouteEntry(
        path: '/login',
        builder: (context, state) => AutoLoginPage(),
      ),
      RouteEntry(
        path: '/profile/:userId',
        builder: (context, state) => ProfilePage(
          userId: state.pathParameters['userId'] ?? '',
          extra: state.extra,
        ),
        protected: true,
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
      title: 'Auto-Restore Router Demo',
      routerConfig: routerService.router,
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Auto-Restore Demo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Demo Auto-Restore: Routes sẽ tự động được khôi phục khi login!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✨ Tính năng Auto-Restore:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('• Không cần gọi RouterService.restoreSavedRoute()'),
                    Text(
                        '• Tự động restore khi AuthService thông báo đã login'),
                    Text('• Giữ nguyên toàn bộ data (path, query, extra)'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/profile/user123'),
              child: Text('Profile User 123'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/settings?tab=privacy&theme=dark'),
              child: Text('Settings với Query Params'),
            ),
            ElevatedButton(
              onPressed: () {
                context.go('/orders/order456', extra: {
                  'customerName': 'Nguyễn Văn A',
                  'total': 150000,
                  'items': ['Sản phẩm 1', 'Sản phẩm 2'],
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                });
              },
              child: Text('Order với Complex Extra Data'),
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final savedInfo = RouterService.getSavedRouteInfo();
                      _showSavedRouteInfo(context, savedInfo);
                    },
                    child: Text('Xem Saved Route'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    onPressed: () {
                      RouterService.clearSavedRoute();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã clear saved route')),
                      );
                    },
                    child: Text('Clear Saved'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                // Simulate logout
                _simulateLogout(context);
              },
              child: Text('Simulate Logout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedRouteInfo(BuildContext context, Map<String, dynamic>? info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Saved Route Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (info != null) ...[
                _buildInfoRow('Path', info['path']),
                _buildInfoRow('Path Params', info['pathParameters']),
                _buildInfoRow('Query Params', info['queryParameters']),
                _buildInfoRow('Extra Data', info['extra']),
              ] else
                Text('Không có route nào được lưu',
                    style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${value ?? 'N/A'}', style: TextStyle(fontSize: 12)),
          Divider(),
        ],
      ),
    );
  }

  void _simulateLogout(BuildContext context) {
    // Simulate logout
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã logout - saved route sẽ bị clear')),
    );

    // Clear saved route khi logout
    RouterService.clearSavedRoute();

    // Notify auth state changed to false
    AppRouterGuard.notifyAuthStateChanged(false);
  }
}

class AutoLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Auto-Restore Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.blue),
            SizedBox(height: 20),
            Text('Trang đăng nhập với Auto-Restore',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: _buildSavedRoutePreview(),
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () => _performAutoLogin(context),
                child: Text('Đăng nhập (Auto-Restore)',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _performManualLogin(context),
                child: Text('Đăng nhập (Manual Restore)'),
              ),
            ),
            SizedBox(height: 30),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text('Về Home mà không đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedRoutePreview() {
    final savedInfo = RouterService.getSavedRouteInfo();

    if (savedInfo == null) {
      return Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 8),
          Text('Không có route nào cần khôi phục'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restore, color: Colors.green),
            SizedBox(width: 8),
            Text('Route sẽ được khôi phục:',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 8),
        Text('📍 ${savedInfo['path']}'),
        if (savedInfo['pathParameters']?.isNotEmpty == true)
          Text('🔗 Path params: ${savedInfo['pathParameters']}'),
        if (savedInfo['queryParameters']?.isNotEmpty == true)
          Text('❓ Query params: ${savedInfo['queryParameters']}'),
        if (savedInfo['extra'] != null) Text('📦 Extra data: Available'),
      ],
    );
  }

  void _performAutoLogin(BuildContext context) {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Đang đăng nhập...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Simulate login process
    Future.delayed(Duration(seconds: 2), () {
      // Notify auth state changed - này sẽ trigger auto-restore!
      AppRouterGuard.notifyAuthStateChanged(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Login thành công! Route được auto-restore'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _performManualLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login thành công! Cần gọi manual restore')),
    );

    // Manual restore
    Future.delayed(Duration(milliseconds: 1500), () {
      RouterService.restoreSavedRoute();
    });
  }
}

// Các page khác giống như trước...
class ProfilePage extends StatelessWidget {
  final String userId;
  final Object? extra;

  const ProfilePage({required this.userId, this.extra});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile (Auto-Restored)')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('✅ Page này được auto-restore!'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
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
      appBar: AppBar(title: Text('Settings (Auto-Restored)')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('✨ Auto-restore với query params!'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
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
      appBar: AppBar(title: Text('Order (Auto-Restored)')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('🛒 Order data được preserve hoàn toàn!'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Order ID: $orderId', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            if (orderData != null) ...[
              Text('Customer: ${orderData['customerName']}'),
              Text('Total: ${orderData['total']} VND'),
              Text('Items: ${orderData['items']?.join(', ')}'),
              if (orderData['timestamp'] != null)
                Text(
                    'Timestamp: ${DateTime.fromMillisecondsSinceEpoch(orderData['timestamp'])}'),
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
