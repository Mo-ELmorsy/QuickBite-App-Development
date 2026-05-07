import 'package:equatable/equatable.dart';

abstract class DriverLocationState extends Equatable {
  const DriverLocationState();

  @override
  List<Object?> get props => [];
}

class DriverLocationInitial extends DriverLocationState {}

class DriverLocationLoading extends DriverLocationState {}

class DriverLocationActive extends DriverLocationState {}

class DriverLocationInactive extends DriverLocationState {}

class DriverLocationPermissionRequired extends DriverLocationState {}

class DriverLocationDisabled extends DriverLocationState {}

class DriverLocationError extends DriverLocationState {
  final String message;
  const DriverLocationError(this.message);

  @override
  List<Object?> get props => [message];
}
