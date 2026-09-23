import '../entities/barber.dart';
import '../entities/barber_candidate.dart';

abstract interface class BarberRepository {
  Future<Barber?> getBarber({required String barberId});

  Future<List<Barber>> getShopBarbers({required String barberShopId});

  Future<Barber> createBarber({
    required String userId,
    required String barberShopId,
    required String name,
    String? phone,
    String? imageUrl,
  });

  Future<void> updateBarber(Barber barber);

  /// Soft deletes a barber by deactivating the existing document.
  Future<void> deleteBarber({required String barberId});

  Future<List<BarberCandidate>> getBarberCandidates();
  Future<Barber?> getBarberByUserAndShop({
    required String userId,
    required String barberShopId,
  });
}
