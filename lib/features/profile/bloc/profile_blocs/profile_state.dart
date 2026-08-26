import '../../data/models/profile_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileModel profile;
  final String message;
  ProfileUpdateSuccess(this.profile, this.message);
}

class ProfileDeleteSuccess extends ProfileState {
  final String message;
  ProfileDeleteSuccess(this.message);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}
