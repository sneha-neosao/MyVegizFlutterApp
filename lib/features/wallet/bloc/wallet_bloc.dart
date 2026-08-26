import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repository/wallet_repo.dart';
import './wallet_event.dart';
import './wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({required WalletRepository repository})
      : super(const WalletDataState()) {
    on<FetchWalletSummary>((event, emit) async {
      // Only update summary-loading flag, don't wipe transactions state
      final current = state is WalletDataState
          ? state as WalletDataState
          : const WalletDataState();
      emit(current.copyWith(
        isSummaryLoading: true,
        clearSummaryError: true,
      ));
      try {
        final summary = await repository.getWalletSummary();
        final updated = state as WalletDataState;
        emit(updated.copyWith(
          summary: summary,
          isSummaryLoading: false,
        ));
      } catch (e) {
        final updated = state as WalletDataState;
        emit(updated.copyWith(
          isSummaryLoading: false,
          summaryError: e.toString(),
        ));
      }
    });

    on<FetchWalletTransactions>((event, emit) async {
      // Only update transactions-loading flag, don't wipe summary state
      final current = state is WalletDataState
          ? state as WalletDataState
          : const WalletDataState();
      emit(current.copyWith(
        isTransactionsLoading: true,
        clearTransactionsError: true,
      ));
      try {
        final response = await repository.getWalletTransactions(
          event.page,
          event.limit,
        );
        final updated = state as WalletDataState;
        emit(updated.copyWith(
          transactionsResponse: response,
          isTransactionsLoading: false,
        ));
      } catch (e) {
        final updated = state as WalletDataState;
        emit(updated.copyWith(
          isTransactionsLoading: false,
          transactionsError: e.toString(),
        ));
      }
    });

    on<ApplyWalletPoints>((event, emit) async {
      final current = state is WalletDataState
          ? state as WalletDataState
          : const WalletDataState();
      emit(current.copyWith(isActionLoading: true, clearApplyError: true));
      try {
        final response = await repository.applyWallet(event.points);
        emit(current.copyWith(
          isActionLoading: false,
          applyStatus: WalletApplyStatus.applied,
        ));
        emit(WalletActionSuccess(response.message, data: response));
        // Refresh summary after applying points
        add(FetchWalletSummary());
      } catch (e) {
        emit(current.copyWith(
          isActionLoading: false,
          applyStatus: WalletApplyStatus.failed,
          applyError: e.toString(),
        ));
        emit(WalletActionError(e.toString()));
      }
    });

    on<RemoveWalletPoints>((event, emit) async {
      final current = state is WalletDataState
          ? state as WalletDataState
          : const WalletDataState();
      emit(current.copyWith(isActionLoading: true, clearApplyError: true));
      try {
        final response = await repository.removeWallet();
        emit(current.copyWith(
          isActionLoading: false,
          applyStatus: WalletApplyStatus.none,
        ));
        emit(WalletActionSuccess(response.message, data: response));
        // Refresh summary after removing points
        add(FetchWalletSummary());
      } catch (e) {
        emit(current.copyWith(
          isActionLoading: false,
          applyError: e.toString(),
        ));
        emit(WalletActionError(e.toString()));
      }
    });
  }
}
