import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            Fluttertoast.showToast(msg: state.message, backgroundColor: Colors.red, textColor: Colors.white);
          }
          // Note: navigation based on role is handled by GoRouter's redirect logic globally 
          // based on authStateChanges instead of doing it locally here.
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fastfood, size: 80, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text('QuickBite', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 8),
                    const Text('Deliver happiness to your door', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 48),

                    if (state is AuthLoading)
                      const CircularProgressIndicator(color: Colors.orange)
                    else ...[
                      _buildGoogleButton(context),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR DEMO LOGIN', style: TextStyle(color: Colors.grey, fontSize: 12))),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDemoButton(context, 'customer', 'Continue as Customer', Colors.blue, Icons.person),
                      const SizedBox(height: 16),
                      _buildDemoButton(context, 'restaurant', 'Continue as Restaurant', Colors.purple, Icons.store),
                      const SizedBox(height: 16),
                      _buildDemoButton(context, 'driver', 'Continue as Driver', Colors.teal, Icons.directions_bike),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          context.read<AuthCubit>().signInWithGoogle();
        },
        icon: const Icon(Icons.login, color: Colors.orange), // Use simple icon for demo
        label: const Text('Sign in with Google', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDemoButton(BuildContext context, String role, String label, Color color, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          context.read<AuthCubit>().signInDemoAsRole(role);
        },
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
