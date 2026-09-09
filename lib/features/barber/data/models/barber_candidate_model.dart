import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/barber_candidate.dart';

class BarberCandidateModel extends BarberCandidate {
  const BarberCandidateModel({
    required super.id,
    required super.name,
    super.phone,
  });

  factory BarberCandidateModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('User document ${document.id} does not exist.');
    }

    return BarberCandidateModel(
      id: document.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
    );
  }
}
