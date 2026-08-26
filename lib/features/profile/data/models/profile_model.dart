/// Model representing the data returned from the Update Profile API.
class ProfileModel {
  final String name;
  final String email;
  final String contact;
  final String? profileImage;
  final String? message;

  const ProfileModel({
    required this.name,
    required this.email,
    required this.contact,
    this.profileImage,
    this.message,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json, {String? message}) {
    return ProfileModel(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      message: message,
    );
  }
}
