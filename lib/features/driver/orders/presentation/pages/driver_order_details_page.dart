import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../customer/checkout/domain/entities/order_entity.dart';
import '../../data/repositories/firebase_driver_order_repository.dart';
import '../cubit/driver_orders_cubit.dart';
import '../cubit/driver_orders_state.dart';

class DriverOrderDetailsPage extends StatelessWidget {
  final String orderId;

  const DriverOrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'driver_1';

    return BlocProvider(
      create: (context) => DriverOrdersCubit(
        repository: FirebaseDriverOrderRepository(),
        driverId: driverId,
      ),
      child: _DriverOrderDetailsView(orderId: orderId),
    );
  }
}

class _DriverOrderDetailsView extends StatelessWidget {
  final String orderId;

  const _DriverOrderDetailsView({required this.orderId});

  Future<void> _launchMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverOrdersCubit, DriverOrdersState>(
      builder: (context, state) {
        if (state is DriverOrdersLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is DriverOrdersLoaded) {
          // Check if it's the active order or one of the available ones
          OrderEntity? order;
          if (state.currentOrder?.id == orderId) {
            order = state.currentOrder;
          } else {
            order = state.availableOrders.where((o) => o.id == orderId).firstOrNull;
          }

          if (order == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Order Details')),
              body: const Center(child: Text('Order not found')),
            );
          }

          return Scaffold(
            appBar: AppBar(title: Text('Order #${order.id.substring(0, 6).toUpperCase()}')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(order.status),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.store, color: Colors.white)),
                      title: const Text('Restaurant Location (Mock)'),
                      subtitle: const Text('123 Food Street'),
                      trailing: IconButton(
                        icon: const Icon(Icons.navigation, color: Colors.blue),
                        onPressed: () => _launchMaps(37.7749, -122.4194),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white)),
                      title: const Text('Customer Location'),
                      subtitle: Text(order.deliveryAddress),
                      trailing: IconButton(
                        icon: const Icon(Icons.navigation, color: Colors.blue),
                        onPressed: () => _launchMaps(37.7849, -122.4094),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Order Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => ListTile(
                    title: Text('${item.quantity}x ${item.name}'),
                    trailing: Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                  )),
                  const Divider(),
                  ListTile(
                    title: const Text('Delivery Fee (Your Earnings)'),
                    trailing: Text('\$${order.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  ListTile(
                    title: const Text('Total Customer Paid'),
                    trailing: Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            bottomNavigationBar: _buildActionButtons(context, order, state.driver?.id),
          );
        }

        return const Scaffold(body: Center(child: Text('Something went wrong')));
      },
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color = Colors.grey;
    if (status == 'readyForPickup') color = Colors.purple;
    if (status == 'onTheWay') color = Colors.teal;
    if (status == 'delivered') color = Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Text('Status: ${status.toUpperCase()}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget? _buildActionButtons(BuildContext context, OrderEntity order, String? currentDriverId) {
    final cubit = context.read<DriverOrdersCubit>();
    
    if (order.status == 'readyForPickup' && order.driverId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => cubit.acceptDelivery(order.id),
          child: const Text('Accept Delivery'),
        ),
      );
    } else if (order.status == 'readyForPickup' && order.driverId == currentDriverId) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => cubit.markPickedUp(order.id),
          child: const Text('Confirm Picked Up'),
        ),
      );
    } else if (order.status == 'onTheWay' && order.driverId == currentDriverId) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => cubit.markDelivered(order.id),
          child: const Text('Mark as Delivered'),
        ),
      );
    }
    
    return null;
  }
}
