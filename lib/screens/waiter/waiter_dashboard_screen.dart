import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ordering_sheet.dart';

class WaiterDashboardScreen extends StatelessWidget {
  const WaiterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RestaurantProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.waiterTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildLegendItem(
                  AppTheme.statusGreen,
                  context.strings.legendFree,
                ),
                const SizedBox(width: 8),
                _buildLegendItem(
                  AppTheme.statusRed,
                  context.strings.legendBusy,
                ),
                const SizedBox(width: 8),
                _buildLegendItem(
                  AppTheme.statusYellow,
                  context.strings.legendPay,
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: langProvider.toggleLanguage,
                  child: Text(
                    langProvider.languageCode,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: provider.tables.length,
          itemBuilder: (context, index) {
            final table = provider.tables[index];
            return _buildTableCard(context, table, provider);
          },
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    TableModel table,
    RestaurantProvider provider,
  ) {
    Color statusColor = provider.getTableColor(table.status);
    bool isTapable = table.status == TableStatus.available;

    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isTapable
            ? () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => OrderingSheet(tableId: table.id),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: statusColor, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  table.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  table.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

