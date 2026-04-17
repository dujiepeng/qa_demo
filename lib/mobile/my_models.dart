class MyDeviceInfo {
  const MyDeviceInfo({
    required this.deviceName,
    required this.resource,
    this.sourceLabel,
  });

  final String deviceName;
  final String resource;
  final String? sourceLabel;
}

class MyUserProfile {
  const MyUserProfile({
    required this.nickname,
    required this.birthday,
    required this.email,
  });

  final String nickname;
  final String birthday;
  final String email;

  MyUserProfile copyWith({
    String? nickname,
    String? birthday,
    String? email,
  }) {
    return MyUserProfile(
      nickname: nickname ?? this.nickname,
      birthday: birthday ?? this.birthday,
      email: email ?? this.email,
    );
  }
}
