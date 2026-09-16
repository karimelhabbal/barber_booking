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

class ServiceCreating extends ServiceState {
  const ServiceCreating();
}

class ServiceCreated extends ServiceState {
  const ServiceCreated(this.service);

  final Service service;

  @override
  List<Object?> get props => [service];
}

class ServiceUpdating extends ServiceState {
  const ServiceUpdating(this.service);

  final Service service;

  @override
  List<Object?> get props => [service];
}

class ServiceUpdated extends ServiceState {
  const ServiceUpdated(this.service);

  final Service service;

  @override
  List<Object?> get props => [service];
}

class ServiceDeleting extends ServiceState {
  const ServiceDeleting(this.serviceId);

  final String serviceId;

  @override
  List<Object?> get props => [serviceId];
}

class ServiceDeleted extends ServiceState {
  const ServiceDeleted(this.serviceId);

  final String serviceId;

  @override
  List<Object?> get props => [serviceId];
}
