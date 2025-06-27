# Router Module

Router module với hỗ trợ protected routes và GlobalKey<NavigatorState>.

## Tính năng

- ✅ Protected router với xử lý authentication
- ✅ Hỗ trợ GlobalKey<NavigatorState> cho navigation mà không cần BuildContext
- ✅ Route guard tự động redirect khi chưa đăng nhập + **giữ nguyên toàn bộ data**
- ✅ Micro Frontend support với RouteEntry
- ✅ Fade transition animations
- ✅ **Structured logging system** với RouterLogger

## Tính năng mới: Data Preservation

### Route Guard giữ nguyên data khi redirect (Auto-Restore)

```dart
// Setup một lần trong main()
void main() {
  AppRouterGuard.initializeAutoRestore();
  runApp(MyApp());
}

// Trong AuthService - KHÔNG cần gọi RouterService.restoreSavedRoute() nữa!
class AuthService {
  Future<bool> login(String username, String password) async {
    bool success = await performLogin(username, password);
    
    if (success) {
      // ✨ Chỉ cần notify - router tự động restore với toàn bộ data!
      AppRouterGuard.notifyAuthStateChanged(true);
    }
    
    return success;
  }
}
```

## Tính năng mới: GlobalKey<NavigatorState>

### Navigation mà không cần BuildContext

```dart
// Navigate từ bất kỳ đâu trong app
RouterService.navigateTo('/settings');
RouterService.pushTo('/profile');
RouterService.pop();
```

### Sử dụng trong Service classes

```dart
class NotificationService {
  static void handleNotification() {
    RouterService.navigateTo('/notifications');
  }
}
```

## Xem thêm

- [📊 Performance Analysis](PERFORMANCE_ANALYSIS.md) - **Tác động hiệu năng minimal!**
- [� Logging System](LOGGING.md) - **Structured logging với RouterLogger**
- [�🔧 Data Preservation](DATA_PRESERVATION.md)
- [⚡ AuthService Example](example/auth_service_example.dart)
- [🚀 Auto-Restore Demo](example/auto_restore_demo.dart)
- [🧪 Performance Test](example/performance_test_demo.dart)
- [📋 Logging Demo](example/logging_demo.dart)
- [📝 Manual Demo](example/data_preservation_demo.dart)
- [🔑 GlobalKey Usage](GLOBALKEY_USAGE.md)
- [💫 Basic Example](example/main.dart)