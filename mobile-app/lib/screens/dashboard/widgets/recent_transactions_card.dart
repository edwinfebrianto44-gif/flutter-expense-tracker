import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../utils/formatters.dart';

class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionNotifier = ref.watch(transactionProvider.notifier);
    final recentTransactions = transactionNotifier.getRecentTransactions();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaksi Terbaru',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all transactions page (not implemented in this demo)
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (recentTransactions.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum Ada Transaksi',
              description: 'Mulai catat transaksi keuangan Anda',
              actionText: 'Tambah Transaksi',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTransactions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final transaction = recentTransactions[index];
                return InkWell(
                  onTap: () {
                    context.pushNamed(
                      'edit-transaction',
                      pathParameters: {'id': transaction.id.toString()},
                      extra: transaction,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: transaction.category?.color.withOpacity(0.1) ?? 
                                   Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              transaction.category?.icon ?? '💰',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Transaction Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.description,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    transaction.category?.name ?? 'Unknown',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.outline,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormatter.formatRelativeTime(transaction.date),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${transaction.type == 'income' ? '+' : '-'}${CurrencyFormatter.formatCompact(transaction.amount)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: transaction.type == 'income'
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              transaction.type == 'income'
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 16,
                              color: transaction.type == 'income'
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
