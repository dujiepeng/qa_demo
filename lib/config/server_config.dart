class ServerEnvironment {
  final String name;
  final String appKey;
  final String? restServer;
  final String? msyncServer;
  final int? msyncPort;
  final String? wsServer;
  final int? wsPort;
  final String? wsPath;
  final String? dnsUrl;
  final bool? isMsync;
  final bool? enableTls;

  const ServerEnvironment({
    required this.name,
    required this.appKey,
    this.restServer,
    this.msyncServer,
    this.msyncPort,
    this.wsServer,
    this.wsPort,
    this.wsPath,
    this.dnsUrl,
    this.isMsync,
    this.enableTls,
  });

  // TKE 集群默认配置
  static const ServerEnvironment tke = ServerEnvironment(
    name: 'TKE',
    appKey: 'easemob-demo#tke-sdb', // 替换为真实的 TKE AppKey
    restServer: 'https://tke-sdb-a1.easemob.com', // 替换为真实的 TKE REST
    msyncServer: 'tke-sdb-msync-im1.easemob.com', // 替换为真实的 TKE msync
    msyncPort: 6717,
    wsServer: 'tke-sdb-im-api-wechat.easemob.com', // 替换为真实的 TKE websocket
    wsPort: 443,
  );

  // qa隔舱 集群默认配置
  static const ServerEnvironment qaCabin = ServerEnvironment(
    name: 'qa隔舱',
    appKey: 'easemob-demo#qatest',
    restServer: 'http://10.202.1.60:8081',
    msyncServer: '10.202.1.60',
    msyncPort: 4300,
    wsServer: '10.202.1.60',
    wsPort: 4717,
    wsPath: '/websocket',
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
    appKey: 'easemob-demo#wang',
  );

  static const List<ServerEnvironment> environments = [
    qaCabin,
    tke,
    sandbox,
    online,
  ];
}
