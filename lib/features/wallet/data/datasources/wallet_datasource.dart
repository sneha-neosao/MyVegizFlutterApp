import '../../../../core/api/api/api_helper.dart';
import '../../../../core/api/api/api_url.dart';
import '../models/wallet_model.dart';

class WalletRemoteDataSource {
  final ApiHelper apiHelper;

  WalletRemoteDataSource(this.apiHelper);

  Future<WalletSummary> getWalletSummary() async {
    final response = await apiHelper.execute(
      method: Method.get,
      url: ApiUrl.walletSummary,
    );
    return WalletSummary.fromJson(response);
  }

  Future<WalletTransactionsResponse> getWalletTransactions(int page, int limit) async {
    final response = await apiHelper.execute(
      method: Method.get,
      url: ApiUrl.walletTransactions(page, limit),
    );
    return WalletTransactionsResponse.fromJson(response);
  }

  Future<WalletApplyResponse> applyWallet(int points) async {
    final response = await apiHelper.execute(
      method: Method.post,
      url: ApiUrl.applyWallet,
      data: {"points": points},
    );
    return WalletApplyResponse.fromJson(response);
  }

  Future<WalletRemoveResponse> removeWallet() async {
    final response = await apiHelper.execute(
      method: Method.post,
      url: ApiUrl.removeWallet,
    );
    return WalletRemoveResponse.fromJson(response);
  }
}
