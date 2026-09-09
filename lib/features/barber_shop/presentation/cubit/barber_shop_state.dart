part of 'barber_shop_cubit.dart';

abstract class BarberShopState extends Equatable {
  const BarberShopState();

  @override
  List<Object?> get props => [];
}

class BarberShopInitial extends BarberShopState {
  const BarberShopInitial();
}

class BarberShopLoading extends BarberShopState {
  const BarberShopLoading();
}

class BarberShopLoaded extends BarberShopState {
  const BarberShopLoaded(this.shops);

  final List<BarberShop> shops;

  @override
  List<Object?> get props => [shops];
}

class BarberShopOwnerLoading extends BarberShopState {
  const BarberShopOwnerLoading();
}

class BarberShopOwnerLoaded extends BarberShopState {
  const BarberShopOwnerLoaded(this.shop);

  final BarberShop? shop;

  @override
  List<Object?> get props => [shop];
}

class BarberShopCreating extends BarberShopState {
  const BarberShopCreating();
}

class BarberShopCreated extends BarberShopState {
  const BarberShopCreated(this.shop);

  final BarberShop shop;

  @override
  List<Object?> get props => [shop];
}

class BarberShopError extends BarberShopState {
  const BarberShopError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
