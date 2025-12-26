import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../models/menu_item.dart';
import '../../models/enums.dart';
import '../../utils/vnd_format.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.reportsTitle),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          indicatorColor: AppTheme.primaryOrange,
          tabs: [
            Tab(text: context.strings.reportByWeek),
            Tab(text: context.strings.reportByMonth),
            Tab(text: context.strings.reportByYear),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportTabView(type: ReportType.weekly),
          _ReportTabView(type: ReportType.monthly),
          _ReportTabView(type: ReportType.yearly),
        ],
      ),
    );
  }
}

class _ReportTabView extends StatefulWidget {
  final ReportType type;

  const _ReportTabView({required this.type});

  @override
  State<_ReportTabView> createState() => _ReportTabViewState();
}

class _ReportTabViewState extends State<_ReportTabView> {
  bool _isLoading = false;
  ReportModel? _currentReport;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadLatestReport();
  }

  Future<void> _loadLatestReport() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<RestaurantProvider>(context, listen: false);
      final report = await provider.generateReport(widget.type);
      if (mounted) {
        setState(() {
          _currentReport = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.strings.errorLoadingReport(e.toString())),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    }
  }

  Future<void> _selectDateAndGenerate() async {
    DateTime? picked;
    
    switch (widget.type) {
      case ReportType.weekly:
        // Select a date, then calculate week
        picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        break;
      case ReportType.monthly:
        // Show year/month picker
        final yearMonth = await _showYearMonthPicker();
        if (yearMonth != null) {
          picked = DateTime(yearMonth['year']!, yearMonth['month']!);
        }
        break;
      case ReportType.yearly:
        // Show year picker
        final year = await _showYearPicker();
        if (year != null) {
          picked = DateTime(year, 1, 1);
        }
        break;
    }

    if (picked != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final provider = Provider.of<RestaurantProvider>(context, listen: false);
        final report = await provider.generateReportForDate(widget.type, picked);
        if (mounted) {
          setState(() {
            _currentReport = report;
            _selectedDate = picked;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.strings.errorGeneratingReport(e.toString())),
              backgroundColor: AppTheme.statusRed,
            ),
          );
        }
      }
    }
  }

  Future<Map<String, int>?> _showYearMonthPicker() async {
    int? selectedYear;
    int? selectedMonth;

    return showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentYear = DateTime.now().year;
            final years = List.generate(5, (i) => currentYear - i);
            final months = List.generate(12, (i) => i + 1);

            return AlertDialog(
              title: Text(context.strings.selectMonthYear),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.strings.yearLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: years.map((year) {
                      return ChoiceChip(
                        label: Text(year.toString()),
                        selected: selectedYear == year,
                        onSelected: (selected) {
                          setState(() => selectedYear = year);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(context.strings.monthLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: months.map((month) {
                      return ChoiceChip(
                        label: Text(month.toString()),
                        selected: selectedMonth == month,
                        onSelected: (selected) {
                          setState(() => selectedMonth = month);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.strings.cancelButton),
                ),
                ElevatedButton(
                  onPressed: (selectedYear != null && selectedMonth != null)
                      ? () => Navigator.pop(context, {
                            'year': selectedYear!,
                            'month': selectedMonth!,
                          })
                      : null,
                  child: Text(context.strings.selectButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int?> _showYearPicker() async {
    int? selectedYear;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentYear = DateTime.now().year;
            final years = List.generate(5, (i) => currentYear - i);

            return AlertDialog(
              title: Text(context.strings.selectYear),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.strings.yearLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: years.map((year) {
                      return ChoiceChip(
                        label: Text(year.toString()),
                        selected: selectedYear == year,
                        onSelected: (selected) {
                          setState(() => selectedYear = year);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.strings.cancelButton),
                ),
                ElevatedButton(
                  onPressed: selectedYear != null
                      ? () => Navigator.pop(context, selectedYear)
                      : null,
                  child: Text(context.strings.selectButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentReport == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              context.strings.noReportData,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLatestReport,
              icon: const Icon(Icons.refresh),
              label: Text(context.strings.loadLatestReport),
            ),
          ],
        ),
      );
    }

    final report = _currentReport!;
    final provider = Provider.of<RestaurantProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadLatestReport,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.strings.reportForPeriod(report.periodLabel),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDateAndGenerate,
                  tooltip: context.strings.selectDifferentDate,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    context.strings.totalRevenue,
                    report.totalRevenue.toVnd(),
                    Icons.attach_money,
                    AppTheme.statusGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    context.strings.totalOrders,
                    '${report.totalOrders}',
                    Icons.receipt_long,
                    AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    context.strings.averageOrder,
                    report.totalOrders > 0
                        ? (report.totalRevenue / report.totalOrders).toVnd()
                        : '0₫',
                    Icons.trending_up,
                    AppTheme.statusYellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    context.strings.itemsSold,
                    '${report.itemSales.length}',
                    Icons.restaurant_menu,
                    AppTheme.darkGreyText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Selling Items
            Text(
              context.strings.mgrBestSellingDemo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (report.itemSales.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      context.strings.noSalesData,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            else
              ...(() {
                final sortedEntries = report.itemSales.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final top10 = sortedEntries.take(10).toList();
                
                return top10.asMap().entries.map((entry) {
                  final index = entry.key;
                  final itemEntry = entry.value;
                  final menuItem = provider.menu.firstWhere(
                    (item) => item.id.toString() == itemEntry.key,
                    orElse: () => provider.menu.isNotEmpty ? provider.menu.first : MenuItem(
                      id: 0,
                      name: 'Unknown',
                      price: 0,
                      category: MenuCategory.food,
                    ),
                  );
                  final revenue = report.itemRevenue[itemEntry.key] ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      title: Text(menuItem.name),
                      subtitle: Text(
                        '${itemEntry.value} ${context.strings.units} • ${revenue.toVnd()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        menuItem.price.toVnd(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList();
              })(),

            const SizedBox(height: 24),

            // Save Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    final provider =
                        Provider.of<RestaurantProvider>(context, listen: false);
                    await provider.saveReport(report);
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.strings.reportSavedSuccess),
                          backgroundColor: AppTheme.statusGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.strings.errorSavingReport(e.toString())),
                          backgroundColor: AppTheme.statusRed,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save),
                label: Text(context.strings.saveReport),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

