# Router với hỗ trợ GlobalKey<NavigatorState>

## Tính năng mới

Đã thêm hỗ trợ `GlobalKey<NavigatorState>` vào RouterService, cho phép:

1. **Navigation mà không cần BuildContext**
2. **Truy cập NavigatorState từ bất kỳ đâu trong app**
3. **Thực hiện navigation từ Service classes, Repository, hoặc bất kỳ class nào**

## Cách sử dụng

### 1. Truy cập GlobalKey

```dart
// Lấy NavigatorState hiện tại
NavigatorState? navigator = RouterService.currentNavigator;

// Lấy BuildContext hiện tại
BuildContext? context = RouterService.currentContext;
```

### 2. Navigation không cần BuildContext

```dart
// Navigate đến route mới (thay thế route hiện tại)
RouterService.navigateTo('/settings');

// Push route mới (thêm vào stack)
RouterService.pushTo('/profile');

// Pop route hiện tại
RouterService.pop();

// Push và replace route hiện tại
RouterService.pushReplacement('/login');
```

### 3. Sử dụng trong Service classes

```dart
class NotificationService {
  static void handleNotificationTap(String route) {
    // Navigation từ service class mà không cần BuildContext
    RouterService.navigateTo(route);
  }
  
  static void showCustomDialog() {
    final context = RouterService.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Notification'),
          content: Text('Dialog từ Service class!'),
        ),
      );
    }
  }
}
```

### 4. Sử dụng trong Repository

```dart
class AuthRepository {
  Future<void> logout() async {
    // Thực hiện logout
    await _clearUserData();
    
    // Navigate về login page mà không cần BuildContext
    RouterService.navigateTo('/login');
  }
  
  Future<void> handleSessionExpired() async {
    // Hiển thị thông báo
    final context = RouterService.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phiên đăng nhập đã hết hạn')),
      );
    }
    
    // Redirect về login
    RouterService.pushReplacement('/login');
  }
}
```

### 5. Setup trong MaterialApp

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routerService = RouterService();
    
    // Đăng ký routes
    routerService.registerRoutes([
      RouteEntry(
        path: '/',
        builder: (context, state) => HomePage(),
      ),
      RouteEntry(
        path: '/settings',
        builder: (context, state) => SettingsPage(),
      ),
    ]);

    return MaterialApp.router(
      title: 'My App',
      routerConfig: routerService.router, // GoRouter tự động sử dụng GlobalKey
    );
  }
}
```

## Lưu ý quan trọng

1. **GlobalKey chỉ hoạt động sau khi MaterialApp được mount**: Đảm bảo không gọi các phương thức navigation trước khi app được khởi tạo hoàn toàn.

2. **Kiểm tra null safety**: Luôn kiểm tra `currentContext` và `currentNavigator` có null không trước khi sử dụng.

3. **Ưu tiên sử dụng BuildContext khi có**: Nếu bạn đang ở trong widget và có BuildContext, vẫn nên sử dụng `context.go()` hoặc `GoRouter.of(context)` để đảm bảo tính nhất quán.

## Ví dụ hoàn chỉnh

Xem file `example/main.dart` để biết cách sử dụng chi tiết.
