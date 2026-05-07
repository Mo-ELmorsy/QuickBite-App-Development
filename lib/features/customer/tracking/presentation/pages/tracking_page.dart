import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../checkout/domain/entities/order_entity.dart';
import '../../../checkout/data/repositories/firebase_order_repository.dart';

class TrackingPage extends StatefulWidget {
  final String orderId;

  const TrackingPage({super.key, required this.orderId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();
  late final FirebaseOrderRepository _repository;
  late final Stream<OrderEntity> _orderStream;
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _repository = FirebaseOrderRepository();
    _orderStream = _repository.getOrderStream(widget.orderId);
  }

  int _getStepFromStatus(String status) {
    switch (status) {
      case 'confirmed': return 0;
      case 'preparing': return 1;
      case 'onTheWay': return 2;
      case 'delivered': return 3;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<OrderEntity>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading order: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data!;
          final currentStep = _getStepFromStatus(order.status);

          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _initialPosition,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                markers: {
                  const Marker(
                    markerId: MarkerId('driver'),
                    position: LatLng(37.7749, -122.4194),
                    infoWindow: InfoWindow(title: 'Driver Location'),
                  ),
                },
              ),
              Positioned(
                top: 50,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => context.go('/customer_home'),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(2))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentStep == 3 ? 'Order Delivered' : 'Arriving in 15 mins', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      Text('Status: ${order.status.toUpperCase()}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.orange, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order.driverId ?? 'Assigning Driver...', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Text('Vehicle Details Pending', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Stepper(
                        physics: const NeverScrollableScrollPhysics(),
                        margin: EdgeInsets.zero,
                        controlsBuilder: (context, details) => const SizedBox.shrink(),
                        currentStep: currentStep,
                        steps: [
                          Step(title: const Text('Order Confirmed'), content: const SizedBox.shrink(), isActive: currentStep >= 0, state: currentStep > 0 ? StepState.complete : StepState.editing),
                          Step(title: const Text('Preparing your food'), content: const SizedBox.shrink(), isActive: currentStep >= 1, state: currentStep > 1 ? StepState.complete : (currentStep == 1 ? StepState.editing : StepState.indexed)),
                          Step(title: const Text('On the way'), content: const SizedBox.shrink(), isActive: currentStep >= 2, state: currentStep > 2 ? StepState.complete : (currentStep == 2 ? StepState.editing : StepState.indexed)),
                          Step(title: const Text('Delivered'), content: const SizedBox.shrink(), isActive: currentStep >= 3, state: currentStep == 3 ? StepState.complete : StepState.indexed),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        }
      ),
    );
  }
}
