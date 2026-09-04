import 'dart:io';

abstract class ProfileEvent {}

class GetProfileEvent extends ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final String name;
  final String email;
  final String contact;
  final File? profileImage;

  UpdateProfileEvent({
    required this.name,
    required this.email,
    required this.contact,
    this.profileImage,
  });
}

class DeleteAccountEvent extends ProfileEvent {}
