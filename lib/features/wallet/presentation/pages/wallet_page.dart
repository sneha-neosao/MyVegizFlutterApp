import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../config/injector_conf.dart';
import '../../bloc/wallet_bloc.dart';
import '../../bloc/wallet_event.dart';
import '../../bloc/wallet_state.dart';
import '../../data/models/wallet_model.dart';
import '../../../../core/utils/snackbar_utils.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletBloc _walletBloc;

  @override
  void initState() {
    super.initState();
    _walletBloc = getIt<WalletBloc>();
    _walletBloc.add(FetchWalletSummary());
    _walletBloc.add(const FetchWalletTransactions(page: 1, limit: 20));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _refresh() {
    _walletBloc.add(FetchWalletSummary());
    _walletBloc.add(const FetchWalletTransactions(page: 1, limit: 20));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      bloc: _walletBloc,
      listenWhen: (_, current) =>
          current is WalletActionSuccess || current is WalletActionError,
      listener: (context, state) {
        if (state is WalletActionSuccess) {
          SnackbarUtils.showSuccessSnackbar(context, state.message);
        } else if (state is WalletActionError) {
          SnackbarUtils.showErrorSnackbar(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text(
            'My Wallet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: SafeArea(
          bottom: true,
          top: false,
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: BlocBuilder<WalletBloc, WalletState>(
              bloc: _walletBloc,
              builder: (context, state) {
                final data =
                    state is WalletDataState ? state : const WalletDataState();

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(data),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildTransactionsList(data),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Balance Card ────────────────────────────────────────────────────────────

  Widget _buildBalanceCard(WalletDataState data) {
    final summary = data.summary;
    final isLoading = data.isSummaryLoading;
    final error = data.summaryError;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFC8019), Color(0xFFFFAB40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFC8019).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // ── Balance amount or loader ──
          if (isLoading && summary == null)
            const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          else if (error != null && summary == null)
            Text(
              'Failed to load',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '₹ ${(summary?.walletBalanceRupees ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.15, end: 0),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Points chip ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Points',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    (summary?.walletBalancePoints ?? 0).toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // ── Apply / Remove buttons ──
              // Row(
              //   children: [
              //     _actionChip(
              //       label: 'Apply',
              //       icon: Icons.check_circle_outline_rounded,
              //       onTap: () => _showApplyDialog(
              //         context,
              //         summary?.walletBalancePoints ?? 0,
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     _actionChip(
              //       label: 'Remove',
              //       icon: Icons.remove_circle_outline_rounded,
              //       onTap: () => _walletBloc.add(RemoveWalletPoints()),
              //     ),
              //   ],
              // ),
            ],
          ),
        ],
      ),
    ).animate().scale(
          delay: 100.ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  // Widget _actionChip({
  //   required String label,
  //   required IconData icon,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //       decoration: BoxDecoration(
  //         color: Colors.white.withValues(alpha: 0.25),
  //         borderRadius: BorderRadius.circular(20),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(icon, color: Colors.white, size: 14),
  //           const SizedBox(width: 4),
  //           Text(
  //             label,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.bold,
  //               fontSize: 12,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ─── Transactions List ────────────────────────────────────────────────────────

  Widget _buildTransactionsList(WalletDataState data) {
    if (data.isTransactionsLoading && data.transactionsResponse == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (data.transactionsError != null && data.transactionsResponse == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                'Could not load transactions.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _walletBloc
                    .add(const FetchWalletTransactions(page: 1, limit: 20)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final transactions = data.transactionsResponse?.transactions ?? [];

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTransactionItem(transactions[index])
            .animate()
            .fadeIn(delay: (40 * index).ms)
            .slideY(begin: 0.08, end: 0);
      },
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    final bool isCredit = tx.transactionType.toUpperCase() == 'CREDIT';
    final DateTime date = DateTime.tryParse(tx.createdAt) ?? DateTime.now();
    final String formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(date.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCredit
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? Colors.green : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Description + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCredit
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx.transactionType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount + points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'} ₹${tx.rupees.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${tx.points} pts',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────
}
