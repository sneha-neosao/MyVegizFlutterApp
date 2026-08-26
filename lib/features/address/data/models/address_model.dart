class AddressModel {
  final int? id;
  final String? uuId;
  final String label;
  final String deliveryName;
  final String deliveryPhone;
  final String addressLine;
  final String? landmark;
  final String? city;
  final String? pincode;
  final double? lat;
  final double? lng;
  final bool isDefault;
  final String? message;

  AddressModel({
    this.id,
    this.uuId,
    required this.label,
    required this.deliveryName,
    required this.deliveryPhone,
    required this.addressLine,
    this.landmark,
    this.city,
    this.pincode,
    this.lat,
    this.lng,
    this.isDefault = false,
    this.message,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json, {String? message}) {
    return AddressModel(
      id: json['id'],
      uuId: json['uu_id'],
      label: json['label'] ?? '',
      deliveryName: json['delivery_name'] ?? '',
      deliveryPhone: json['delivery_phone'] ?? '',
      addressLine: json['address_line'] ?? '',
      landmark: json['landmark'],
      city: json['city'],
      pincode: json['pincode'],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      message: message ?? json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'delivery_name': deliveryName,
      'delivery_phone': deliveryPhone,
      'address_line': addressLine,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault ? 1 : 0,
    };
  }
}

class AddressListResponse {
  final int total;
  final List<AddressModel> addresses;

  AddressListResponse({required this.total, required this.addresses});

  factory AddressListResponse.fromJson(Map<String, dynamic> json) {
    return AddressListResponse(
      total: json['total'] ?? 0,
      addresses: (json['addresses'] as List?)
              ?.map((e) => AddressModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MockAddressData {
  static List<AddressModel> savedAddresses = [];
}
