import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:flutter/foundation.dart';

/// A global ValueNotifier for the profile image path.
/// Any widget that displays the profile image should wrap itself in a
/// [ValueListenableBuilder] on [profileImageNotifier].
///
/// When the user updates their photo, call [ProfileImageNotifier.update]
/// so every listener rebuilds automatically.
final profileImageNotifier = ValueNotifier<String?>('');

class ProfileImageNotifier {
  /// Load the saved path from secure storage and broadcast it.
  static Future<void> load() async {
    final path = await SecureStorage.getCustomerProfileImage();
    profileImageNotifier.value = path;
  }

  /// Persist a new [path] and broadcast it to all listeners.
  static Future<void> update(String path) async {
    await SecureStorage.saveCustomerProfileImage(path);
    profileImageNotifier.value = path;
  }
}
