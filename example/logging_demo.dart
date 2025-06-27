import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:router/router.dart';

void main() {
  // Initialize auto-restore system
  AppRouterGuard.initializeAutoRestore();

  runApp(LoggingDemoApp());
}

class LoggingDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routerService = RouterService();

    // Register routes
    routerService.registerRoutes([
      RouteEntry(
        path: '/',
        builder: (context, state) => LoggingDemoPage(),
      ),
      RouteEntry(
        path: '/login',
        builder: (context, state) => LoginPage(),
      ),
      RouteEntry(
        path: '/protected/:id',
        builder: (context, state) => ProtectedPage(
          id: state.pathParameters['id'] ?? '',
          extra: state.extra,
        ),
        protected: true,
      ),
    ]);

    return MaterialApp.router(
      title: 'Router Logging Demo',
      routerConfig: routerService.router,
    );
  }
}

class LoggingDemoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Router Logging Demo'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📝 Router Logging System',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                        'Router đã được cải tiến để sử dụng RouterLogger thay vì print()'),
                    Text('Tất cả logs sẽ được format và có prefix [Router]'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('🧪 Test Logging Functions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                RouterLogger.info('This is an info message from demo');
              },
              child: Text('Test Info Log'),
            ),
            ElevatedButton(
              onPressed: () {
                RouterLogger.warning('This is a warning message from demo');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Test Warning Log'),
            ),
            ElevatedButton(
              onPressed: () {
                RouterLogger.error('This is an error message from demo');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Test Error Log'),
            ),
            ElevatedButton(
              onPressed: () {
                RouterLogger.debug('This is a debug message from demo');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Test Debug Log'),
            ),
            SizedBox(height: 30),
            Text('🔒 Test Auto-Restore Logging',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // This will trigger auto-restore logging when redirected to login
                context.go('/protected/demo123', extra: {
                  'message': 'This data should be preserved and logged',
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Access Protected Route\n(triggers logging)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Start performance monitoring to see logs
                RouterPerformanceAnalyzer.startMonitoring();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Performance monitoring started - check logs!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: Text('Start Performance Monitoring\n(generates logs)'),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Log Format:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '[Router INFO] Router Performance Monitoring started...'),
                    Text('[Router ERROR] Auto-restore error: ...'),
                    Text('[Router WARNING] Performance impact detected'),
                    Text('[Router DEBUG] Internal state: ...'),
                  ],
                ),
              ),
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
      appBar: AppBar(title: Text('Login - Logging Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login Page with Auto-Restore Logging'),
            SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('💡 Tips:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('• Check console để thấy các log messages'),
                    Text(
                        '• RouterLogger sẽ log tất cả auto-restore activities'),
                    Text('• Error handling được log mà không crash app'),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                RouterLogger.info(
                    'Login button pressed - triggering auto-restore');

                // Simulate login và trigger auto-restore
                AppRouterGuard.notifyAuthStateChanged(true);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Login successful! Check logs for auto-restore')),
                );
              },
              child: Text('Login & Trigger Auto-Restore'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                RouterLogger.warning('Manual navigation back to home');
                context.go('/');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Manual Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProtectedPage extends StatelessWidget {
  final String id;
  final Object? extra;

  const ProtectedPage({required this.id, this.extra});

  @override
  Widget build(BuildContext context) {
    final data = extra as Map<String, dynamic>?;

    // Log successful restore
    RouterLogger.info('Protected page loaded successfully - ID: $id');
    if (data != null) {
      RouterLogger.debug('Extra data preserved: ${data.keys.join(', ')}');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Protected Page'),
        backgroundColor: Colors.green,
      ),
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
                    Text('✅ Successfully auto-restored with logging!'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Page ID: $id', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            if (data != null) ...[
              Text('📦 Preserved Data:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Message: ${data['message']}'),
              Text(
                  'Timestamp: ${DateTime.fromMillisecondsSinceEpoch(data['timestamp'])}'),
            ] else
              Text('No extra data'),
            SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔍 Logging Activities:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('• Route guard logged the redirect'),
                    Text('• Auto-restore process was logged'),
                    Text('• Data preservation was logged'),
                    Text('• Page load was logged'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                RouterLogger.info(
                    'Navigating back to home from protected page');
                context.go('/');
              },
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
