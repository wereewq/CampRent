import 'package:go_router/go_router.dart';
import '../models/role.dart';
import '../screens/admin_screen.dart';
import '../screens/equipment_list_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/instructor_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_rentals_screen.dart';
import '../screens/register_screen.dart';
import '../screens/rental_order_screen.dart';
import '../state/auth_notifier.dart';
import '../widgets/adaptive_scaffold.dart';

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/catalog',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) {
        return '/catalog';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      ShellRoute(
        builder: (context, state, child) {
          final loc = state.uri.path;
          int idx = 0;
          if (loc.startsWith('/my-rentals')) {
            idx = 1;
          }
          if (loc.startsWith('/instructor')) {
            idx = 1;
          }
          if (loc.startsWith('/admin-panel')) {
            idx = 2;
          }
          return AdaptiveScaffold(currentIndex: idx, child: child);
        },
        routes: [
          GoRoute(
            path: '/catalog',
            builder: (c, s) => const EquipmentListScreen(),
          ),
          GoRoute(
            path: '/rent/:id',
            builder: (c, s) => RentalOrderScreen(
              equipmentId: int.parse(s.pathParameters['id'] ?? '1'),
            ),
          ),
          GoRoute(
            path: '/my-rentals',
            builder: (c, s) => const MyRentalsScreen(),
          ),
          GoRoute(
            path: '/instructor',
            redirect: (context, state) =>
                auth.has(Role.librarian) ? null : '/forbidden',
            builder: (c, s) => const InstructorScreen(),
          ),
          GoRoute(
            path: '/admin-panel',
            redirect: (context, state) =>
                auth.has(Role.admin) ? null : '/forbidden',
            builder: (c, s) => const AdminScreen(),
          ),
        ],
      ),
    ],
  );
}
