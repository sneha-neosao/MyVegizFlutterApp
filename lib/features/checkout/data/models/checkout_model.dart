class SlotModel {
  final String uuId;
  final String slotRange;
  final String startTime;
  final String endTime;
  final String deliveryDate;
  final bool isToday;
  final String label;

  SlotModel({
    required this.uuId,
    required this.slotRange,
    required this.startTime,
    required this.endTime,
    required this.deliveryDate,
    required this.isToday,
    required this.label,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      uuId: json['uu_id'] ?? '',
      slotRange: json['slot_range'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      deliveryDate: json['delivery_date'] ?? '',
      isToday: json['is_today'] ?? false,
      label: json['label'] ?? '',
    );
  }
}

class ServiceTimeModel {
  final String serviceStartTime;
  final String serviceEndTime;
  final bool isServiceEnable;

  ServiceTimeModel({
    required this.serviceStartTime,
    required this.serviceEndTime,
    required this.isServiceEnable,
  });

  factory ServiceTimeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTimeModel(
      serviceStartTime: json['service_start_time'] as String? ?? '08:00:00',
      serviceEndTime: json['service_end_time'] as String? ?? '21:00:00',
      isServiceEnable: json['is_service_enable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_start_time': serviceStartTime,
      'service_end_time': serviceEndTime,
      'is_service_enable': isServiceEnable,
    };
  }

  /// Formatted range string (e.g. "8:00 AM to 9:00 PM")
  String get formattedRange {
    final start = _formatTime(serviceStartTime);
    final end = _formatTime(serviceEndTime);
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start to $end';
    }
    return '8:00 AM to 9:00 PM';
  }

  /// Returns true if current time is within service hours and service is enabled
  bool isCurrentlyServiceable() {
    if (!isServiceEnable) return false;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = _parseMinutes(serviceStartTime, defaultMinutes: 8 * 60);
    final endMinutes = _parseMinutes(serviceEndTime, defaultMinutes: 21 * 60);

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight range (e.g. 20:00 to 04:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  static int _parseMinutes(String timeStr, {required int defaultMinutes}) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.isNotEmpty) {
        final h = int.parse(parts[0]);
        final m = parts.length > 1 ? int.parse(parts[1]) : 0;
        return h * 60 + m;
      }
    } catch (_) {}
    return defaultMinutes;
  }

  static String _formatTime(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.isNotEmpty) {
        final h = int.parse(parts[0]);
        final m = parts.length > 1 ? int.parse(parts[1]) : 0;
        final period = h >= 12 ? 'PM' : 'AM';
        final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final minuteStr = m > 0 ? ':${m.toString().padLeft(2, '0')}' : ':00';
        return '$displayH$minuteStr $period';
      }
    } catch (_) {}
    return timeStr;
  }
}

class OrderSettingsModel {
  final int id;
  final String uuId;
  final bool isCodEnabled;
  final bool isOnlineEnabled;
  final bool isFirstOrderFree;
  final String? autoAssignMode;
  final bool isActive;
  final String createdAt;
  final List<String> availableModes;
  final ServiceTimeModel? serviceTime;

  OrderSettingsModel({
    required this.id,
    required this.uuId,
    required this.isCodEnabled,
    required this.isOnlineEnabled,
    required this.isFirstOrderFree,
    this.autoAssignMode,
    required this.isActive,
    required this.createdAt,
    this.availableModes = const [],
    this.serviceTime,
  });

  factory OrderSettingsModel.fromJson(Map<String, dynamic> json) {
    return OrderSettingsModel(
      id: json['id'] ?? 0,
      uuId: json['uu_id'] ?? '',
      isCodEnabled: json['is_cod_enabled'] ?? false,
      isOnlineEnabled: json['is_online_enabled'] ?? false,
      isFirstOrderFree: json['is_first_order_free'] ?? false,
      autoAssignMode: json['auto_assign_mode'] ??
          json['auto_assign'] ??
          json['autoAssignMode'],
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      availableModes: (json['available_modes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      serviceTime: json['service_time'] != null &&
              json['service_time'] is Map<String, dynamic>
          ? ServiceTimeModel.fromJson(
              json['service_time'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlaceOrderResponseModel {
  final int id;
  final String uuId;
  final double totalAmount;
  final double discountedTotal;
  final double deliveryCharge;
  final double grandTotal;
  final String? customerNote;

  PlaceOrderResponseModel({
    required this.id,
    required this.uuId,
    required this.totalAmount,
    required this.discountedTotal,
    required this.deliveryCharge,
    required this.grandTotal,
    this.customerNote,
  });

  factory PlaceOrderResponseModel.fromJson(Map<String, dynamic> json) {
    return PlaceOrderResponseModel(
      id: json['id'] ?? 0,
      uuId: json['uu_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      discountedTotal: (json['discounted_total'] ?? 0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      customerNote: json['customer_note'] as String?,
    );
  }
}
