import 'package:equatable/equatable.dart';

class Barber extends Equatable {
  final String id;
  final String userId;
  final String barberShopId;
  final String name;
  final String? phone;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Barber({
    required this.id,
    required this.userId,
    required this.barberShopId,
    required this.name,
    this.phone,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    barberShopId,
    name,
    phone,
    imageUrl,
    isActive,
    createdAt,
    updatedAt,
  ];
}
