import '../data/models/address_model.dart';

abstract class AddressEvent {}

class FetchAddressList extends AddressEvent {}

class AddAddressEvent extends AddressEvent {
  final AddressModel address;

  AddAddressEvent(this.address);
}

class UpdateAddressEvent extends AddressEvent {
  final String uuId;
  final AddressModel address;

  UpdateAddressEvent({required this.uuId, required this.address});
}

class DeleteAddressEvent extends AddressEvent {
  final String uuId;

  DeleteAddressEvent(this.uuId);
}

class ClearAddressEvent extends AddressEvent {}

