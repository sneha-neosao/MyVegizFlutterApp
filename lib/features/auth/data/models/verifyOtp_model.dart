// To parse this JSON data, do
//
//     final sendOtpVerifyModel = sendOtpVerifyModelFromJson(jsonString);

import 'dart:convert';

VerifyOtpModel sendOtpVerifyModelFromJson(String str) =>
    VerifyOtpModel.fromJson(json.decode(str));

String sendOtpVerifyModelToJson(VerifyOtpModel data) =>
    json.encode(data.toJson());

class VerifyOtpModel {
  int status;
  String message;
  Data? data;

  VerifyOtpModel({required this.status, required this.message, this.data});

  factory VerifyOtpModel.fromJson(Map<String, dynamic> json) => VerifyOtpModel(
    status: json["status"] ?? 0,
    message: json["message"] ?? "Unknown error",
    data: json["data"] != null ? Data.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  String accessToken;
  String refreshToken;
  String tokenType;
  Customer customer;

  Data({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.customer,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    accessToken: json["access_token"],
    refreshToken: json["refresh_token"],
    tokenType: json["token_type"],
    customer: Customer.fromJson(json["customer"]),
  );

  Map<String, dynamic> toJson() => {
    "access_token": accessToken,
    "refresh_token": refreshToken,
    "token_type": tokenType,
    "customer": customer.toJson(),
  };
}

class Customer {
  int id;
  String uuId;
  String name;
  String contact;
  String email;
  String? profileImage;
  bool isActive;

  Customer({
    required this.id,
    required this.uuId,
    required this.name,
    required this.contact,
    required this.email,
    this.profileImage,
    required this.isActive,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json["id"] ?? 0,
    uuId: json["uu_id"] ?? "",
    name: json["name"] ?? "",
    contact: json["contact"] ?? "",
    email: json["email"] ?? "",
    profileImage: json["profile_image"] ?? json["profileImage"],
    isActive: json["is_active"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uu_id": uuId,
    "name": name,
    "contact": contact,
    "email": email,
    if (profileImage != null) "profile_image": profileImage,
    "is_active": isActive,
  };
}

// class VerifyOtpModel {
//   final int status;
//   final String message;
//   final dynamic data;
//
//   VerifyOtpModel({required this.status, required this.message, this.data});
//
//   factory VerifyOtpModel.fromJson(Map<String, dynamic> json) {
//     return VerifyOtpModel(
//       status: json['status'],
//       message: json['message'],
//       data: json['data'],
//     );
//   }
// }
