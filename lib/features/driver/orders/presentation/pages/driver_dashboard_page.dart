import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/firebase_driver_order_repository.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_orders_state.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'driver_1';

    return BlocProvider(
      create: (context) => DriverOrdersCubit(
        repository: FirebaseDriverOrderRepository(),
        driverId: driverId,
      ),
      child: const _DriverDashboardView(),
    );
  }
}

class _DriverDashboardView extends StatelessWidget {
  const _DriverDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          BlocBuilder<DriverOrdersCubit, DriverOrdersState>(
            builder: (context, state) {
              bool isAvailable = false;
              if (state is DriverOrdersLoaded && state.driver != null) {
                isAvailable = state.driver!.isAvailable;
              }

              return Row(
                children: [
                  Text(isAvailable ? 'Online' : 'Offline', style: TextStyle(color: isAvailable ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                  Switch(
                    value: isAvailable,
                    onChanged: (val) {
                      context.read<DriverOrdersCubit>().toggleAvailability(val);
                    },
                    activeTrackColor: Colors.green,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<DriverOrdersCubit, DriverOrdersState>(
        listener: (context, state) {
          if (state is DriverOrdersError) {
            Fluttertoast.showToast(msg: state.message, backgroundColor: Colors.red, textColor: Colors.white);
          }
        },
        builder: (context, state) {
          if (state is DriverOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DriverOrdersLoaded) {
            final activeOrder = state.currentOrder;
            final available = state.availableOrders;

            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Text("Today's Earnings", style: TextStyle(fontSize: 18, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text('\$${state.todayEarnings.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (activeOrder != null) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text('Current Active Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.orange.shade50,
                        child: ListTile(
                          onTap: () {
                            context.push('/driver/orders/${activeOrder.id}');
                          },
                          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.directions_bike, color: Colors.white)),
                          title: Text('Order #${activeOrder.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(activeOrder.status.toUpperCase(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Text('Available Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (available.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No available orders right now', style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = available[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: () {
                                context.push('/driver/orders/${order.id}');
                              },
                              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.shopping_bag, color: Colors.white)),
                              title: Text('Order #${order.id.substring(0, 6).toUpperCase()}'),
                              subtitle: Text('${order.items.length} items • \$${order.total.toStringAsFixed(2)}\nTo: ${order.deliveryAddress}'),
                              trailing: ElevatedButton(
                                onPressed: state.driver?.isAvailable == true && activeOrder == null
                                    ? () {
                                        context.read<DriverOrdersCubit>().acceptDelivery(order.id);
                                      }
                                    : null,
                                child: const Text('Accept'),
                              ),
                            ),
                          );
                        },
                        childCount: available.length,
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
