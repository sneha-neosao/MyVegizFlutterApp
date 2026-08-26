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

  RegisterModel({required this.status, required this.message, this.data});

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
  String mobile;

  Data({required this.mobile});

  factory Data.fromJson(Map<String, dynamic> json) =>
      Data(mobile: json["mobile"]);

  Map<String, dynamic> toJson() => {"mobile": mobile};
}
