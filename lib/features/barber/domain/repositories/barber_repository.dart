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
  Future<List<BarberCandidate>> getBarberCandidates();
  Future<Barber?> getBarberByUserAndShop({
    required String userId,
    required String barberShopId,
  });
}
