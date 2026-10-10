import '../../domain/entities/barber_candidate.dart';

class BarberCandidateModel extends BarberCandidate {
  const BarberCandidateModel({
    required super.id,
    required super.name,
    super.phone,
  });

  factory BarberCandidateModel.fromJson(Map<String, dynamic> row) {
    return BarberCandidateModel(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      phone: row['phone'] as String?,
    );
  }
}
