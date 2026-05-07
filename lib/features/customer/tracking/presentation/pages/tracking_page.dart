import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../checkout/domain/entities/order_entity.dart';
import '../../../checkout/data/repositories/firebase_order_repository.dart';
import '../../../../driver/orders/domain/entities/driver_entity.dart';
import '../../../../driver/orders/data/models/driver_model.dart';
import '../../../../../core/services/directions_service.dart';

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
  late final DirectionsService _directionsService;
  
  Set<Polyline> _polylines = {};
  String _distance = '';
  String _duration = '';
  LatLng? _lastOrigin;
  LatLng? _lastDestination;
  

  @override
  void initState() {
    super.initState();
    _repository = FirebaseOrderRepository();
    _orderStream = _repository.getOrderStream(widget.orderId);
    _directionsService = DirectionsService();
  }

  Future<void> _updateRoute(LatLng origin, LatLng destination) async {
    // Avoid redundant API calls if locations haven't changed much
    if (_lastOrigin == origin && _lastDestination == destination) return;
    
    final route = await _directionsService.getRoutePolyline(
      origin: origin,
      destination: destination,
    );

    if (route != null && mounted) {
      setState(() {
        _lastOrigin = origin;
        _lastDestination = destination;
        _distance = route.distanceText;
        _duration = route.durationText;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: route.points,
            color: Colors.orange,
            width: 5,
          ),
        };
      });

      // Fit camera to bounds
      final GoogleMapController controller = await _controller.future;
      LatLngBounds bounds;
      if (origin.latitude > destination.latitude) {
        bounds = LatLngBounds(southwest: destination, northeast: origin);
      } else {
        bounds = LatLngBounds(southwest: origin, northeast: destination);
      }
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  int _getStepFromStatus(String status) {
    switch (status) {
      case 'confirmed': return 0;
      case 'preparing': return 1;
      case 'readyForPickup': return 1;
      case 'onTheWay': return 2;
      case 'delivered': return 3;
      default: return 0;
    }
  }

  Stream<DriverEntity?> _getDriverStream(String? driverId) {
    if (driverId == null) return Stream.value(null);
    return FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DriverModel.fromFirestore(doc);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<OrderEntity>(
        stream: _orderStream,
        builder: (context, orderSnapshot) {
          if (orderSnapshot.hasError) {
            return Center(child: Text('Error loading order: ${orderSnapshot.error}'));
          }

          if (!orderSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = orderSnapshot.data!;
          final currentStep = _getStepFromStatus(order.status);

          return StreamBuilder<DriverEntity?>(
            stream: _getDriverStream(order.driverId),
            builder: (context, driverSnapshot) {
              final driver = driverSnapshot.data;
              
              LatLng driverLatLng = const LatLng(37.7749, -122.4194); // Mock default
              if (driver?.latitude != null && driver?.longitude != null) {
                driverLatLng = LatLng(driver!.latitude!, driver.longitude!);
              }

              // Locations for route
              final restaurantLatLng = const LatLng(37.7749, -122.4194); // Mock restaurant
              final customerLatLng = const LatLng(37.7849, -122.4094); // Mock customer

              // Determine route points
              if (order.status == 'onTheWay') {
                _updateRoute(driverLatLng, customerLatLng);
              } else if (order.status != 'delivered') {
                _updateRoute(restaurantLatLng, customerLatLng);
              }

              return Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(target: driverLatLng, zoom: 14.4746),
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    polylines: _polylines,
                    markers: {
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: driverLatLng,
                        infoWindow: const InfoWindow(title: 'Driver Location'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      ),
                      Marker(
                        markerId: const MarkerId('restaurant'),
                        position: restaurantLatLng,
                        infoWindow: const InfoWindow(title: 'Restaurant'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      ),
                      Marker(
                        markerId: const MarkerId('customer'),
                        position: customerLatLng,
                        infoWindow: const InfoWindow(title: 'Your Location'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
                            currentStep == 3 ? 'Order Delivered' : (order.status == 'onTheWay' ? 'Driver is on the way' : 'Preparing your order'), 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Status: ${order.status.toUpperCase()}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              if (_duration.isNotEmpty)
                                Text('ETA: $_duration ($_distance)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                          if (const String.fromEnvironment('GOOGLE_MAPS_API_KEY').isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text('Route unavailable, showing live location only.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
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
                                    Text(driver?.name ?? (order.driverId != null ? 'Driver Assigned' : 'Assigning Driver...'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(driver?.vehicle ?? 'Vehicle Details Pending', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              if (driver != null)
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
          );
        }
      ),
    );
  }
}
