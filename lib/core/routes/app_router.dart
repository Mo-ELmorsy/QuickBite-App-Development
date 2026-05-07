import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/customer/home/presentation/pages/customer_home_page.dart';
import '../../features/restaurant/orders/presentation/pages/restaurant_dashboard_page.dart';
import '../../features/restaurant/orders/presentation/pages/restaurant_order_details_page.dart';
import '../../features/driver/presentation/pages/driver_home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/customer/cart/presentation/pages/cart_page.dart';
import '../../features/customer/restaurant/presentation/pages/restaurant_menu_page.dart';
import '../../features/customer/checkout/presentation/pages/checkout_page.dart';
import '../../features/customer/tracking/presentation/pages/tracking_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/customer_home',
        builder: (context, state) => const CustomerHomePage(),
      ),
      GoRoute(
        path: '/restaurant_dashboard',
        builder: (context, state) => const RestaurantDashboardPage(),
      ),
      GoRoute(
        path: '/restaurant/dashboard',
        builder: (context, state) => const RestaurantDashboardPage(),
      ),
      GoRoute(
        path: '/restaurant/orders/:orderId',
        builder: (context, state) {
          final id = state.pathParameters['orderId'] ?? '';
          return RestaurantOrderDetailsPage(orderId: id);
        },
      ),
      GoRoute(
        path: '/driver_home',
        builder: (context, state) => const DriverHomePage(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DefaultTabController(
            length: 4,
            child: RestaurantMenuPage(restaurantId: id),
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TrackingPage(orderId: id);
        },
      ),
    ],
  );
}
