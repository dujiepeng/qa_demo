class ServerEnvironment {
  final String name;
  final String appKey;
  final String restServer;
  final String msyncServer;
  final int msyncPort;
  final String wsServer;
  final int wsPort;
  final bool isMsync;

  const ServerEnvironment({
    required this.name,
    required this.appKey,
    required this.restServer,
    required this.msyncServer,
    required this.msyncPort,
    required this.wsServer,
    required this.wsPort,
    this.isMsync = true,
  });

  // TKE 集群默认配置
  static const ServerEnvironment tke = ServerEnvironment(
    name: 'TKE',
    appKey: 'easemob-demo#tke-sdb', // 替换为真实的 TKE AppKey
    restServer: 'http://tke-sdb-a1.easemob.com:80', // 替换为真实的 TKE REST
    msyncServer: 'tke-sdb-msync-im1.easemob.com', // 替换为真实的 TKE msync
    msyncPort: 6717,
    wsServer: 'tke-sdb-im-api-wechat.easemob.com', // 替换为真实的 TKE websocket
    wsPort: 443,
  );

  // 开发沙箱 集群默认配置
  static const ServerEnvironment sandbox = ServerEnvironment(
    name: '开发沙箱',
    appKey: 'easemob-demo#chatlist', // 替换为真实的沙箱 AppKey
    restServer: 'http://a1-hsb.easemob.com', // 替换为真实的沙箱 REST
    msyncServer: '81.70.142.13', // 替换为真实的沙箱 msync
    msyncPort: 4300,
    wsServer: 'im-api-new-hsb.easemob.com', // 替换为真实的沙箱 websocket
    wsPort: 443,
  );

  // ebs 集群配置（只有 AppKey 可配置）
  static const ServerEnvironment online = ServerEnvironment(
    name: 'ebs',
    appKey: 'easemob#easeim',
    restServer: '',
    msyncServer: '',
    msyncPort: 0,
    wsServer: '',
    wsPort: 0,
  );

  static const List<ServerEnvironment> environments = [tke, sandbox, online];
}
