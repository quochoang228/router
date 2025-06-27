# Data Preservation trong Route Guard

# Data Preservation trong Route Guard

## Tổng quan

Router hiện đã hỗ trợ **giữ nguyên toàn bộ data** khi redirect do route guard. Điều này bao gồm:

- ✅ **Path Parameters** (ví dụ: `/profile/:userId`)
- ✅ **Query Parameters** (ví dụ: `?tab=privacy&theme=dark`)
- ✅ **Extra Data** (object data được truyền qua `extra`)
- ✅ **Auto-restore** khi auth state thay đổi (không cần gọi manual)
- ✅ **Manual restore** nếu cần control chi tiết

## 🔥 Auto-Restore vs Manual Restore

### Auto-Restore (Recommended) ⭐

```dart
// Setup một lần trong main()
AppRouterGuard.initializeAutoRestore();

// Trong AuthService - chỉ cần notify auth state
class AuthService {
  Future<bool> login(String username, String password) async {
    bool success = await performLogin(username, password);
    
    if (success) {
      // ✨ Magic! Chỉ cần notify - router tự động restore
      AppRouterGuard.notifyAuthStateChanged(true);
    }
    
    return success;
  }
}
```

### Manual Restore (Nếu cần control)

```dart
// Cách cũ - vẫn hoạt động
class AuthService {
  Future<bool> login(String username, String password) async {
    bool success = await performLogin(username, password);
    
    if (success) {
      // Phải tự gọi restore
      RouterService.restoreSavedRoute();
    }
    
    return success;
  }
}
```

## Cách hoạt động

### 1. Khi user truy cập protected route mà chưa đăng nhập:

```dart
// User truy cập: /profile/user123?tab=settings
// Extra data: { name: "Nguyễn Văn A", age: 25 }

// Router tự động:
// 1. Lưu toàn bộ GoRouterState (path, query, extra)
// 2. Redirect về /login
// 3. Sau khi login thành công → tự động khôi phục về /profile/user123?tab=settings với extra data
```

### 2. API mới được thêm vào:

```dart
// Khôi phục route đã lưu (thường gọi sau khi login thành công)
RouterService.restoreSavedRoute();

// Lấy thông tin về route đã lưu
Map<String, dynamic>? info = RouterService.getSavedRouteInfo();

// Xóa route đã lưu
RouterService.clearSavedRoute();
```

## Setup và Cấu hình

### 1. Khởi tạo Auto-Restore (một lần trong main())

```dart
void main() {
  // Initialize auto-restore system
  AppRouterGuard.initializeAutoRestore();
  
  runApp(MyApp());
}
```

### 2. Cấu hình AuthService để notify router

```dart
class AuthService {
  Future<bool> login(String username, String password) async {
    bool success = await _performLogin(username, password);
    
    if (success) {
      // Option 1: Auto-restore (Recommended)
      AppRouterGuard.notifyAuthStateChanged(true);
      
      // Option 2: Manual restore (nếu cần)
      // RouterService.restoreSavedRoute();
    }
    
    return success;
  }
  
  Future<void> logout() async {
    await _performLogout();
    
    // Clear saved route và notify
    RouterService.clearSavedRoute();
    AppRouterGuard.notifyAuthStateChanged(false);
  }
}
```

### 3. Optional: Cấu hình callback

```dart
// Trong app initialization
RouterService.configureAutoRestore(
  onAuthStateChanged: () {
    print('Route đã được auto-restore!');
    // Có thể hiển thị notification, refresh data, etc.
  },
);
```

### 2. Kiểm tra saved route info

```dart
void checkSavedRoute() {
  final info = RouterService.getSavedRouteInfo();
  if (info != null) {
    print('Saved path: ${info['path']}');
    print('Path params: ${info['pathParameters']}');
    print('Query params: ${info['queryParameters']}');
    print('Extra data: ${info['extra']}');
  }
}
```

### 3. Manual restore (nếu cần)

```dart
// Trường hợp đặc biệt, bạn có thể tự quyết định khi nào restore
void manualRestore() {
  final savedInfo = RouterService.getSavedRouteInfo();
  if (savedInfo != null) {
    // Kiểm tra điều kiện nào đó...
    if (shouldRestore) {
      RouterService.restoreSavedRoute();
    } else {
      RouterService.clearSavedRoute(); // Bỏ qua việc restore
    }
  }
}
```

## Ví dụ thực tế

### Scenario 1: E-commerce App

```dart
// User đang xem chi tiết sản phẩm với nhiều filter
context.go('/products/phone123?color=red&storage=128gb&sort=price', extra: {
  'cartItems': ['item1', 'item2'],
  'previousPage': '/category/electronics'
});

// Chưa đăng nhập → redirect về /login
// Sau khi login → tự động quay lại chính xác trang sản phẩm với:
// - Product ID: phone123  
// - Filters: color=red, storage=128gb, sort=price
// - Cart items và previous page info
```

### Scenario 2: Banking App

```dart
// User đang điền form chuyển khoản
context.go('/transfer?beneficiary=123456789', extra: {
  'amount': 1000000,
  'message': 'Chuyển tiền học phí',
  'formData': formController.data
});

// Session hết hạn → redirect về /login
// Sau khi đăng nhập → quay lại form với toàn bộ thông tin đã điền
```

### Scenario 3: Social Media App

```dart
// User đang xem profile của ai đó với tab cụ thể
context.go('/user/john_doe?tab=photos&page=2', extra: {
  'fromNotification': true,
  'notificationId': 'notif_123'
});

// Chưa đăng nhập → redirect về /login  
// Sau login → quay lại đúng tab photos, page 2 của user john_doe
```

## Best Practices

### 1. Tự động restore trong AuthService

```dart
class AuthService {
  Future<void> loginWithSavedRoute(String username, String password) async {
    final success = await login(username, password);
    if (success) {
      // Auto restore - recommended approach
      RouterService.restoreSavedRoute();
    }
  }
}
```

### 2. Hiển thị preview cho user

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final savedInfo = RouterService.getSavedRouteInfo();
    
    return Scaffold(
      body: Column(
        children: [
          LoginForm(),
          if (savedInfo != null)
            Card(
              child: Text('Sau khi đăng nhập, bạn sẽ quay lại: ${savedInfo['path']}'),
            ),
        ],
      ),
    );
  }
}
```

### 3. Clear saved route khi cần

```dart
class LogoutService {
  void logout() {
    // Clear user session
    _clearUserData();
    
    // Clear saved route để tránh restore nhầm
    RouterService.clearSavedRoute();
    
    // Navigate to login
    RouterService.navigateTo('/login');
  }
}
```

## Lưu ý quan trọng

1. **Automatic cleanup**: Saved route sẽ tự động bị xóa khi:
   - User truy cập route không protected
   - Gọi `RouterService.restoreSavedRoute()`
   - Gọi `RouterService.clearSavedRoute()`

2. **Memory management**: Chỉ lưu 1 route gần nhất, route mới sẽ ghi đè route cũ

3. **Security**: Extra data được lưu trong memory, không persist qua app restart

4. **Compatibility**: Tương thích ngược hoàn toàn với code cũ

## Demo

Chạy file `example/data_preservation_demo.dart` để xem demo đầy đủ các tính năng.
