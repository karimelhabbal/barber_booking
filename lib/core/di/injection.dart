import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/user_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

import '../../features/barber_shop/data/datasources/barber_shop_remote_data_source.dart';
import '../../features/barber_shop/data/repositories/barber_shop_repository_impl.dart';
import '../../features/barber_shop/domain/repositories/barber_shop_repository.dart';
import '../../features/barber_shop/presentation/cubit/barber_shop_cubit.dart';

import '../../features/barber/data/datasources/barber_remote_data_source.dart';
import '../../features/barber/data/repositories/barber_repository_impl.dart';
import '../../features/barber/domain/repositories/barber_repository.dart';
import '../../features/barber/presentation/cubit/barber_cubit.dart';

import '../../features/schedule/data/datasources/schedule_remote_data_source.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/presentation/cubit/schedule_cubit.dart';

import '../../features/service/data/datasources/service_remote_data_source.dart';
import '../../features/service/data/repositories/service_repository_impl.dart';
import '../../features/service/domain/repositories/service_repository.dart';
import '../../features/service/presentation/cubit/service_cubit.dart';

import '../../features/booking/data/datasources/booking_remote_data_source.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/domain/services/availability_service.dart';
import '../../features/booking/domain/usecases/create_booking.dart';
import '../../features/booking/domain/usecases/get_available_slots.dart';
import '../../features/booking/presentation/cubit/booking_cubit.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<fb.FirebaseAuth>(() => fb.FirebaseAuth.instance);

  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: getIt<fb.FirebaseAuth>()),
  );

  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authRemoteDataSource: getIt<AuthRemoteDataSource>(),
      userRemoteDataSource: getIt<UserRemoteDataSource>(),
    ),
  );

  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(authRepository: getIt<AuthRepository>()),
  );

  // ---------------------------------------------------------------------------
  // Barber Shop
  // ---------------------------------------------------------------------------

  getIt.registerLazySingleton<BarberShopRemoteDataSource>(
    () => BarberShopRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<BarberShopRepository>(
    () => BarberShopRepositoryImpl(
      remoteDataSource: getIt<BarberShopRemoteDataSource>(),
    ),
  );

  getIt.registerFactory<BarberShopCubit>(
    () => BarberShopCubit(repository: getIt<BarberShopRepository>()),
  );

  // ---------------------------------------------------------------------------
  // Barber
  // ---------------------------------------------------------------------------

  getIt.registerLazySingleton<BarberRemoteDataSource>(
    () => BarberRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<BarberRepository>(
    () =>
        BarberRepositoryImpl(remoteDataSource: getIt<BarberRemoteDataSource>()),
  );

  getIt.registerFactory<BarberCubit>(
    () => BarberCubit(repository: getIt<BarberRepository>()),
  );

  // ---------------------------------------------------------------------------
  // Schedule
  // ---------------------------------------------------------------------------

  getIt.registerLazySingleton<ScheduleRemoteDataSource>(
    () => ScheduleRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(
      remoteDataSource: getIt<ScheduleRemoteDataSource>(),
    ),
  );

  getIt.registerFactory<ScheduleCubit>(
    () => ScheduleCubit(repository: getIt<ScheduleRepository>()),
  );

  // ---------------------------------------------------------------------------
  // Service
  // ---------------------------------------------------------------------------

  getIt.registerLazySingleton<ServiceRemoteDataSource>(
    () => ServiceRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<ServiceRepository>(
    () => ServiceRepositoryImpl(
      remoteDataSource: getIt<ServiceRemoteDataSource>(),
    ),
  );

  getIt.registerFactory<ServiceCubit>(
    () => ServiceCubit(repository: getIt<ServiceRepository>()),
  );

  // ---------------------------------------------------------------------------
  // Booking
  // ---------------------------------------------------------------------------

  getIt.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      remoteDataSource: getIt<BookingRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<AvailabilityService>(
    () => const AvailabilityService(),
  );

  getIt.registerLazySingleton<GetAvailableSlots>(
    () => GetAvailableSlots(
      scheduleRepository: getIt<ScheduleRepository>(),
      bookingRepository: getIt<BookingRepository>(),
      availabilityService: getIt<AvailabilityService>(),
    ),
  );

  getIt.registerLazySingleton<CreateBooking>(
    () => CreateBooking(
      bookingRepository: getIt<BookingRepository>(),
      getAvailableSlots: getIt<GetAvailableSlots>(),
    ),
  );

  getIt.registerFactory<BookingCubit>(
    () => BookingCubit(
      repository: getIt<BookingRepository>(),
      getAvailableSlots: getIt<GetAvailableSlots>(),
      createBooking: getIt<CreateBooking>(),
    ),
  );
}
