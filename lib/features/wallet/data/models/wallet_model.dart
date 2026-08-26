class WalletSummary {
  final int walletBalancePoints;
  final double walletBalanceRupees;
  final double walletUsageLimitPercent;

  WalletSummary({
    required this.walletBalancePoints,
    required this.walletBalanceRupees,
    this.walletUsageLimitPercent = 100.0,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return WalletSummary(
      walletBalancePoints: (data['wallet_balance_points'] as num?)?.toInt() ?? 0,
      walletBalanceRupees: (data['wallet_balance_rupees'] as num?)?.toDouble() ?? 0.0,
      walletUsageLimitPercent: (data['wallet_usage_limit_percent'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class WalletTransaction {
  final int id;
  final int? orderId;
  final String? orderUuId;
  final double? orderTotalAmount;
  final double? walletDiscountAmount;
  final double? discountedTotal;
  final String transactionType;
  final int points;
  final double rupees;
  final String description;
  final String createdAt;

  WalletTransaction({
    required this.id,
    this.orderId,
    this.orderUuId,
    this.orderTotalAmount,
    this.walletDiscountAmount,
    this.discountedTotal,
    required this.transactionType,
    required this.points,
    required this.rupees,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? 0,
      orderId: json['order_id'],
      orderUuId: json['order_uu_id'],
      orderTotalAmount: (json['order_total_amount'] as num?)?.toDouble(),
      walletDiscountAmount: (json['wallet_discount_amount'] as num?)?.toDouble(),
      discountedTotal: (json['discounted_total'] as num?)?.toDouble(),
      transactionType: json['transaction_type'] ?? 'CREDIT',
      points: (json['points'] as num?)?.toInt() ?? 0,
      rupees: (json['rupees'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class WalletTransactionsResponse {
  final List<WalletTransaction> transactions;
  final Pagination? pagination;

  WalletTransactionsResponse({
    required this.transactions,
    this.pagination,
  });

  factory WalletTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? [];
    return WalletTransactionsResponse(
      transactions: data.map((e) => WalletTransaction.fromJson(e)).toList(),
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    );
  }
}

class Pagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 10,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class WalletApplyResponse {
  final int points;
  final double rupees;
  final String message;

  WalletApplyResponse({
    required this.points,
    required this.rupees,
    required this.message,
  });

  factory WalletApplyResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return WalletApplyResponse(
      points: (data['points'] as num?)?.toInt() ?? 0,
      rupees: (data['rupees'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] ?? '',
    );
  }
}

class WalletRemoveResponse {
  final bool removed;
  final String message;

  WalletRemoveResponse({
    required this.removed,
    required this.message,
  });

  factory WalletRemoveResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return WalletRemoveResponse(
      removed: data['removed'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
