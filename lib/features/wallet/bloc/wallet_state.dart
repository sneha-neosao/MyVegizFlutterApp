import 'package:equatable/equatable.dart';
import '../data/models/wallet_model.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

/// Tracks the result of the last wallet apply/remove action.
enum WalletApplyStatus {
  /// No action taken yet — let cart data decide.
  none,
  /// Backend confirmed wallet was applied successfully.
  applied,
  /// Backend rejected the apply request.
  failed,
}

/// Unified data state — summary and transactions are updated independently
/// so they never clobber each other.
class WalletDataState extends WalletState {
  final WalletSummary? summary;
  final WalletTransactionsResponse? transactionsResponse;
  final bool isSummaryLoading;
  final bool isTransactionsLoading;
  final bool isActionLoading;
  /// Tracks the last apply/remove result independently from cart data.
  final WalletApplyStatus applyStatus;
  /// The error message from the last failed apply/remove action.
  final String? applyError;
  final String? summaryError;
  final String? transactionsError;

  const WalletDataState({
    this.summary,
    this.transactionsResponse,
    this.isSummaryLoading = false,
    this.isTransactionsLoading = false,
    this.isActionLoading = false,
    this.applyStatus = WalletApplyStatus.none,
    this.applyError,
    this.summaryError,
    this.transactionsError,
  });

  WalletDataState copyWith({
    WalletSummary? summary,
    WalletTransactionsResponse? transactionsResponse,
    bool? isSummaryLoading,
    bool? isTransactionsLoading,
    bool? isActionLoading,
    WalletApplyStatus? applyStatus,
    String? applyError,
    String? summaryError,
    String? transactionsError,
    bool clearSummaryError = false,
    bool clearTransactionsError = false,
    bool clearApplyError = false,
  }) {
    return WalletDataState(
      summary: summary ?? this.summary,
      transactionsResponse: transactionsResponse ?? this.transactionsResponse,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
      isTransactionsLoading:
          isTransactionsLoading ?? this.isTransactionsLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      applyStatus: applyStatus ?? this.applyStatus,
      applyError: clearApplyError ? null : (applyError ?? this.applyError),
      summaryError: clearSummaryError ? null : (summaryError ?? this.summaryError),
      transactionsError: clearTransactionsError
          ? null
          : (transactionsError ?? this.transactionsError),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        transactionsResponse,
        isSummaryLoading,
        isTransactionsLoading,
        isActionLoading,
        applyStatus,
        applyError,
        summaryError,
        transactionsError,
      ];
}

/// State emitted after Apply or Remove wallet actions
class WalletActionSuccess extends WalletState {
  final String message;
  final dynamic data;

  const WalletActionSuccess(this.message, {this.data});

  @override
  List<Object?> get props => [message, data];
}

class WalletActionError extends WalletState {
  final String message;

  const WalletActionError(this.message);

  @override
  List<Object?> get props => [message];
}
