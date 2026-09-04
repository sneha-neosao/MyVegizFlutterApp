import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/core/utils/profile_image_notifier.dart';
import '../../domain/usecase/profile_usecases.dart';
import './profile_event.dart';
import './profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.deleteAccountUseCase,
  }) : super(ProfileInitial()) {
    on<GetProfileEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }

  Future<void> _onGetProfile(
    GetProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    logger.i('👤 ProfileBloc: Fetching profile...');
    emit(ProfileLoading());

    final result = await getProfileUseCase();

    await result.fold(
      (failure) {
        logger.e('👤 ProfileBloc GetProfile error: ${failure.message}');
        emit(ProfileError(failure.message));
      },
      (response) async {
        logger.i('👤 ProfileBloc: Profile response status=${response.status}, message="${response.message}"');

        final profile = response.data;
        if (profile != null) {
          logger.i('👤 ProfileBloc: Profile data found for "${profile.name}"');

          // Sync locally in SecureStorage
          if (profile.name.isNotEmpty) await SecureStorage.saveCustomerName(profile.name);
          if (profile.email.isNotEmpty) await SecureStorage.saveCustomerEmail(profile.email);
          if (profile.contact.isNotEmpty) await SecureStorage.saveCustomerContact(profile.contact);

          if (profile.profileImage != null && profile.profileImage!.isNotEmpty) {
            profileImageNotifier.value = profile.profileImage;
            await SecureStorage.saveCustomerProfileImage(profile.profileImage!);
          }
        }

        emit(ProfileLoaded(
          status: response.status,
          message: response.message,
          profile: profile,
        ));
      },
    );
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
