import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:provider/provider.dart';

import '../common/widgets/input_dialog.dart';
import '../common/widgets/common_gradient_background.dart';
import '../pages/single/contact_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import 'my_models.dart';

typedef LoadDevicesCallback = Future<List<EMDeviceInfo>> Function();
typedef LoadStoredDevicesCallback =
    Future<List<EMDeviceInfo>> Function(String userId, String password);
typedef KickDeviceCallback =
    Future<void> Function(String userId, String password, String resource);

class MyDevicesPageMobile extends StatefulWidget {
  const MyDevicesPageMobile({
    super.key,
    this.devices,
    this.loadDevices,
    this.loadStoredDevices,
    this.kickDevice,
  });

  final List<MyDeviceInfo>? devices;
  final LoadDevicesCallback? loadDevices;
  final LoadStoredDevicesCallback? loadStoredDevices;
  final KickDeviceCallback? kickDevice;

  @override
  State<MyDevicesPageMobile> createState() => _MyDevicesPageMobileState();
}

class _MyDevicesPageMobileState extends State<MyDevicesPageMobile> {
  List<MyDeviceInfo> _devices = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reloadDevices(showLoading: true);
  }

  Future<void> _reloadDevices({required bool showLoading}) async {
    if (widget.devices != null) {
      if (showLoading) {
        setState(() {
          _devices = widget.devices!;
          _isLoading = false;
        });
      }
      if (widget.loadDevices == null && widget.loadStoredDevices == null) {
        return;
      }
    } else if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final loadDevices = widget.loadDevices;
      final devices = loadDevices != null
          ? await loadDevices()
          : await _loadDevicesFromStoredCredentials();
      if (!mounted) {
        return;
      }

      setState(() {
        _devices = devices.map(_mapDeviceInfo).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('刷新设备列表失败: $e')));
    }
  }

  Future<void> _handleRefresh() async {
    await _reloadDevices(showLoading: false);
  }

  Future<List<EMDeviceInfo>> _loadDevicesFromStoredCredentials() async {
    final settings = Provider.of<AppSettings?>(context, listen: false);
    final userId = settings?.lastLoginUserId.trim() ?? '';
    final password = settings?.lastLoginPassword.trim() ?? '';
    if (userId.isEmpty || password.isEmpty) {
      return const [];
    }
    return (widget.loadStoredDevices ?? _defaultLoadStoredDevices)(
      userId,
      password,
    );
  }

  Future<List<EMDeviceInfo>> _defaultLoadStoredDevices(
    String userId,
    String password,
  ) {
    return fetchLoggedInDevices(userId: userId, password: password);
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Text(
              '暂无其他登录设备',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList(bool isDark) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder(isDark)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary(isDark).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.devices_outlined,
                color: AppColors.primary(isDark),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    device.deviceName,
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if ((device.sourceLabel ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary(isDark).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      device.sourceLabel!,
                      style: TextStyle(
                        color: AppColors.primary(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if ((device.sourceLabel ?? '').isEmpty)
                  IconButton(
                    tooltip: '踢下线',
                    onPressed: () => _kickDevice(device),
                    icon: Icon(
                      Icons.logout,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DeviceLine(
                    label: 'Resource',
                    value: device.resource.isEmpty ? '无' : device.resource,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _kickDevice(MyDeviceInfo device) async {
    final settings = Provider.of<AppSettings?>(context, listen: false);
    final userId = settings?.lastLoginUserId.trim() ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('缺少登录账号，无法踢设备')));
      return;
    }
    if (device.resource.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('缺少设备 resource，无法踢设备')));
      return;
    }

    final result = await showInputDialog(
      context: context,
      title: '踢下线',
      fields: [InputFieldData(title: '密码', placeholder: '请输入密码', text: '')],
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    final password = result.first.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入密码')));
      return;
    }

    try {
      await (widget.kickDevice ?? _defaultKickDevice)(
        userId,
        password,
        device.resource,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = _devices
            .where((item) => item.resource != device.resource)
            .toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已踢下线 ${device.deviceName}')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('踢设备失败: $e')));
    }
  }

  Future<void> _defaultKickDevice(
    String userId,
    String password,
    String resource,
  ) {
    return kickLoggedInDevice(
      userId: userId,
      password: password,
      resource: resource,
    );
  }

  MyDeviceInfo _mapDeviceInfo(EMDeviceInfo device) {
    return MyDeviceInfo(
      deviceName: (device.deviceName?.trim().isNotEmpty ?? false)
          ? device.deviceName!.trim()
          : (device.resource?.trim().isNotEmpty ?? false)
          ? device.resource!.trim()
          : '未知设备',
      resource: device.resource?.trim() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings().isDarkMode;

    return CommonGradientBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '其他登录设备',
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary(isDark),
                ),
              )
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _devices.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildDeviceList(isDark),
              ),
      ),
    );
  }
}

class _DeviceLine extends StatelessWidget {
  const _DeviceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings().isDarkMode;
    return Text(
      '$label：$value',
      style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 13),
    );
  }
}
