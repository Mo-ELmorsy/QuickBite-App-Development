import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/services/location_service.dart';
import '../../domain/repositories/driver_order_repository.dart';
import 'driver_location_state.dart';

class DriverLocationCubit extends Cubit<DriverLocationState> {
  final LocationService _locationService;
  final DriverOrderRepository _repository;
  final String _driverId;
  StreamSubscription<Position>? _positionSubscription;

  DriverLocationCubit({
    required LocationService locationService,
    required DriverOrderRepository repository,
    required String driverId,
  })  : _locationService = locationService,
        _repository = repository,
        _driverId = driverId,
        super(DriverLocationInitial());

  Future<void> checkPermissions() async {
    final enabled = await _locationService.isLocationServiceEnabled();
    if (!enabled) {
      emit(DriverLocationDisabled());
      return;
    }

    final permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      emit(DriverLocationPermissionRequired());
    } else {
      emit(DriverLocationInactive());
    }
  }

  Future<void> requestPermission() async {
    final permission = await _locationService.requestPermission();
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      emit(DriverLocationPermissionRequired());
    } else {
      emit(DriverLocationInactive());
    }
  }

  void startTracking() async {
    final permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      emit(DriverLocationPermissionRequired());
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen(
      (position) {
        _repository.updateDriverLocation(
          _driverId, 
          position.latitude, 
          position.longitude
        );
        emit(DriverLocationActive());
      },
      onError: (error) {
        emit(DriverLocationError(error.toString()));
      },
    );
  }

  void stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    emit(DriverLocationInactive());
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
