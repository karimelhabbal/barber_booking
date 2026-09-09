import 'package:equatable/equatable.dart';

class BarberShop extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String? phone;
  final String? address;
  final String? description;
  final String? imageUrl;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BarberShop({
    required this.id,
    required this.name,
    required this.ownerId,
    this.phone,
    this.address,
    this.description,
    this.imageUrl,
    required this.timezone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    ownerId,
    phone,
    address,
    description,
    imageUrl,
    timezone,
    isActive,
    createdAt,
    updatedAt,
  ];
}
