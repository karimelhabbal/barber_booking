import 'package:equatable/equatable.dart';

class AvailableSlot extends Equatable {
  final DateTime start;
  final DateTime end;

  const AvailableSlot({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}
