import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:my_vegiz_flutter/core/errors/failures.dart';
import '../../data/models/profile_model.dart';
import '../../data/repository/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<Either<Failure, ProfileResponse>> call() {
    return repository.getProfile();
  }
}

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, ProfileModel>> call({
    required String name,
    required String email,
    required String contact,
    File? profileImage,
  }) {
    return repository.updateProfile(
      name: name,
      email: email,
      contact: contact,
      profileImage: profileImage,
    );
  }
}

class DeleteAccountUseCase {
  final ProfileRepository repository;

  DeleteAccountUseCase(this.repository);

  Future<Either<Failure, String>> call() {
    return repository.deleteAccount();
  }
}
