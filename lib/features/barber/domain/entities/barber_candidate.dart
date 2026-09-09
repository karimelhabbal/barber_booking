import 'package:equatable/equatable.dart';

class BarberCandidate extends Equatable {
  final String id;
  final String name;
  final String? phone;

  const BarberCandidate({required this.id, required this.name, this.phone});

  @override
  List<Object?> get props => [id, name, phone];
}
