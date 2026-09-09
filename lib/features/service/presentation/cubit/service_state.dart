import 'package:equatable/equatable.dart';

import '../../domain/entities/service.dart';

abstract class ServiceState extends Equatable {
  const ServiceState();

  @override
  List<Object?> get props => [];
}

class ServiceInitial extends ServiceState {
  const ServiceInitial();
}

class ServiceLoading extends ServiceState {
  const ServiceLoading();
}

class ServiceLoaded extends ServiceState {
  const ServiceLoaded(this.services);

  final List<Service> services;

  @override
  List<Object?> get props => [services];
}

class ServiceError extends ServiceState {
  const ServiceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
