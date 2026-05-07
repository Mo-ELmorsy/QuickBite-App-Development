import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/customer/cart/presentation/bloc/cart_bloc.dart';
import 'firebase_options.dart';
import 'core/routes/app_router.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables if needed
  // await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Stripe
  // Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  runApp(const QuickBiteApp());
}

class QuickBiteApp extends StatelessWidget {
  const QuickBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(repository: FirebaseAuthRepository())),
        BlocProvider(create: (_) => CartBloc()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            AppRouter.router.go('/login');
          } else if (state is Authenticated) {
            final role = state.user.role;
            if (role == 'restaurant') {
              AppRouter.router.go('/restaurant/dashboard');
            } else if (role == 'driver') {
              AppRouter.router.go('/driver/dashboard');
            } else {
              AppRouter.router.go('/customer_home');
            }
          }
        },
        child: MaterialApp.router(
        title: 'QuickBite',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
