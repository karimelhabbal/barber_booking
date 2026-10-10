import '../../domain/entities/barber_shop.dart';

class BarberShopModel extends BarberShop {
  const BarberShopModel({
    required super.id,
    required super.name,
    required super.ownerId,
    super.phone,
    super.address,
    super.description,
    super.imageUrl,
    required super.timezone,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BarberShopModel.fromJson(Map<String, dynamic> data) {
    return BarberShopModel(
      id: data['id'] as String,
      name: data['name'] as String? ?? '',
      ownerId: data['owner_id'] as String? ?? data['ownerId'] as String? ?? '',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      description: data['description'] as String?,
      imageUrl: data['image_url'] as String? ?? data['imageUrl'] as String?,
      timezone: data['timezone'] as String? ?? 'Africa/Cairo',
      isActive: data['is_active'] as bool? ?? data['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'owner_id': ownerId,
      'phone': phone,
      'address': address,
      'description': description,
      'image_url': imageUrl,
      'timezone': timezone,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory BarberShopModel.fromEntity(BarberShop shop) {
    return BarberShopModel(
      id: shop.id,
      name: shop.name,
      ownerId: shop.ownerId,
      phone: shop.phone,
      address: shop.address,
      description: shop.description,
      imageUrl: shop.imageUrl,
      timezone: shop.timezone,
      isActive: shop.isActive,
      createdAt: shop.createdAt,
      updatedAt: shop.updatedAt,
    );
  }
}
