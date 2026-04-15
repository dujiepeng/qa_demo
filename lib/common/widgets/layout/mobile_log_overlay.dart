import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_settings.dart';
import '../log_panel/log_panel.dart';

class MobileLogOverlay extends StatefulWidget {
  final Widget child;
  const MobileLogOverlay({super.key, required this.child});

  @override
  State<MobileLogOverlay> createState() => _MobileLogOverlayState();
}

class _MobileLogOverlayState extends State<MobileLogOverlay> {
  static const double _bubbleSize = 56.0;
  static const double _bubbleEdgeMargin = 8.0;
  double _logPanelHeight = 200.0;
  static const double _minLogHeight = 100.0;
  double? _bubbleVerticalRatioOverride;
  bool? _bubbleOnRightSideOverride;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;
    final isMinimized = settings.isLogOverlayMinimized;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (settings.isLoggedIn && !isMinimized)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildLogArea(isDark),
                ),
              if (settings.isLoggedIn && isMinimized)
                _buildFloatingBubble(context, isDark, settings, constraints),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogArea(bool isDark) {
    final settings = context.watch<AppSettings>();
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _logPanelHeight,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _logPanelHeight -= details.delta.dy;
                          final maxHeight =
                              MediaQuery.of(context).size.height * 0.7;
                          if (_logPanelHeight < _minLogHeight) {
                            _logPanelHeight = _minLogHeight;
                          } else if (_logPanelHeight > maxHeight) {
                            _logPanelHeight = maxHeight;
                          }
                        });
                      },
                      child: Container(
                        height: 28,
                        width: double.infinity,
                        color: isDark ? Colors.black26 : Colors.grey[300],
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.glassBorder(isDark),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.minimize, size: 18),
                              tooltip: '最小化日志',
                              splashRadius: 18,
                              onPressed: () {
                                settings.setLogOverlayMinimized(true);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: settings.isInit
                          ? LogPanel(isDark: isDark)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBubble(
    BuildContext context,
    bool isDark,
    AppSettings settings,
    BoxConstraints constraints,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + _bubbleEdgeMargin;
    final bottomPadding = mediaQuery.padding.bottom + _bubbleEdgeMargin;
    final maxTop = constraints.maxHeight - bottomPadding - _bubbleSize;
    final minTop = topPadding;
    final usableHeight = (maxTop - minTop).clamp(0.0, double.infinity);
    final verticalRatio =
        _bubbleVerticalRatioOverride ?? settings.logBubbleVerticalRatio;
    final bubbleTop = minTop + usableHeight * verticalRatio;
    final snappedRight =
        _bubbleOnRightSideOverride ?? settings.logBubbleOnRightSide;

    return Positioned(
      top: bubbleTop.clamp(minTop, maxTop),
      left: snappedRight ? null : _bubbleEdgeMargin,
      right: snappedRight ? _bubbleEdgeMargin : null,
      child: GestureDetector(
        onTap: () {
          settings.setLogOverlayMinimized(false);
        },
        onLongPressMoveUpdate: (details) {
          if (usableHeight <= 0) {
            return;
          }
          final localPosition = details.localPosition;
          final nextTop = (bubbleTop + localPosition.dy - (_bubbleSize / 2))
              .clamp(minTop, maxTop);
          final nextRatio = ((nextTop - minTop) / usableHeight).clamp(0.0, 1.0);
          final nextOnRightSide =
              details.globalPosition.dx > constraints.maxWidth / 2;
          setState(() {
            _bubbleVerticalRatioOverride = nextRatio;
            _bubbleOnRightSideOverride = nextOnRightSide;
          });
        },
        onLongPressEnd: (_) {
          final nextRatio =
              _bubbleVerticalRatioOverride ?? settings.logBubbleVerticalRatio;
          final nextOnRightSide =
              _bubbleOnRightSideOverride ?? settings.logBubbleOnRightSide;
          settings.updateLogBubblePlacement(
            onRightSide: nextOnRightSide,
            verticalRatio: nextRatio,
          );
          setState(() {
            _bubbleVerticalRatioOverride = null;
            _bubbleOnRightSideOverride = null;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _bubbleSize,
            height: _bubbleSize,
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.glassBorder(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.bug_report_outlined,
              color: AppColors.primary(isDark),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
