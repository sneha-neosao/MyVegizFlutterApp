import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/core/utils/profile_image_notifier.dart';
import '../../domain/usecase/profile_usecases.dart';
import './profile_event.dart';
import './profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;

  ProfileBloc({
    required this.updateProfileUseCase,
    required this.deleteAccountUseCase,
  }) : super(ProfileInitial()) {
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    logger.i('👤 ProfileBloc: Updating profile for "${event.name}"');
    emit(ProfileLoading());

    final result = await updateProfileUseCase(
      name: event.name,
      email: event.email,
      contact: event.contact,
      profileImage: event.profileImage,
    );

    await result.fold(
      (failure) {
        logger.e('👤 ProfileBloc UpdateError: ${failure.message}');
        emit(ProfileError(failure.message));
      },
      (profile) async {
        logger.i('👤 ProfileBloc: Profile updated successfully');

        // Persist locally
        await SecureStorage.saveCustomerName(profile.name);
        await SecureStorage.saveCustomerEmail(profile.email);
        await SecureStorage.saveCustomerContact(profile.contact);

        // Broadcast the Cloudinary URL to all image listeners
        if (profile.profileImage != null && profile.profileImage!.isNotEmpty) {
          profileImageNotifier.value = profile.profileImage;
          await SecureStorage.saveCustomerProfileImage(profile.profileImage!);
        }

        emit(ProfileUpdateSuccess(profile, profile.message ?? 'Profile updated successfully'));
      },
    );
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<ProfileState> emit,
  ) async {
    logger.i('👤 ProfileBloc: Deleting account');
    emit(ProfileLoading());

    final result = await deleteAccountUseCase();

    await result.fold(
      (failure) {
        logger.e('👤 ProfileBloc DeleteError: ${failure.message}');
        emit(ProfileError(failure.message));
      },
      (message) async {
        logger.i('👤 ProfileBloc: Account deleted — $message');
        await SecureStorage.clearAll();
        emit(ProfileDeleteSuccess(message));
      },
    );
  }
}
