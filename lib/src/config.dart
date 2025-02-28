part of '../router.dart';

/// Router Service quản lý toàn bộ navigation trong app
class RouterService extends ChangeNotifier {
  final List<RouteEntry> _routes = [];
  late GoRouter _router;

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
    protectedRoutes = _routes.where((element) => element.protected).map((e) => e.path).toSet();
    _router = GoRouter(
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
}

class AppRouterGuard {
  static Future<String?> guard3(
    BuildContext context,
    GoRouterState state,
  ) async {
    final authService = Dependencies().getIt<AuthService>();
    final isLoggedIn = await authService.isLoggedIn(); // Kiểm tra trạng thái đăng nhập
    final String location = state.matchedLocation.split('?').first; // location hiện tại : Bỏ query params

    final String lastAttemptedRoute = authService.lastAttemptedRoute ?? ''; // location cuối cùng
    authService.lastAttemptedRoute = location;

    if (!RouterService.protectedRoutes.contains(location)) {
      if (!RouterService.protectedRoutes.contains(lastAttemptedRoute)) {
        authService.loginSuccessAttemptedRoute = null;
      }
      return null;
    } else {
      if (isLoggedIn) {
        return null;
      } else {
        authService.loginSuccessAttemptedRoute = location;
        return AuthService.loginRouter;
      }
    }
  }
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
