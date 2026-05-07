import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/repositories/firebase_restaurant_order_repository.dart';
import '../cubit/restaurant_orders_cubit.dart';
import '../cubit/restaurant_orders_state.dart';
import 'package:intl/intl.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../auth/presentation/cubit/auth_state.dart';

class RestaurantDashboardPage extends StatelessWidget {
  const RestaurantDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String restaurantId = 'restaurant_demo_1';
    if (authState is Authenticated) {
      restaurantId = authState.user.restaurantId ?? authState.user.uid;
    }

    return BlocProvider(
      create: (context) => RestaurantOrdersCubit(
        repository: FirebaseRestaurantOrderRepository(),
        restaurantId: restaurantId,
      ),
      child: const _RestaurantDashboardView(),
    );
  }
}

class _RestaurantDashboardView extends StatelessWidget {
  const _RestaurantDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        actions: [
          BlocBuilder<RestaurantOrdersCubit, RestaurantOrdersState>(
            builder: (context, state) {
              bool isOpen = false;
              if (state is RestaurantOrdersLoaded) isOpen = state.isOpen;

              return Switch(
                value: isOpen,
                onChanged: (val) {
                  context.read<RestaurantOrdersCubit>().toggleOpenStatus(val);
                },
                activeTrackColor: Colors.green,
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<RestaurantOrdersCubit, RestaurantOrdersState>(
        listener: (context, state) {
          if (state is RestaurantOrdersError) {
            Fluttertoast.showToast(msg: state.message, backgroundColor: Colors.red, textColor: Colors.white);
          }
        },
        builder: (context, state) {
          if (state is RestaurantOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RestaurantOrdersLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                // Since it's a stream, we just wait a bit for UX
                await Future.delayed(const Duration(seconds: 1));
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Text("Today's Revenue", style: TextStyle(fontSize: 18, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text('\$${state.todayRevenue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Incoming Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (state.orders.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('No orders yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = state.orders[index];
                          final timeStr = DateFormat.Hm().format(order.createdAt);
                          
                          Color statusColor = Colors.grey;
                          if (order.status == 'confirmed') statusColor = Colors.orange;
                          if (order.status == 'preparing') statusColor = Colors.blue;
                          if (order.status == 'readyForPickup') statusColor = Colors.purple;
                          if (order.status == 'onTheWay') statusColor = Colors.teal;
                          if (order.status == 'delivered') statusColor = Colors.green;
                          if (order.status == 'rejected') statusColor = Colors.red;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: () {
                                context.push('/restaurant/orders/${order.id}', extra: order);
                              },
                              leading: CircleAvatar(
                                backgroundColor: statusColor,
                                child: const Icon(Icons.receipt, color: Colors.white),
                              ),
                              title: Text('Order #${order.id.substring(0, min(order.id.length, 6)).toUpperCase()}'),
                              subtitle: Text('${order.items.length} items • \$${order.total.toStringAsFixed(2)} • $timeStr'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(order.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                        childCount: state.orders.length,
                      ),
                    ),
                ],
              ),
            );
          }

          return const Center(child: Text('Something went wrong.'));
        },
      ),
    );
  }
}

int min(int a, int b) => a < b ? a : b;
