// To parse this JSON data, do
//
//     final registerModel = registerModelFromJson(jsonString);

import 'dart:convert';

RegisterModel registerModelFromJson(String str) =>
    RegisterModel.fromJson(json.decode(str));

String registerModelToJson(RegisterModel data) => json.encode(data.toJson());

class RegisterModel {
  int status;
  String message;
  Data? data;

  RegisterModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory RegisterModel.fromJson(Map<String, dynamic> json) => RegisterModel(
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
  String? accessToken;
  String? refreshToken;
  String? tokenType;
  Customer? customer;
  bool? cartMerged;

  Data({
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.customer,
    this.cartMerged,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        accessToken: json["access_token"],
        refreshToken: json["refresh_token"],
        tokenType: json["token_type"],
        customer: json["customer"] != null
            ? Customer.fromJson(json["customer"])
            : null,
        cartMerged: json["cart_merged"],
      );

  Map<String, dynamic> toJson() => {
        if (accessToken != null) "access_token": accessToken,
        if (refreshToken != null) "refresh_token": refreshToken,
        if (tokenType != null) "token_type": tokenType,
        if (customer != null) "customer": customer?.toJson(),
        if (cartMerged != null) "cart_merged": cartMerged,
      };
}

class Customer {
  int id;
  String uuId;
  String name;
  String? email;
  String contact;
  String? profileImage;
  bool isActive;

  Customer({
    required this.id,
    required this.uuId,
    required this.name,
    this.email,
    required this.contact,
    this.profileImage,
    required this.isActive,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json["id"] ?? 0,
        uuId: json["uu_id"] ?? "",
        name: json["name"] ?? "",
        email: json["email"],
        contact: json["contact"] ?? "",
        profileImage: json["profile_image"] ?? json["profileImage"],
        isActive: json["is_active"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uu_id": uuId,
        "name": name,
        "email": email,
        "contact": contact,
        if (profileImage != null) "profile_image": profileImage,
        "is_active": isActive,
      };
}
