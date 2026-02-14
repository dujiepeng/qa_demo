import 'package:flutter/material.dart';

/// 异步按钮组件
/// 在异步操作完成之前防止重复点击
class AsyncButton extends StatefulWidget {
  const AsyncButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  /// 异步点击回调
  final Future<void> Function() onPressed;

  /// 按钮子组件
  final Widget child;

  /// 按钮样式
  final ButtonStyle? style;

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePress,
      style: widget.style,
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : widget.child,
    );
  }
}

/// 异步文本按钮组件
class AsyncTextButton extends StatefulWidget {
  const AsyncTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  final Future<void> Function() onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  State<AsyncTextButton> createState() => _AsyncTextButtonState();
}

class _AsyncTextButtonState extends State<AsyncTextButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isLoading ? null : _handlePress,
      style: widget.style,
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.child,
    );
  }
}

/// 异步图标按钮组件
class AsyncIconButton extends StatefulWidget {
  const AsyncIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.tooltip,
  });

  final Future<void> Function() onPressed;
  final Widget icon;
  final Color? color;
  final String? tooltip;

  @override
  State<AsyncIconButton> createState() => _AsyncIconButtonState();
}

class _AsyncIconButtonState extends State<AsyncIconButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading ? null : _handlePress,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.icon,
      color: widget.color,
      tooltip: widget.tooltip,
    );
  }
}
