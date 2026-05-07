import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../domain/entities/order_entity.dart';
import '../../data/repositories/firebase_order_repository.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CheckoutCubit(FirebaseOrderRepository()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, checkoutState) {
            if (checkoutState is CheckoutFailure) {
              Fluttertoast.showToast(
                msg: checkoutState.message,
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            } else if (checkoutState is CheckoutSuccess) {
              Fluttertoast.showToast(
                msg: 'Order placed successfully!',
                backgroundColor: Colors.green,
                textColor: Colors.white,
              );
              context.read<CartBloc>().add(ClearCart());
              context.go('/tracking/${checkoutState.orderId}');
            }
          },
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartUpdated) {
                final cartState = state;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.orange),
                          title: const Text('Home'),
                          subtitle: const Text('123 Main Street, Apt 4B'),
                          trailing: TextButton(onPressed: () {}, child: const Text('Change')),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.credit_card, color: Colors.orange),
                          title: const Text('Credit Card'),
                          subtitle: const Text('**** **** **** 4242'),
                          trailing: TextButton(onPressed: () {}, child: const Text('Change')),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ...cartState.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.quantity}x ${item.name}'),
                                    Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                                  ],
                                ),
                              )),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal'),
                                  Text('\$${cartState.subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Delivery Fee'),
                                  Text('\$${cartState.deliveryFee.toStringAsFixed(2)}'),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('\$${cartState.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            if (cartState is CartUpdated) {
              return BlocBuilder<CheckoutCubit, CheckoutState>(
                builder: (context, checkoutState) {
                  final isLoading = checkoutState is CheckoutLoading;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading ? null : () {
                        final order = OrderEntity(
                          id: '', // Empty ID tells Firestore to generate one
                          userId: FirebaseAuth.instance.currentUser?.uid ?? 'user_123',
                          restaurantId: 'restaurant_demo_1', // Mock restaurant ID
                          items: cartState.items,
                          status: 'confirmed',
                          subtotal: cartState.subtotal,
                          deliveryFee: cartState.deliveryFee,
                          discount: cartState.discount,
                          total: cartState.total,
                          paymentMethod: 'Credit Card',
                          deliveryAddress: '123 Main Street, Apt 4B',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          timestamps: {
                            'confirmed': DateTime.now().toIso8601String(),
                            'preparing': null,
                            'onTheWay': null,
                            'delivered': null,
                          },
                        );
                        context.read<CheckoutCubit>().placeOrder(order);
                      },
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
