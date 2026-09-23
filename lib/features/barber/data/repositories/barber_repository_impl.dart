import '../../domain/entities/barber.dart';
import '../../domain/repositories/barber_repository.dart';
import '../datasources/barber_remote_data_source.dart';
import '../models/barber_model.dart';
import '../../domain/entities/barber_candidate.dart';

class BarberRepositoryImpl implements BarberRepository {
  BarberRepositoryImpl({required this._remoteDataSource});

  final BarberRemoteDataSource _remoteDataSource;

  @override
  Future<Barber?> getBarber({required String barberId}) {
    return _remoteDataSource.getBarber(barberId: barberId);
  }

  @override
  Future<List<Barber>> getShopBarbers({required String barberShopId}) {
    return _remoteDataSource.getShopBarbers(barberShopId: barberShopId);
  }

  @override
  Future<Barber> createBarber({
    required String userId,
    required String barberShopId,
    required String name,
    String? phone,
    String? imageUrl,
  }) {
    return _remoteDataSource.createBarber(
      userId: userId,
      barberShopId: barberShopId,
      name: name,
      phone: phone,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<void> updateBarber(Barber barber) {
    return _remoteDataSource.updateBarber(BarberModel.fromEntity(barber));
  }

  @override
  Future<void> deleteBarber({required String barberId}) {
    return _remoteDataSource.deleteBarber(barberId: barberId);
  }

  @override
  Future<List<BarberCandidate>> getBarberCandidates() {
    return _remoteDataSource.getBarberCandidates();
  }

  @override
  Future<Barber?> getBarberByUserAndShop({
    required String userId,
    required String barberShopId,
  }) {
    return _remoteDataSource.getBarberByUserAndShop(
      userId: userId,
      barberShopId: barberShopId,
    );
  }
}
