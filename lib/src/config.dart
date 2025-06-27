part of '../router.dart';

/// Utility logger cho Router module
class RouterLogger {
  static void info(String message) {
    LogUtils.i('[Router INFO] $message');
  }

  static void error(String message) {
    LogUtils.e('[Router ERROR] $message');
  }

  static void debug(String message) {
    LogUtils.d('[Router DEBUG] $message');
  }

  static void warning(String message) {
    LogUtils.w('[Router WARNING] $message');
  }
}

/// Router Service quản lý toàn bộ navigation trong app
class RouterService extends ChangeNotifier {
  final List<RouteEntry> _routes = [];
  late GoRouter _router;

  /// GlobalKey để truy cập NavigatorState từ bất kỳ đâu trong app
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Callback được gọi khi cần restore route sau khi login
  static void Function()? _onAuthStateChanged;

  /// Cấu hình auto-restore khi auth state thay đổi
  static void configureAutoRestore({
    void Function()? onAuthStateChanged,
  }) {
    _onAuthStateChanged = onAuthStateChanged;
  }

  // List<RouteEntry> get routes => _routes;

  static Set<String> protectedRoutes = {};

  RouterService() {
    _updateRouter();
  }

  // RouterService() {
  //   _router = GoRouter(
  //     initialLocation: '/',
  //     debugLogDiagnostics: false,
  //     routes: _routes.map((entry) {
  //       return GoRoute(
  //         path: entry.path,
  //         builder: (context, state) => entry.builder(context),
  //       );
  //     }).toList(),
  //   );
  // }

  void registerRoute(RouteEntry entry) {
    _routes.add(entry);
    _updateRouter();
    notifyListeners(); // Thông báo UI cập nhật
  }

  void registerRoutes(List<RouteEntry> entries) {
    _routes.addAll(entries);
    _updateRouter();
  }

  void _updateRouter() {
    protectedRoutes = _routes
        .where((element) => element.protected)
        .map((e) => e.path)
        .toSet();
    _router = GoRouter(
      navigatorKey: navigatorKey, // Thêm navigatorKey vào GoRouter
      initialLocation: '/',
      redirect: AppRouterGuard.guard3,
      debugLogDiagnostics: false,
      routes: _routes.map((entry) {
        return GoRoute(
          path: entry.path,
          builder: (context, state) => entry.builder(context, state),
        );
      }).toList(),
    );
  }

  // GoRouter get router => _router;

  // static void setUpDependencies() {
  //   Dependencies().registerFactory<RouterService>(
  //     () => RouterService(),
  //   );
  // }
  //
  GoRouter get router => Dependencies().getIt<RouterService>()._router;

  /// Lấy NavigatorState hiện tại từ GlobalKey
  static NavigatorState? get currentNavigator => navigatorKey.currentState;

  /// Lấy BuildContext hiện tại từ NavigatorState
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate đến route mới mà không cần BuildContext
  static void navigateTo(String path, {Object? extra}) {
    if (currentContext != null) {
      GoRouter.of(currentContext!).go(path, extra: extra);
    }
  }

  /// Push route mới mà không cần BuildContext
  static void pushTo(String path, {Object? extra}) {
    if (currentContext != null) {
      GoRouter.of(currentContext!).push(path, extra: extra);
    }
  }

  /// Pop route hiện tại mà không cần BuildContext
  static void pop([Object? result]) {
    currentNavigator?.pop(result);
  }

  /// Push và replace route hiện tại mà không cần BuildContext
  static void pushReplacement(String path, {Object? extra}) {
    if (currentContext != null) {
      GoRouter.of(currentContext!).pushReplacement(path, extra: extra);
    }
  }

  /// Khôi phục route đã lưu sau khi đăng nhập thành công
  static void restoreSavedRoute() {
    AppRouterGuard.restoreRouteWithData();
  }

  /// Tự động restore route và trigger callback
  static void autoRestoreAfterLogin() {
    AppRouterGuard.restoreRouteWithData();
    _onAuthStateChanged?.call();
  }

  /// Lấy thông tin về route đã lưu
  static Map<String, dynamic>? getSavedRouteInfo() {
    return AppRouterGuard.getSavedRouteInfo();
  }

  /// Xóa route đã lưu
  static void clearSavedRoute() {
    AppRouterGuard.clearSavedRoute();
  }
}

class AppRouterGuard {
  /// Lưu toàn bộ state của route bị chặn để khôi phục sau khi đăng nhập
  static GoRouterState? _savedRouteState;

  /// Flag để track xem có đang trong quá trình auto-restore không
  static bool _isAutoRestoring = false;

  /// Stream controller để listen auth state changes
  static StreamController<bool>? _authStateController;

  /// Timer để debounce auth state changes
  static Timer? _debounceTimer;

  /// Timer để cleanup saved route sau timeout
  static Timer? _cleanupTimer;

  /// Configuration
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _savedRouteTimeout =
      Duration(minutes: 30); // Auto cleanup sau 30 phút

  /// Initialize auto-restore listener
  static void initializeAutoRestore() {
    // Dispose existing resources first
    dispose();

    _authStateController = StreamController<bool>.broadcast();

    // Listen to auth state changes với debouncing
    _authStateController!.stream.listen((isLoggedIn) {
      _handleAuthStateChange(isLoggedIn);
    });
  }

  /// Handle auth state change với debouncing và optimization
  static void _handleAuthStateChange(bool isLoggedIn) {
    if (!_autoRestoreEnabled) return; // Skip nếu disabled

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Debounce multiple rapid auth state changes
    _debounceTimer = Timer(_debounceDelay, () {
      if (isLoggedIn && _savedRouteState != null && !_isAutoRestoring) {
        _performAutoRestore();
      } else if (!isLoggedIn) {
        // Clear saved route khi logout để tiết kiệm memory
        clearSavedRoute();
      }
    });
  }

  /// Perform auto-restore với error handling và timeout
  static void _performAutoRestore() {
    if (_isAutoRestoring) return; // Prevent multiple concurrent restores

    _isAutoRestoring = true;

    // Set timeout để tự động cleanup nếu restore bị stuck
    _cleanupTimer = Timer(_savedRouteTimeout, () {
      _isAutoRestoring = false;
      clearSavedRoute();
    });

    // Sử dụng microtask để tối ưu hơn Future.delayed
    Future.microtask(() {
      try {
        restoreRouteWithData();
      } catch (e) {
        // Log error nhưng không crash app
        RouterLogger.error('Auto-restore error: $e');
      } finally {
        _isAutoRestoring = false;
        _cleanupTimer?.cancel();
      }
    });
  }

  /// Notify auth state change - gọi từ AuthService
  static void notifyAuthStateChanged(bool isLoggedIn) {
    _authStateController?.add(isLoggedIn);
  }

  /// Cleanup resources và timers
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    _authStateController?.close();
    _authStateController = null;

    _savedRouteState = null;
    _isAutoRestoring = false;
  }

  static Future<String?> guard3(
    BuildContext context,
    GoRouterState state,
  ) async {
    final authService = Dependencies().getIt<AuthService>();
    final isLoggedIn =
        await authService.isLoggedIn(); // Kiểm tra trạng thái đăng nhập
    final String location = state.matchedLocation
        .split('?')
        .first; // location hiện tại : Bỏ query params

    final String lastAttemptedRoute =
        authService.lastAttemptedRoute ?? ''; // location cuối cùng
    authService.lastAttemptedRoute = location;

    if (!RouterService.protectedRoutes.contains(location)) {
      if (!RouterService.protectedRoutes.contains(lastAttemptedRoute)) {
        authService.loginSuccessAttemptedRoute = null;
        _savedRouteState = null; // Xóa saved state khi không cần bảo vệ
      }
      return null;
    } else {
      if (isLoggedIn) {
        return null;
      } else {
        // Lưu toàn bộ route state (bao gồm cả data) để khôi phục sau
        _savedRouteState = state;
        authService.loginSuccessAttemptedRoute = location;
        return AuthService.loginRouter;
      }
    }
  }

  /// Khôi phục route với toàn bộ data sau khi đăng nhập thành công
  static void restoreRouteWithData() {
    if (_savedRouteState != null) {
      final state = _savedRouteState!;
      _savedRouteState = null; // Clear saved state

      // Xây dựng lại URL với query parameters
      String fullPath = state.matchedLocation;
      if (state.uri.queryParameters.isNotEmpty) {
        final queryString = state.uri.queryParameters.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        fullPath += '?$queryString';
      }

      // Navigate với extra data
      RouterService.navigateTo(fullPath, extra: state.extra);
    }
  }

  /// Lấy thông tin về route đã lưu
  static Map<String, dynamic>? getSavedRouteInfo() {
    if (_savedRouteState == null) return null;

    return {
      'path': _savedRouteState!.matchedLocation,
      'pathParameters': _savedRouteState!.pathParameters,
      'queryParameters': _savedRouteState!.uri.queryParameters,
      'extra': _savedRouteState!.extra,
      'fullPath': _savedRouteState!.fullPath,
    };
  }

  /// Xóa route đã lưu
  static void clearSavedRoute() {
    _savedRouteState = null;
    _cleanupTimer?.cancel();
  }

  /// Performance monitoring
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'hasStreamController': _authStateController != null,
      'hasSavedRoute': _savedRouteState != null,
      'isAutoRestoring': _isAutoRestoring,
      'hasDebounceTimer': _debounceTimer != null && _debounceTimer!.isActive,
      'hasCleanupTimer': _cleanupTimer != null && _cleanupTimer!.isActive,
      'memoryUsage': {
        'savedRouteState': _savedRouteState != null ? 'allocated' : 'null',
        'streamController': _authStateController != null ? 'allocated' : 'null',
      }
    };
  }

  /// Enable/disable auto-restore (để test performance impact)
  static bool _autoRestoreEnabled = true;

  static void setAutoRestoreEnabled(bool enabled) {
    _autoRestoreEnabled = enabled;
    if (!enabled) {
      dispose(); // Clean up nếu disable
    }
  }

  static bool get isAutoRestoreEnabled => _autoRestoreEnabled;
}

class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({
    required LocalKey super.key,
    required super.child,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curveTween = CurveTween(curve: Curves.easeIn);
            return FadeTransition(
              opacity: animation.drive(curveTween),
              child: child,
            );
          },
        );
}
