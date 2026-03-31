import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_strings.dart';
import '../../providers/restaurant_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/payment_dialog.dart';

class CashierDashboardScreen extends StatelessWidget {
  const CashierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantProvider>(
      builder: (context, provider, _) {
        final pendingTables = provider.tables
            .where((table) => table.status == TableStatus.paymentPending)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));

        return Scaffold(
          backgroundColor: AppTheme.lightGreyBg,
          appBar: AppBar(
            title: const Text('Thu ngân'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: context.strings.refresh,
                onPressed: () => provider.refreshData(),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : pendingTables.isEmpty
              ? const _CashierEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingTables.length,
                  itemBuilder: (context, index) {
                    final table = pendingTables[index];
                    return _PendingPaymentCard(table: table);
                  },
                ),
        );
      },
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  final TableModel table;

  const _PendingPaymentCard({required this.table});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.statusYellow,
          child: Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text(
          table.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Đang chờ thanh toán'),
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.point_of_sale),
          label: const Text('Thanh toán'),
          onPressed: () async {
            await _openPaymentDialog(context, provider, table);
          },
        ),
      ),
    );
  }

  Future<void> _openPaymentDialog(
    BuildContext context,
    RestaurantProvider provider,
    TableModel table,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      final orders = await provider.getCompletedOrdersForTable(table.id);
      if (!context.mounted) return;
      Navigator.pop(context);

      if (orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có đơn hàng nào để thanh toán'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => PaymentDialog(table: table, orders: orders),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải thông tin thanh toán: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CashierEmptyState extends StatelessWidget {
  const _CashierEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có bàn nào chờ thanh toán',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
