import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class MessageSendOptionsRow extends StatelessWidget {
  final TextEditingController countController;
  final bool deliverOnlineOnly;
  final ValueChanged<bool> onDeliverOnlineOnlyChanged;
  final bool isDark;

  const MessageSendOptionsRow({
    super.key,
    required this.countController,
    required this.deliverOnlineOnly,
    required this.onDeliverOnlineOnlyChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '重复次数',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: TextField(
            controller: countController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary(isDark)),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            contextMenuBuilder: (context, editableTextState) {
              final buttonItems = editableTextState.contextMenuButtonItems;
              buttonItems.removeWhere(
                (item) => item.type == ContextMenuButtonType.paste,
              );
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: buttonItems,
              );
            },
            decoration: InputDecoration(
              hintText: '次数',
              hintStyle: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 12,
              ),
              filled: true,
              fillColor: AppColors.inputBackground(isDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary(isDark)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onDeliverOnlineOnlyChanged(!deliverOnlineOnly),
          child: Row(
            children: [
              Checkbox(
                value: deliverOnlineOnly,
                onChanged: (value) =>
                    onDeliverOnlineOnlyChanged(value ?? false),
              ),
              Text(
                '只发在线',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
