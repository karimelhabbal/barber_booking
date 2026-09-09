import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final String id;
  final String barberShopId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Service({
    required this.id,
    required this.barberShopId,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    barberShopId,
    name,
    description,
    durationMinutes,
    price,
    isActive,
    createdAt,
    updatedAt,
  ];
}
