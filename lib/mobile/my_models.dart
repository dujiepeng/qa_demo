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
    this.avatarUrl = '',
    this.phone = '',
    this.gender = 0,
    this.sign = '',
    this.ext = '',
  });

  final String nickname;
  final String birthday;
  final String email;
  final String avatarUrl;
  final String phone;
  final int gender;
  final String sign;
  final String ext;

  MyUserProfile copyWith({
    String? nickname,
    String? birthday,
    String? email,
    String? avatarUrl,
    String? phone,
    int? gender,
    String? sign,
    String? ext,
  }) {
    return MyUserProfile(
      nickname: nickname ?? this.nickname,
      birthday: birthday ?? this.birthday,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      sign: sign ?? this.sign,
      ext: ext ?? this.ext,
    );
  }
}
