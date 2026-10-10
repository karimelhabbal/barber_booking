import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/barber_shop_model.dart';

abstract interface class BarberShopRemoteDataSource {
  Future<BarberShopModel?> getShop({required String shopId});
  Future<BarberShopModel?> getOwnerShop({required String ownerId});
  Future<List<BarberShopModel>> getActiveShops();
  Future<BarberShopModel> createShop({required String ownerId, required String name, String? phone, String? address, String? description, String? imageUrl, required String timezone});
  Future<void> updateShop(BarberShopModel shop);
}

class BarberShopRemoteDataSourceImpl implements BarberShopRemoteDataSource {
  BarberShopRemoteDataSourceImpl({required this._client});
  final SupabaseClient _client;

  @override
  Future<BarberShopModel?> getShop({required String shopId}) async {
    final row = await _client.from('barber_shops').select().eq('id', shopId).maybeSingle();
    return row == null ? null : BarberShopModel.fromJson(row);
  }

  @override
  Future<BarberShopModel?> getOwnerShop({required String ownerId}) async {
    final rows = await _client.from('barber_shops').select().eq('owner_id', ownerId).limit(1);
    return rows.isEmpty ? null : BarberShopModel.fromJson(rows.first);
  }

  @override
  Future<List<BarberShopModel>> getActiveShops() async {
    final rows = await _client.from('barber_shops').select().eq('is_active', true);
    return rows.map(BarberShopModel.fromJson).toList();
  }

  @override
  Future<BarberShopModel> createShop({required String ownerId, required String name, String? phone, String? address, String? description, String? imageUrl, required String timezone}) async {
    final now = DateTime.now();
    final row = await _client.from('barber_shops').insert({
      'owner_id': ownerId,
      'name': name.trim(),
      'phone': phone?.trim(),
      'address': address?.trim(),
      'description': description?.trim(),
      'image_url': imageUrl?.trim(),
      'timezone': timezone,
      'is_active': true,
      'created_at': now.toUtc().toIso8601String(),
      'updated_at': now.toUtc().toIso8601String(),
    }).select().single();
    return BarberShopModel.fromJson(row);
  }

  @override
  Future<void> updateShop(BarberShopModel shop) async {
    await _client.from('barber_shops').update({...shop.toJson(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', shop.id).eq('owner_id', shop.ownerId);
  }
}
