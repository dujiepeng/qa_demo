import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

/// 带有 Switch 的对话框组件，支持异步确认逻辑
///
/// [title] 对话框标题
/// [description] 对话框描述信息
/// [initialValue] 开关的初始状态
/// [onChanged] 切换开关的回调，返回 Future<bool>。如果返回 false，开关将回弹到旧状态。
Future<void> showSwitchAlert({
  required BuildContext context,
  required String title,
  required String description,
  required bool initialValue,
  required Future<bool> Function(bool value) onChanged,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // 禁止点击外部关闭，确保状态一致性
    builder: (context) => _SwitchAlert(
      title: title,
      description: description,
      initialValue: initialValue,
      onChanged: onChanged,
    ),
  );
}

class _SwitchAlert extends StatefulWidget {
  final String title;
  final String description;
  final bool initialValue;
  final Future<bool> Function(bool value) onChanged;

  const _SwitchAlert({
    required this.title,
    required this.description,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_SwitchAlert> createState() => _SwitchAlertState();
}

class _SwitchAlertState extends State<_SwitchAlert> {
  final _settings = AppSettings();
  late bool _currentValue;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // 初始化开关状态
    _currentValue = widget.initialValue;
  }

  Future<void> _handleToggle(bool value) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 执行异步回调
      final success = await widget.onChanged(value);

      if (mounted) {
        if (success) {
          // 如果成功，更新当前状态
          setState(() {
            _currentValue = value;
            _isProcessing = false;
          });
        } else {
          // 如果失败，保持原状态（回弹由 onChanged 的逻辑保证，这里只需重置 loading）
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      elevation: 0,
      title: Text(
        widget.title,
        style: TextStyle(
          color: AppColors.textPrimary(isDark),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentValue ? '已开启' : '已关闭',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Switch.adaptive(
                    value: _currentValue,
                    onChanged: _isProcessing ? null : _handleToggle,
                    activeColor: AppColors.primary(isDark),
                  ),
                  if (_isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text(
            '完成',
            style: TextStyle(
              color: AppColors.primary(isDark),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
