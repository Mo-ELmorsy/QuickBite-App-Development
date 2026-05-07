import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../customer/checkout/domain/entities/order_entity.dart';
import '../../data/repositories/firebase_restaurant_order_repository.dart';
import '../cubit/restaurant_orders_cubit.dart';
import '../cubit/restaurant_orders_state.dart';

class RestaurantOrderDetailsPage extends StatelessWidget {
  final String orderId;

  const RestaurantOrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    // We can recreate the cubit or retrieve it. Since order details might be pushed, 
    // passing the existing cubit via BlocProvider.value is best, but go_router makes it tricky without shell routes.
    // Instead, we just instantiate a new cubit for this specific order/restaurant if needed, 
    // or better, since we have the order details passed or we can listen to the stream.
    // Wait, we need the Cubit to update status. 
    return BlocProvider(
      create: (context) => RestaurantOrdersCubit(
        repository: FirebaseRestaurantOrderRepository(),
        restaurantId: 'rest_1', // TODO: Auth
      ),
      child: _RestaurantOrderDetailsView(orderId: orderId),
    );
  }
}

class _RestaurantOrderDetailsView extends StatelessWidget {
  final String orderId;

  const _RestaurantOrderDetailsView({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantOrdersCubit, RestaurantOrdersState>(
      builder: (context, state) {
        if (state is RestaurantOrdersLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is RestaurantOrdersLoaded) {
          // Find the specific order from the stream
          final order = state.orders.where((o) => o.id == orderId).firstOrNull;
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
                  const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Card(
                    child: ListTile(
                      title: Text('${item.quantity}x ${item.name}'),
                      subtitle: item.specialInstructions.isNotEmpty ? Text('Note: ${item.specialInstructions}', style: const TextStyle(color: Colors.red)) : null,
                      trailing: Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                    ),
                  )),
                  const SizedBox(height: 24),
                  const Text('Customer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Customer Name (Mock)'),
                      subtitle: Text(order.deliveryAddress),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('\$${order.subtotal.toStringAsFixed(2)}')]),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Delivery Fee'), Text('\$${order.deliveryFee.toStringAsFixed(2)}')]),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Discount'), Text('-\$${order.discount.toStringAsFixed(2)}')]),
                          const Divider(height: 24),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            bottomNavigationBar: _buildActionButtons(context, order),
          );
        }

        return const Scaffold(body: Center(child: Text('Something went wrong')));
      },
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color = Colors.grey;
    if (status == 'confirmed') color = Colors.orange;
    if (status == 'preparing') color = Colors.blue;
    if (status == 'readyForPickup') color = Colors.purple;
    if (status == 'onTheWay') color = Colors.teal;
    if (status == 'delivered') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Text('Status: ${status.toUpperCase()}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget? _buildActionButtons(BuildContext context, OrderEntity order) {
    final cubit = context.read<RestaurantOrdersCubit>();
    
    if (order.status == 'confirmed') {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => cubit.rejectOrder(order.id),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => cubit.acceptOrder(order.id),
                child: const Text('Accept'),
              ),
            ),
          ],
        ),
      );
    } else if (order.status == 'preparing') {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => cubit.markReadyForPickup(order.id),
          child: const Text('Mark Ready for Pickup'),
        ),
      );
    } else if (order.status == 'readyForPickup') {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: const ElevatedButton(
          onPressed: null,
          child: Text('Waiting for Driver...'),
        ),
      );
    }
    
    return null; // Read-only for other states
  }
}
