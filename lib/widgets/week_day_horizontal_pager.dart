import 'package:flutter/material.dart';
import '../providers/app_strings.dart';
import '../theme/app_theme.dart';

/// Compact row (Mon–Sun) synced to a [PageController] for day-by-day paging.
class WeekDayStrip extends StatelessWidget {
  const WeekDayStrip({
    super.key,
    required this.weekDays,
    required this.selectedIndex,
    required this.pageController,
    this.onSelected,
  });

  final List<DateTime> weekDays;
  final int selectedIndex;
  final PageController pageController;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: List.generate(weekDays.length, (i) {
        final d = weekDays[i];
        final isToday =
            d.year == now.year && d.month == now.month && d.day == now.day;
        final selected = i == selectedIndex;
        final label = context.strings.getWeekdayAbbr(d.weekday);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: selected
                  ? AppTheme.primaryOrange
                  : (isToday
                      ? AppTheme.primaryOrange.withValues(alpha: 0.12)
                      : Colors.white),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  onSelected?.call(i);
                  // Nếu màn hình cha không xử lý, fallback sang animate trực tiếp.
                  if (onSelected == null && pageController.hasClients) {
                    pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppTheme.darkGreyText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppTheme.darkGreyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
