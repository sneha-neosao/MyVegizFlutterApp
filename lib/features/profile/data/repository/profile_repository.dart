import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:my_vegiz_flutter/core/errors/failures.dart';
import '../datasources/profile_datasource.dart';
import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileModel>> updateProfile({
    required String name,
    required String email,
    required String contact,
    File? profileImage,
  });

  Future<Either<Failure, String>> deleteAccount();
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ProfileModel>> updateProfile({
    required String name,
    required String email,
    required String contact,
    File? profileImage,
  }) async {
    try {
      final result = await remoteDataSource.updateProfile(
        name: name,
        email: email,
        contact: contact,
        profileImage: profileImage,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deleteAccount() async {
    try {
      final result = await remoteDataSource.deleteAccount();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
