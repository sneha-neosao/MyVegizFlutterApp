import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object> get props => [];
}

class FetchWalletSummary extends WalletEvent {}

class FetchWalletTransactions extends WalletEvent {
  final int page;
  final int limit;

  const FetchWalletTransactions({this.page = 1, this.limit = 10});

  @override
  List<Object> get props => [page, limit];
}

class ApplyWalletPoints extends WalletEvent {
  final int points;

  const ApplyWalletPoints(this.points);

  @override
  List<Object> get props => [points];
}

class RemoveWalletPoints extends WalletEvent {}
