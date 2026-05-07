import 'package:flutter/material.dart';
import '../../data/repositories/firebase_driver_order_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_orders_state.dart';
import '../cubit/driver_location_cubit.dart';
import '../cubit/driver_location_state.dart';
import '../../../../../core/services/location_service.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'driver_1';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DriverOrdersCubit(
            repository: FirebaseDriverOrderRepository(),
            driverId: driverId,
          ),
        ),
        BlocProvider(
          create: (context) => DriverLocationCubit(
            locationService: LocationService(),
            repository: FirebaseDriverOrderRepository(),
            driverId: driverId,
          )..checkPermissions(),
        ),
      ],
      child: const _DriverDashboardView(),
    );
  }
}

class _DriverDashboardView extends StatelessWidget {
  const _DriverDashboardView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DriverOrdersCubit, DriverOrdersState>(
          listener: (context, state) {
            if (state is DriverOrdersLoaded) {
              final isOnline = state.driver?.isAvailable == true;
              final hasActiveOrder = state.currentOrder != null;

              if (isOnline || hasActiveOrder) {
                context.read<DriverLocationCubit>().startTracking();
              } else {
                context.read<DriverLocationCubit>().stopTracking();
              }
            }
          },
        ),
        BlocListener<DriverLocationCubit, DriverLocationState>(
          listener: (context, state) {
            if (state is DriverLocationError) {
              Fluttertoast.showToast(msg: state.message, backgroundColor: Colors.red);
            }
          },
        ),
      ],
      child: Scaffold(
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
                      onChanged: (val) async {
                        if (val) {
                          // Check permission before going online
                          final locState = context.read<DriverLocationCubit>().state;
                          if (locState is DriverLocationPermissionRequired || locState is DriverLocationDisabled) {
                            Fluttertoast.showToast(msg: 'Location permission required to go online');
                            context.read<DriverLocationCubit>().requestPermission();
                            return;
                          }
                        }
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
        body: Column(
          children: [
            _buildLocationStatus(),
            Expanded(
              child: BlocConsumer<DriverOrdersCubit, DriverOrdersState>(
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
    ),
  ],
),
      ),
    );
  }

  Widget _buildLocationStatus() {
    return BlocBuilder<DriverLocationCubit, DriverLocationState>(
      builder: (context, state) {
        Color bgColor = Colors.grey.shade200;
        String text = 'Checking Location...';
        IconData icon = Icons.location_searching;
        bool showAction = false;

        if (state is DriverLocationActive) {
          bgColor = Colors.green.shade50;
          text = 'Live Location Active';
          icon = Icons.location_on;
        } else if (state is DriverLocationInactive) {
          bgColor = Colors.blue.shade50;
          text = 'Location Ready (Standby)';
          icon = Icons.location_on_outlined;
        } else if (state is DriverLocationPermissionRequired) {
          bgColor = Colors.orange.shade50;
          text = 'Location Permission Required';
          icon = Icons.location_off;
          showAction = true;
        } else if (state is DriverLocationDisabled) {
          bgColor = Colors.red.shade50;
          text = 'Location Services Disabled';
          icon = Icons.location_disabled;
          showAction = true;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: bgColor,
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
              if (showAction)
                TextButton(
                  onPressed: () {
                    context.read<DriverLocationCubit>().requestPermission();
                  },
                  child: const Text('Grant', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}
