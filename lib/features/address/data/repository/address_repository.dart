import 'package:my_vegiz_flutter/core/api/api/api_exception.dart';
import 'package:my_vegiz_flutter/core/errors/failures.dart';
import 'package:my_vegiz_flutter/features/address/data/datasources/address_remote_datasource.dart';
import 'package:fpdart/fpdart.dart';
import '../models/address_model.dart';

abstract class AddressRepository {
  Future<Either<Failure, AddressListResponse>> getAddressList();
  Future<Either<Failure, AddressModel>> addAddress(AddressModel address);
  Future<Either<Failure, AddressModel>> updateAddress(
    String uuId,
    AddressModel address,
  );
  Future<Either<Failure, String>> deleteAddress(String uuId);
}

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;

  AddressRepositoryImpl(this.remoteDataSource);

  String _extractErrorMessage(dynamic e) {
    if (e is ApiException && e.message.isNotEmpty) {
      return e.message;
    }
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }

  @override
  Future<Either<Failure, AddressListResponse>> getAddressList() async {
    try {
      final result = await remoteDataSource.getAddressList();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, AddressModel>> addAddress(AddressModel address) async {
    try {
      final result = await remoteDataSource.addAddress(address);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, AddressModel>> updateAddress(
    String uuId,
    AddressModel address,
  ) async {
    try {
      final result = await remoteDataSource.updateAddress(uuId, address);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, String>> deleteAddress(String uuId) async {
    try {
      final result = await remoteDataSource.deleteAddress(uuId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }
}
