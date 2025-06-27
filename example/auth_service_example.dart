import 'dart:async';
import 'package:router/router.dart';

/// Example AuthService với Auto-Restore integration
class AuthService {
  static const String loginRouter = '/login';

  bool _isLoggedIn = false;
  String? lastAttemptedRoute;
  String? loginSuccessAttemptedRoute;

  /// Stream để theo dõi auth state changes
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get authStateStream => _authStateController.stream;

  AuthService() {
    // Listen to auth state changes và notify router
    authStateStream.listen((isLoggedIn) {
      AppRouterGuard.notifyAuthStateChanged(isLoggedIn);
    });
  }

  /// Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    // Simulate async check (có thể từ SharedPreferences, SecureStorage, etc.)
    await Future.delayed(Duration(milliseconds: 100));
    return _isLoggedIn;
  }

  /// Đăng nhập - phiên bản AUTO-RESTORE
  Future<bool> loginWithAutoRestore(String username, String password) async {
    print('🔐 Đang đăng nhập với auto-restore...');

    // Simulate login API call
    await Future.delayed(Duration(seconds: 1));

    // Giả sử login thành công
    bool success = username.isNotEmpty && password.isNotEmpty;

    if (success) {
      _isLoggedIn = true;

      // ✨ Chỗ này là magic! Chỉ cần notify auth state changed
      // Router sẽ tự động restore route với toàn bộ data
      _authStateController.add(true);

      print('✅ Login thành công! Router sẽ tự động restore...');
    } else {
      print('❌ Login thất bại!');
    }

    return success;
  }

  /// Đăng nhập - phiên bản MANUAL (cách cũ)
  Future<bool> loginWithManualRestore(String username, String password) async {
    print('🔐 Đăng nhập với manual restore...');

    await Future.delayed(Duration(seconds: 1));
    bool success = username.isNotEmpty && password.isNotEmpty;

    if (success) {
      _isLoggedIn = true;

      // Cách cũ: phải tự gọi restore
      RouterService.restoreSavedRoute();

      print('✅ Login thành công! Đã manual restore route.');
    }

    return success;
  }

  /// Đăng xuất
  Future<void> logout() async {
    print('🚪 Đang đăng xuất...');

    _isLoggedIn = false;

    // Clear saved route khi logout
    RouterService.clearSavedRoute();

    // Notify auth state changed
    _authStateController.add(false);

    // Navigate to login
    RouterService.navigateTo('/login');

    print('✅ Đã đăng xuất và clear saved route.');
  }

  /// Login với custom behavior
  Future<bool> loginWithCustomRestore(
    String username,
    String password, {
    bool shouldAutoRestore = true,
    void Function()? onRestoreComplete,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    bool success = username.isNotEmpty && password.isNotEmpty;

    if (success) {
      _isLoggedIn = true;

      if (shouldAutoRestore) {
        // Configure callback trước khi restore
        if (onRestoreComplete != null) {
          RouterService.configureAutoRestore(
            onAuthStateChanged: onRestoreComplete,
          );
        }

        // Trigger auto-restore
        _authStateController.add(true);
      } else {
        // Skip auto-restore
        print('⏭️ Skip auto-restore theo yêu cầu');
      }
    }

    return success;
  }

  /// Get thông tin về route sẽ được restore
  Map<String, dynamic>? getRestorePreview() {
    return RouterService.getSavedRouteInfo();
  }

  void dispose() {
    _authStateController.close();
  }
}

/// Extension để dễ sử dụng
extension AuthServiceExtension on AuthService {
  /// Quick login với auto-restore
  Future<bool> quickLogin() async {
    return await loginWithAutoRestore('demo_user', 'demo_password');
  }

  /// Login và show preview trước khi restore
  Future<bool> loginWithPreview() async {
    final preview = getRestorePreview();
    if (preview != null) {
      print('📋 Sẽ restore route: ${preview['path']}');
      print('📦 Với data: ${preview['extra']}');
    }

    return await loginWithAutoRestore('demo_user', 'demo_password');
  }
}

/// Example usage trong app
class AuthIntegrationExample {
  static void demonstrateUsage() {
    final authService = AuthService();

    // Method 1: Auto-restore (Recommended)
    authService.loginWithAutoRestore('username', 'password').then((success) {
      if (success) {
        print('✨ Login thành công! Route sẽ tự động được restore.');
      }
    });

    // Method 2: Manual restore (nếu cần control)
    authService.loginWithManualRestore('username', 'password');

    // Method 3: Custom restore với callback
    authService.loginWithCustomRestore(
      'username',
      'password',
      shouldAutoRestore: true,
      onRestoreComplete: () {
        print('🎉 Route đã được restore! Có thể thực hiện thêm action...');
        // Ví dụ: hiển thị welcome message, refresh data, etc.
      },
    );

    // Method 4: Quick login
    authService.quickLogin();

    // Method 5: Login với preview
    authService.loginWithPreview();
  }
}

/// Singleton pattern cho global access
class Auth {
  static AuthService? _instance;

  static AuthService get instance {
    _instance ??= AuthService();
    return _instance!;
  }

  /// Quick access methods
  static Future<bool> login(String username, String password) {
    return instance.loginWithAutoRestore(username, password);
  }

  static Future<void> logout() {
    return instance.logout();
  }

  static Future<bool> isLoggedIn() {
    return instance.isLoggedIn();
  }
}
