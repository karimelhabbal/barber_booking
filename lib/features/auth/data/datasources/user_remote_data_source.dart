import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../../domain/entities/user.dart';

abstract interface class UserRemoteDataSource {
  Future<UserModel?> getUser({required String userId});
  Future<UserModel> createUser({required String userId, required String name, required String phone});
  Future<void> updateUser(UserModel user);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl({required this._client});
  final SupabaseClient _client;

  @override
  Future<UserModel?> getUser({required String userId}) async {
    final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return row == null ? null : UserModel.fromJson(row);
  }

  @override
  Future<UserModel> createUser({required String userId, required String name, required String phone}) async {
    final normalizedPhone = phone.trim();
    final row = await _client.from('profiles').insert({
      'id': userId,
      'name': name.trim(),
      // Email/social signups supply no phone; store NULL instead of an empty string.
      'phone': normalizedPhone.isEmpty ? null : normalizedPhone,
      'role': 'customer',
      'barber_shop_id': null,
    }).select().single();
    return UserModel.fromJson(row);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _client.from('profiles').update({
      'name': user.name,
      'phone': user.phone,
      'role': _roleToString(user.role),
      'barber_shop_id': user.barberShopId,
    }).eq('id', user.id);
  }

  String _roleToString(UserRole role) => switch (role) {
    UserRole.owner => 'owner', UserRole.barber => 'barber', UserRole.customer => 'customer',
  };
}
