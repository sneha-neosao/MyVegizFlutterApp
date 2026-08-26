import '../datasources/wallet_datasource.dart';
import '../models/wallet_model.dart';

abstract class WalletRepository {
  Future<WalletSummary> getWalletSummary();
  Future<WalletTransactionsResponse> getWalletTransactions(int page, int limit);
  Future<WalletApplyResponse> applyWallet(int points);
  Future<WalletRemoveResponse> removeWallet();
}

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource dataSource;

  WalletRepositoryImpl(this.dataSource);

  @override
  Future<WalletSummary> getWalletSummary() {
    return dataSource.getWalletSummary();
  }

  @override
  Future<WalletTransactionsResponse> getWalletTransactions(int page, int limit) {
    return dataSource.getWalletTransactions(page, limit);
  }

  @override
  Future<WalletApplyResponse> applyWallet(int points) {
    return dataSource.applyWallet(points);
  }

  @override
  Future<WalletRemoveResponse> removeWallet() {
    return dataSource.removeWallet();
  }
}
