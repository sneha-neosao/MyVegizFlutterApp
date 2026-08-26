// To parse this JSON data, do
//
//     final sendOtpModel = sendOtpModelFromJson(jsonString);

import 'dart:convert';

SendOtpModel sendOtpModelFromJson(String str) => SendOtpModel.fromJson(json.decode(str));

String sendOtpModelToJson(SendOtpModel data) => json.encode(data.toJson());

class SendOtpModel {
  int status;
  String message;
  Data? data;

  SendOtpModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory SendOtpModel.fromJson(Map<String, dynamic> json) => SendOtpModel(
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

  Data({
    required this.mobile,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    mobile: json["mobile"],
  );

  Map<String, dynamic> toJson() => {
    "mobile": mobile,
  };
}
