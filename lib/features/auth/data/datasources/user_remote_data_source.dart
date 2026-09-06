import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

abstract interface class UserRemoteDataSource {
  Future<UserModel?> getUser({required String userId});

  Future<UserModel> createUser({
    required String userId,
    required String name,
    required String phone,
  });

  Future<void> updateUser(UserModel user);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserModel?> getUser({required String userId}) async {
    final document = await _usersCollection.doc(userId).get();

    if (!document.exists) {
      return null;
    }

    return UserModel.fromFirestore(document);
  }

  @override
  Future<UserModel> createUser({
    required String userId,
    required String name,
    required String phone,
  }) async {
    final userReference = _usersCollection.doc(userId);

    final existingDocument = await userReference.get();

    if (existingDocument.exists) {
      return UserModel.fromFirestore(existingDocument);
    }

    final user = UserModel(id: userId, name: name.trim(), phone: phone.trim());

    await userReference.set(user.toFirestore());

    return user;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _usersCollection
        .doc(user.id)
        .set(user.toFirestore(), SetOptions(merge: true));
  }
}
