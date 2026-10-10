import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_model.dart';

abstract interface class ServiceRemoteDataSource {
  Future<ServiceModel?> getService({required String shopId, required String serviceId});
  Future<List<ServiceModel>> getShopServices({required String shopId});
  Future<List<ServiceModel>> getActiveShopServices({required String shopId});
  Future<ServiceModel> createService({required String shopId, required String name, String? description, required int durationMinutes, required double price});
  Future<void> updateService(ServiceModel service);
  Future<void> deleteService({required String shopId, required String serviceId});
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  ServiceRemoteDataSourceImpl({required this._client});
  final SupabaseClient _client;

  @override
  Future<ServiceModel?> getService({required String shopId, required String serviceId}) async {
    final row = await _client.from('services').select().eq('barber_shop_id', shopId).eq('id', serviceId).maybeSingle();
    return row == null ? null : ServiceModel.fromJson(row);
  }

  @override
  Future<List<ServiceModel>> getShopServices({required String shopId}) async {
    final rows = await _client.from('services').select().eq('barber_shop_id', shopId);
    return rows.map(ServiceModel.fromJson).toList();
  }

  @override
  Future<List<ServiceModel>> getActiveShopServices({required String shopId}) async {
    final rows = await _client.from('services').select().eq('barber_shop_id', shopId).eq('is_active', true);
    return rows.map(ServiceModel.fromJson).toList();
  }

  @override
  Future<ServiceModel> createService({required String shopId, required String name, String? description, required int durationMinutes, required double price}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = await _client.from('services').insert({
      'barber_shop_id': shopId,
      'name': name.trim(),
      'description': description?.trim(),
      'duration_minutes': durationMinutes,
      'price': price,
      'is_active': true,
      'created_at': now,
      'updated_at': now,
    }).select().single();
    return ServiceModel.fromJson(row);
  }

  @override
  Future<void> updateService(ServiceModel service) async {
    await _client.from('services').update({...service.toJson(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('barber_shop_id', service.barberShopId).eq('id', service.id);
  }

  @override
  Future<void> deleteService({required String shopId, required String serviceId}) async {
    await _client.from('services').delete().eq('barber_shop_id', shopId).eq('id', serviceId);
  }
}
