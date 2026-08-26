import 'package:fpdart/fpdart.dart';
import 'package:my_vegiz_flutter/core/errors/failures.dart';
import '../../data/models/address_model.dart';
import '../../data/repository/address_repository.dart';

class GetAddressListUseCase {
  final AddressRepository repository;
  GetAddressListUseCase(this.repository);

  Future<Either<Failure, AddressListResponse>> call() async {
    return await repository.getAddressList();
  }
}

class AddAddressUseCase {
  final AddressRepository repository;
  AddAddressUseCase(this.repository);

  Future<Either<Failure, AddressModel>> call(AddressModel address) async {
    return await repository.addAddress(address);
  }
}

class UpdateAddressUseCase {
  final AddressRepository repository;
  UpdateAddressUseCase(this.repository);

  Future<Either<Failure, AddressModel>> call(
    String uuId,
    AddressModel address,
  ) async {
    return await repository.updateAddress(uuId, address);
  }
}

class DeleteAddressUseCase {
  final AddressRepository repository;
  DeleteAddressUseCase(this.repository);

  Future<Either<Failure, String>> call(String uuId) async {
    return await repository.deleteAddress(uuId);
  }
}
