import 'dart:convert';

class AppUpdateResponse {
  final int status;
  final String message;
  final DeliveryAppData? data;

  AppUpdateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AppUpdateResponse.fromRawJson(String str) =>
      AppUpdateResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AppUpdateResponse.fromJson(Map<String, dynamic> json) {
    return AppUpdateResponse(
      status: json["status"] ?? 0,
      message: json["message"] ?? "",
      data: json["data"] != null ? DeliveryAppData.fromJson(json["data"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class DeliveryAppData {
  final AppVersion androidAppVersion;
  final AppVersion iosAppVersion;

  DeliveryAppData({
    required this.androidAppVersion,
    required this.iosAppVersion,
  });

  factory DeliveryAppData.fromJson(Map<String, dynamic> json) => DeliveryAppData(
    androidAppVersion:
    AppVersion.fromJson(json["android_app_version"] ?? {}),
    iosAppVersion:
    AppVersion.fromJson(json["ios_app_version"] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    "android_app_version": androidAppVersion.toJson(),
    "ios_app_version": iosAppVersion.toJson(),
  };
}

class AppVersion {
  final String version;
  final bool forceUpdate;
  final String updateMessage;
  final String storeLink;

  AppVersion({
    required this.version,
    required this.forceUpdate,
    required this.updateMessage,
    required this.storeLink,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) => AppVersion(
    version: json["version"] ?? "",
    forceUpdate: json["force_update"] ?? false,
    updateMessage: json["update_message"] ?? "",
    storeLink: json["store_link"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "version": version,
    "force_update": forceUpdate,
    "update_message": updateMessage,
    "store_link": storeLink,
  };
}
