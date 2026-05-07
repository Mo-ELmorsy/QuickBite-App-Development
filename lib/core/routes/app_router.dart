import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/customer/home/presentation/pages/customer_home_page.dart';
import '../../features/restaurant/orders/presentation/pages/restaurant_dashboard_page.dart';
import '../../features/restaurant/orders/presentation/pages/restaurant_order_details_page.dart';
import '../../features/driver/orders/presentation/pages/driver_dashboard_page.dart';
import '../../features/driver/orders/presentation/pages/driver_order_details_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/customer/cart/presentation/pages/cart_page.dart';
import '../../features/customer/restaurant/presentation/pages/restaurant_menu_page.dart';
import '../../features/customer/checkout/presentation/pages/checkout_page.dart';
import '../../features/customer/tracking/presentation/pages/tracking_page.dart';
import '../../features/restaurant/menu/presentation/pages/restaurant_menu_management_page.dart';
import '../../features/restaurant/menu/presentation/pages/add_edit_menu_item_page.dart';
import '../../features/restaurant/menu/domain/entities/menu_item_entity.dart';

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
        path: '/restaurant/menu',
        builder: (context, state) => const RestaurantMenuManagementPage(),
      ),
      GoRoute(
        path: '/restaurant/menu/add',
        builder: (context, state) => const AddEditMenuItemPage(),
      ),
      GoRoute(
        path: '/restaurant/menu/edit/:itemId',
        builder: (context, state) {
          final item = state.extra as MenuItemEntity?;
          return AddEditMenuItemPage(item: item);
        },
      ),
      GoRoute(
        path: '/driver_home',
        builder: (context, state) => const DriverDashboardPage(),
      ),
      GoRoute(
        path: '/driver/dashboard',
        builder: (context, state) => const DriverDashboardPage(),
      ),
      GoRoute(
        path: '/driver/orders/:orderId',
        builder: (context, state) {
          final id = state.pathParameters['orderId'] ?? '';
          return DriverOrderDetailsPage(orderId: id);
        },
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
