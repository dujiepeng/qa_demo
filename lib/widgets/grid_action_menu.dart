import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GridActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  GridActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class GridActionMenu extends StatelessWidget {
  final List<GridActionItem> items;
  final double? itemWidth;
  final double itemHeight;
  final double spacing;
  final double runSpacing;
  final bool isDark;

  const GridActionMenu({
    super.key,
    required this.items,
    this.itemWidth,
    this.itemHeight = 60,
    this.spacing = 8,
    this.runSpacing = 8,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item width if not provided to fit roughly 4 items per row by default, or use fixed width
        final double width =
            itemWidth ?? (constraints.maxWidth - spacing * 5) / 4;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: items.map((item) {
            return SizedBox(
              width: width,
              height: itemHeight,
              child: ElevatedButton(
                onPressed: item.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.inputBackground(isDark),
                  foregroundColor: AppColors.textPrimary(isDark),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.glassBorder(isDark)),
                  ),
                  elevation: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: AppColors.primary(isDark), size: 20),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(isDark),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
