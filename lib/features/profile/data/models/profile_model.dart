/// Response model for GET /web/profile/list
class ProfileResponse {
  final int status;
  final String message;
  final ProfileModel? data;

  const ProfileResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? ProfileModel.fromJson(json['data'] as Map<String, dynamic>, message: json['message'] as String?)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.toJson(),
  };
}

/// Model representing user profile data.
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'contact': contact,
    if (profileImage != null) 'profile_image': profileImage,
  };
}
