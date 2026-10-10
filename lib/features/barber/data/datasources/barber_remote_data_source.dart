import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/barber_candidate_model.dart';
import '../models/barber_model.dart';

enum BarberDataSourceErrorCode {
  barberIdEmpty,
  userIdEmpty,
  shopIdEmpty,
  nameEmpty,
  userNotFound,
  userNotBarber,
  assignedAnotherShop,
  assignedThisShop,
  barberNotFound,
  barberUserIdMissing,
  barberShopIdMissing,
}

class BarberDataSourceException implements Exception {
  const BarberDataSourceException(this.code);

  final BarberDataSourceErrorCode code;
}

abstract interface class BarberRemoteDataSource {
  Future<BarberModel?> getBarber({required String barberId});

  Future<List<BarberModel>> getShopBarbers({required String barberShopId});

  Future<BarberModel> createBarber({
    required String userId,
    required String barberShopId,
    required String name,
    String? phone,
    String? imageUrl,
  });

  Future<void> updateBarber(BarberModel barber);

  Future<void> deleteBarber({required String barberId});

  Future<List<BarberCandidateModel>> getBarberCandidates();

  Future<BarberModel?> getBarberByUserAndShop({
    required String userId,
    required String barberShopId,
  });
}

class BarberRemoteDataSourceImpl implements BarberRemoteDataSource {
  BarberRemoteDataSourceImpl({required this._supabase});

  final SupabaseClient _supabase;

  @override
  Future<BarberModel?> getBarber({required String barberId}) async {
    final id = barberId.trim();
    if (id.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.barberIdEmpty,
      );
    }
    final row = await _supabase
        .from('barbers')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : BarberModel.fromSupabase(row);
  }

  @override
  Future<List<BarberModel>> getShopBarbers({
    required String barberShopId,
  }) async {
    final shopId = barberShopId.trim();
    if (shopId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.shopIdEmpty,
      );
    }
    final rows = await _supabase
        .from('barbers')
        .select()
        .eq('barber_shop_id', shopId)
        .eq('is_active', true);
    return rows.map(BarberModel.fromSupabase).toList();
  }

  @override
  Future<BarberModel> createBarber({
    required String userId,
    required String barberShopId,
    required String name,
    String? phone,
    String? imageUrl,
  }) async {
    final uid = userId.trim(),
        shopId = barberShopId.trim(),
        barberName = name.trim();
    if (uid.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userIdEmpty,
      );
    }
    if (shopId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.shopIdEmpty,
      );
    }
    if (barberName.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.nameEmpty,
      );
    }
    final profile = await _supabase
        .from('profiles')
        .select('id,role,barber_shop_id')
        .eq('id', uid)
        .maybeSingle();
    if (profile == null) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userNotFound,
      );
    }
    if (profile['role'] != 'barber') {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userNotBarber,
      );
    }
    final currentShop = (profile['barber_shop_id'] as String?)?.trim();
    if (currentShop != null &&
        currentShop.isNotEmpty &&
        currentShop != shopId) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.assignedAnotherShop,
      );
    }
    final existing = await getBarberByUserAndShop(
      userId: uid,
      barberShopId: shopId,
    );
    if (existing != null && existing.isActive) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.assignedThisShop,
      );
    }
    final now = DateTime.now();
    final barber = BarberModel(
      id: existing?.id ?? _newBarberId(),
      userId: uid,
      barberShopId: shopId,
      name: barberName,
      phone: phone?.trim(),
      imageUrl: imageUrl?.trim(),
      isActive: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (existing == null) {
      await _supabase.from('barbers').insert(barber.toSupabase());
    } else {
      await _supabase
          .from('barbers')
          .update(barber.toSupabase())
          .eq('id', barber.id);
    }
    await _assignBarberProfile(uid, shopId);
    return barber;
  }

  @override
  Future<void> updateBarber(BarberModel barber) async {
    await _supabase.from('barbers').update({
      'name': barber.name,
      'phone': barber.phone,
      'image_url': barber.imageUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', barber.id);
  }

  @override
  Future<void> deleteBarber({required String barberId}) async {
    final id = barberId.trim();
    if (id.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.barberIdEmpty,
      );
    }
    final barber = await _supabase
        .from('barbers')
        .select('id,user_id,barber_shop_id')
        .eq('id', id)
        .maybeSingle();
    if (barber == null) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.barberNotFound,
      );
    }
    final uid = barber['user_id'] as String,
        shopId = barber['barber_shop_id'] as String;
    final profile = await _supabase
        .from('profiles')
        .select('barber_shop_id')
        .eq('id', uid)
        .maybeSingle();
    if (profile == null) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userNotFound,
      );
    }
    await _supabase
        .from('barbers')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    if (profile['barber_shop_id'] == shopId) {
      await _assignBarberProfile(uid, null);
    }
  }

  @override
  Future<List<BarberCandidateModel>> getBarberCandidates() async {
    final rows = await _supabase
        .from('profiles')
        .select('id,name,phone')
        .eq('role', 'barber')
        .isFilter('barber_shop_id', null);
    return rows.map(BarberCandidateModel.fromJson).toList();
  }

  @override
  Future<BarberModel?> getBarberByUserAndShop({
    required String userId,
    required String barberShopId,
  }) async {
    final uid = userId.trim(), shopId = barberShopId.trim();
    if (uid.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.userIdEmpty,
      );
    }
    if (shopId.isEmpty) {
      throw const BarberDataSourceException(
        BarberDataSourceErrorCode.shopIdEmpty,
      );
    }
    final row = await _supabase
        .from('barbers')
        .select()
        .eq('user_id', uid)
        .eq('barber_shop_id', shopId)
        .limit(1)
        .maybeSingle();
    return row == null ? null : BarberModel.fromSupabase(row);
  }

  static String _newBarberId() {
    const alphabet =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(
      24,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  Future<void> _assignBarberProfile(String userId, String? shopId) async {
    await _supabase.rpc(
      'assign_barber_profile_to_shop',
      params: {'p_profile_id': userId, 'p_shop_id': shopId},
    );
  }
}
