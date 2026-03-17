import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../config/server_config.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage>
    with SingleTickerProviderStateMixin {
  final _settings = AppSettings();
  late TabController _tabController;

  // 用于维护三个环境的控制器
  final Map<String, _EnvControllers> _controllers = {};

  final List<ServerEnvironment> _envs = ServerEnvironment.environments;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    for (int i = 0; i < _envs.length; i++) {
      if (_settings.activeEnvName == _envs[i].name) {
        initialIndex = i;
        break;
      }
    }
    _tabController = TabController(
      length: _envs.length,
      initialIndex: initialIndex,
      vsync: this,
    );

    // 为每个环境初始化一个控制器组
    for (int i = 0; i < _envs.length; i++) {
      final env = _envs[i];
      // 如果 _settings 里有保存的该环境的值，就用保存的值，否则用默认值
      final savedEnvStr = _settings.getCustomEnv(env.name);
      final appKey = savedEnvStr?['appKey'] ?? env.appKey;
      final restServer = savedEnvStr?['restServer'] ?? env.restServer;
      final msyncServer = savedEnvStr?['msyncServer'] ?? env.msyncServer;
      final msyncPort =
          savedEnvStr?['msyncPort']?.toString() ?? env.msyncPort.toString();
      final wsServer = savedEnvStr?['wsServer'] ?? env.wsServer;
      final wsPort =
          savedEnvStr?['wsPort']?.toString() ?? env.wsPort.toString();
      final isMsync = savedEnvStr?['isMsync'] ?? env.isMsync;

      _controllers[env.name] = _EnvControllers(
        appKeyController: TextEditingController(text: appKey),
        restServerController: TextEditingController(text: restServer),
        msyncServerController: TextEditingController(text: msyncServer),
        msyncPortController: TextEditingController(text: msyncPort),
        wsServerController: TextEditingController(text: wsServer),
        wsPortController: TextEditingController(text: wsPort),
        isMsync: isMsync,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    // 获取当前选中的 Tab 的环境
    final activeEnv = _envs[_tabController.index];
    final ctrl = _controllers[activeEnv.name]!;

    // 存储当前选中的环境名称与值
    final customData = {
      'appKey': ctrl.appKeyController.text.trim(),
      'restServer': ctrl.restServerController.text.trim(),
      'msyncServer': ctrl.msyncServerController.text.trim(),
      'msyncPort': int.tryParse(ctrl.msyncPortController.text.trim()) ?? 6717,
      'wsServer': ctrl.wsServerController.text.trim(),
      'wsPort': int.tryParse(ctrl.wsPortController.text.trim()) ?? 443,
      'isMsync': ctrl.isMsync,
    };

    // 保存到 AppSettings
    _settings.saveCustomEnv(activeEnv.name, customData);
    _settings.activeEnvName = activeEnv.name; // 记录当前选择的集群

    // 因为这里强指定了环境，所以以前的 useCustom 状态就一直 true
    // (必须在设置 _settings.appKey 之前设置，否则 setter 内部可能会失效)
    _settings.useCustomAppKey = true;
    _settings.useCustomServer = true;

    // 依然修改 AppSettings 老字段，以便于兼容之前的逻辑和历史记录功能
    _settings.appKey = customData['appKey'] as String;
    _settings.restServer = customData['restServer'] as String;
    // 将 msync 对应给 imServer 等，这里先向后兼容老代码
    _settings.imServer = customData['msyncServer'] as String;
    _settings.imPort = customData['msyncPort'] as int;

    // 保存到历史记录中
    _settings.addCurrentConfigToHistory();

    // 每次点击保存总是视作环境改变，并要求重启
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('配置已更新'),
          content: Text('已保存【${activeEnv.name}】集群配置。\n更改配置需要重启app后才生效。'),
          actions: [
            TextButton(
              onPressed: () async {
                _settings.isDirty = true;
                _settings.isLoggedIn = false;
                await _settings.saveSettings();
                exit(0);
              },
              child: const Text('确认重启'),
            ),
          ],
        ),
      );
    }
  }

  void _applyConfig(ServerConfig config) {
    // 同步到设置对象并触发通知
    _settings.applyConfig(config);

    // 同步到 UI 表单控制器
    final ctrl = _controllers[config.envName];
    if (ctrl != null) {
      ctrl.appKeyController.text = config.appKey;
      ctrl.restServerController.text = config.restServer;
      ctrl.msyncServerController.text = config.msyncServer;
      ctrl.msyncPortController.text = config.msyncPort.toString();
      ctrl.wsServerController.text = config.wsServer;
      ctrl.wsPortController.text = config.wsPort.toString();
      ctrl.isMsync = config.isMsync;

      // 切换到对应的 tab
      final index = _envs.indexWhere((e) => e.name == config.envName);
      if (index != -1) {
        _tabController.index = index;
      }

      setState(() {});
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('配置已加载，请点击保存记录生效')));
    }
  }

  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = _settings.isDarkMode;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '配置历史',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _settings.configHistory.isEmpty
                        ? Center(
                            child: Text(
                              '暂无历史记录',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _settings.configHistory.length,
                            itemBuilder: (context, index) {
                              final config = _settings.configHistory[index];
                              final subTitle =
                                  '集群: ${config.envName} | 连接: ${config.isMsync ? 'TCP' : 'WebSocket'}';
                              return ListTile(
                                title: Text(
                                  config.appKey,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  subTitle,
                                  style: TextStyle(
                                    color: AppColors.textSecondary(isDark),
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (contextDialog) {
                                      return AlertDialog(
                                        backgroundColor: isDark
                                            ? const Color(0xFF1C1C1E)
                                            : Colors.white,
                                        title: Text(
                                          '配置详情',
                                          style: TextStyle(
                                            color: AppColors.textPrimary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '集群: ${config.envName}',
                                                style: TextStyle(
                                                  color: AppColors.textPrimary(
                                                    isDark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'AppKey: ${config.appKey}',
                                                style: TextStyle(
                                                  color: AppColors.textPrimary(
                                                    isDark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '连接方式: ${config.isMsync ? 'TCP' : 'WebSocket'}',
                                                style: TextStyle(
                                                  color: AppColors.textPrimary(
                                                    isDark,
                                                  ),
                                                ),
                                              ),
                                              if (config.envName != '线上') ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  'REST: ${config.restServer}',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textPrimary(
                                                          isDark,
                                                        ),
                                                  ),
                                                ),
                                                if (config.isMsync) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'MSYNC: ${config.msyncServer}:${config.msyncPort}',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textPrimary(
                                                            isDark,
                                                          ),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'WebSocket: ${config.wsServer}:${config.wsPort}',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textPrimary(
                                                            isDark,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(contextDialog),
                                            child: Text(
                                              '取消',
                                              style: TextStyle(
                                                color: AppColors.textSecondary(
                                                  isDark,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary(isDark),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(
                                                contextDialog,
                                              ); // Close AlertDialog
                                              Navigator.pop(
                                                context,
                                              ); // Close BottomSheet
                                              _applyConfig(config);
                                              // 直接执行切换重载流程
                                              _handleSave();
                                            },
                                            child: const Text(
                                              '切换',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.withValues(alpha: 0.7),
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      _settings.removeConfigFromHistory(config);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.backgroundStart(isDark),
      appBar: AppBar(
        title: Text(
          '服务器设置',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '历史配置',
            onPressed: _showHistoryDialog,
          ),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary(isDark),
          labelColor: AppColors.primary(isDark),
          unselectedLabelColor: AppColors.textSecondary(isDark),
          tabs: _envs.map((e) => Tab(text: e.name)).toList(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundStart(isDark),
              AppColors.backgroundEnd(isDark),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _envs
                    .map((env) => _buildEnvTab(env, isDark))
                    .toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.backgroundEnd(isDark).withValues(alpha: 0.5),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(isDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '保存并使用该配置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvTab(ServerEnvironment env, bool isDark) {
    final ctrl = _controllers[env.name]!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        _buildSectionTitle('${env.name} Cluster - AppKey', isDark),
        _buildInputItem(
          controller: ctrl.appKeyController,
          hintText: 'AppKey',
          isDark: isDark,
        ),

        if (env.name != '线上') ...[
          const SizedBox(height: 20),
          _buildSectionTitle('REST 配置', isDark),
          _buildInputItem(
            controller: ctrl.restServerController,
            hintText: 'REST 服务器地址',
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('MSYNC 配置', isDark),
          _buildSwitchItem(
            title: '使用 MSYNC 连接',
            icon: Icons.link,
            value: ctrl.isMsync,
            onChanged: (val) {
              setState(() {
                ctrl.isMsync = val;
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildInputItem(
            controller: ctrl.msyncServerController,
            hintText: 'MSYNC 服务器地址',
            isDark: isDark,
            enabled: ctrl.isMsync,
          ),
          const SizedBox(height: 10),
          _buildInputItem(
            controller: ctrl.msyncPortController,
            hintText: 'MSYNC 端口',
            keyboardType: TextInputType.number,
            isDark: isDark,
            enabled: ctrl.isMsync,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('WebSocket 配置', isDark),
          _buildSwitchItem(
            title: '使用 WebSocket 连接',
            icon: Icons.language,
            value: !ctrl.isMsync,
            onChanged: (val) {
              setState(() {
                ctrl.isMsync = !val;
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildInputItem(
            controller: ctrl.wsServerController,
            hintText: 'WebSocket 服务器地址',
            isDark: isDark,
            enabled: !ctrl.isMsync,
          ),
          const SizedBox(height: 10),
          _buildInputItem(
            controller: ctrl.wsPortController,
            hintText: 'WebSocket 端口',
            keyboardType: TextInputType.number,
            isDark: isDark,
            enabled: !ctrl.isMsync,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary(isDark), size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 16,
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary(isDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }

  Widget _buildInputItem({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    required bool isDark,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(
          color: enabled
              ? AppColors.textPrimary(isDark)
              : AppColors.textSecondary(isDark),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

class _EnvControllers {
  final TextEditingController appKeyController;
  final TextEditingController restServerController;
  final TextEditingController msyncServerController;
  final TextEditingController msyncPortController;
  final TextEditingController wsServerController;
  final TextEditingController wsPortController;
  bool isMsync;

  _EnvControllers({
    required this.appKeyController,
    required this.restServerController,
    required this.msyncServerController,
    required this.msyncPortController,
    required this.wsServerController,
    required this.wsPortController,
    required this.isMsync,
  });

  void dispose() {
    appKeyController.dispose();
    restServerController.dispose();
    msyncServerController.dispose();
    msyncPortController.dispose();
    wsServerController.dispose();
    wsPortController.dispose();
  }
}
