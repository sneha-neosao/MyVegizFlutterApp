import 'dart:convert';

RegiVerifyOtpModel regiVerifyOtpModelFromJson(String str) =>
    RegiVerifyOtpModel.fromJson(json.decode(str));

String regiVerifyOtpModelToJson(RegiVerifyOtpModel data) =>
    json.encode(data.toJson());

class RegiVerifyOtpModel {
  int status;
  String message;
  Data? data;

  RegiVerifyOtpModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory RegiVerifyOtpModel.fromJson(Map<String, dynamic> json) =>
      RegiVerifyOtpModel(
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
  bool cartMerged;

  Data({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.customer,
    required this.cartMerged,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    accessToken: json["access_token"] ?? "",
    refreshToken: json["refresh_token"] ?? "",
    tokenType: json["token_type"] ?? "",
    customer: Customer.fromJson(json["customer"]),
    cartMerged: json["cart_merged"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "access_token": accessToken,
    "refresh_token": refreshToken,
    "token_type": tokenType,
    "customer": customer.toJson(),
    "cart_merged": cartMerged,
  };
}

class Customer {
  int id;
  String uuId;
  String name;
  String email;
  String contact;
  bool isActive;

  Customer({
    required this.id,
    required this.uuId,
    required this.name,
    required this.email,
    required this.contact,
    required this.isActive,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json["id"] ?? 0,
    uuId: json["uu_id"] ?? "",
    name: json["name"] ?? "",
    email: json["email"] ?? "",
    contact: json["contact"] ?? "",
    isActive: json["is_active"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uu_id": uuId,
    "name": name,
    "email": email,
    "contact": contact,
    "is_active": isActive,
  };
}
