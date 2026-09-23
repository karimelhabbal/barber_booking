part of 'barber_cubit.dart';

abstract class BarberState extends Equatable {
  const BarberState();

  @override
  List<Object?> get props => [];
}

class BarberInitial extends BarberState {
  const BarberInitial();
}

class BarberProfileLoading extends BarberState {
  const BarberProfileLoading();
}

class BarberProfileLoaded extends BarberState {
  const BarberProfileLoaded(this.barber);

  final Barber barber;

  @override
  List<Object?> get props => [barber];
}

class BarberLoading extends BarberState {
  const BarberLoading();
}

class BarberLoaded extends BarberState {
  const BarberLoaded(this.barbers);

  final List<Barber> barbers;

  @override
  List<Object?> get props => [barbers];
}

class BarberCreating extends BarberState {
  const BarberCreating();
}

class BarberCreated extends BarberState {
  const BarberCreated(this.barber);

  final Barber barber;

  @override
  List<Object?> get props => [barber];
}

class BarberUpdating extends BarberState {
  const BarberUpdating();
}

class BarberUpdated extends BarberState {
  const BarberUpdated(this.barber);

  final Barber barber;

  @override
  List<Object?> get props => [barber];
}

class BarberDeleting extends BarberState {
  const BarberDeleting(this.barberId);

  final String barberId;

  @override
  List<Object?> get props => [barberId];
}

class BarberDeleted extends BarberState {
  const BarberDeleted(this.barberId);

  final String barberId;

  @override
  List<Object?> get props => [barberId];
}

class BarberError extends BarberState {
  const BarberError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class BarberCandidatesLoading extends BarberState {
  const BarberCandidatesLoading();
}

class BarberCandidatesLoaded extends BarberState {
  const BarberCandidatesLoaded(this.candidates);

  final List<BarberCandidate> candidates;

  @override
  List<Object?> get props => [candidates];
}
