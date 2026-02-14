import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

/// 输入字段数据模型
class InputFieldData {
  /// 字段标题
  final String title;

  /// 输入框占位符
  final String placeholder;

  /// 当前文本值
  String text;

  /// 是否多行输入
  final bool multiline;

  InputFieldData({
    required this.title,
    required this.placeholder,
    required this.text,
    this.multiline = false,
  });

  /// 创建副本
  InputFieldData copyWith({
    String? title,
    String? placeholder,
    String? text,
    bool? multiline,
  }) {
    return InputFieldData(
      title: title ?? this.title,
      placeholder: placeholder ?? this.placeholder,
      text: text ?? this.text,
      multiline: multiline ?? this.multiline,
    );
  }
}

/// 通用输入对话框
///
/// 使用示例：
/// ```dart
/// final result = await showInputDialog(
///   context: context,
///   title: '编辑信息',
///   fields: [
///     InputFieldData(title: '名称', placeholder: '请输入名称', text: '当前名称'),
///     InputFieldData(title: '描述', placeholder: '请输入描述', text: '当前描述', multiline: true),
///   ],
/// );
/// if (result != null) {
///   // 用户点击了确定，result 包含更新后的字段数据
/// }
/// ```
Future<List<InputFieldData>?> showInputDialog({
  required BuildContext context,
  required String title,
  required List<InputFieldData> fields,
}) async {
  return showDialog<List<InputFieldData>>(
    context: context,
    builder: (context) => _InputDialog(title: title, fields: fields),
  );
}

/// 内部对话框组件（StatefulWidget）
class _InputDialog extends StatefulWidget {
  final String title;
  final List<InputFieldData> fields;

  const _InputDialog({required this.title, required this.fields});

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  final _settings = AppSettings();
  late List<TextEditingController> _controllers;
  late List<InputFieldData> _fieldsCopy;

  @override
  void initState() {
    super.initState();
    // 创建字段副本，避免直接修改传入的数据
    _fieldsCopy = widget.fields.map((field) => field.copyWith()).toList();
    // 为每个字段创建 controller
    _controllers = _fieldsCopy
        .map((field) => TextEditingController(text: field.text))
        .toList();
  }

  @override
  void dispose() {
    // 安全地 dispose 所有 controllers
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      title: Text(
        widget.title,
        style: TextStyle(color: AppColors.textPrimary(isDark)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_fieldsCopy.length, (index) {
            final field = _fieldsCopy[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _fieldsCopy.length - 1 ? 16 : 0,
              ),
              child: TextField(
                controller: _controllers[index],
                style: TextStyle(color: AppColors.textPrimary(isDark)),
                minLines: 1,
                maxLines: field.multiline ? 3 : 1,
                decoration: InputDecoration(
                  labelText: field.title,
                  hintText: field.placeholder,
                  labelStyle: TextStyle(color: AppColors.textSecondary(isDark)),
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary(isDark).withOpacity(0.5),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.glassBorder(isDark),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary(isDark)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 点击取消，返回 null
            Navigator.pop(context);
          },
          child: Text(
            '取消',
            style: TextStyle(color: AppColors.textSecondary(isDark)),
          ),
        ),
        TextButton(
          onPressed: () {
            // 更新字段数据
            for (int i = 0; i < _fieldsCopy.length; i++) {
              _fieldsCopy[i].text = _controllers[i].text.trim();
            }
            // 返回更新后的字段数据
            Navigator.pop(context, _fieldsCopy);
          },
          child: Text('确定', style: TextStyle(color: AppColors.primary(isDark))),
        ),
      ],
    );
  }
}
