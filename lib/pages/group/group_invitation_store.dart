import 'package:flutter/foundation.dart';

class GroupInvitationStore extends ChangeNotifier {
  GroupInvitationStore._();

  static final GroupInvitationStore instance = GroupInvitationStore._();

  final List<GroupInvitation> _invitations = [];

  List<GroupInvitation> get invitations => List.unmodifiable(_invitations);

  void record(GroupInvitation invitation) {
    _invitations.removeWhere((item) => item.groupId == invitation.groupId);
    _invitations.insert(0, invitation);
    notifyListeners();
  }

  void remove(String groupId) {
    final before = _invitations.length;
    _invitations.removeWhere((item) => item.groupId == groupId);
    if (_invitations.length != before) {
      notifyListeners();
    }
  }

  void clear() {
    if (_invitations.isEmpty) {
      return;
    }
    _invitations.clear();
    notifyListeners();
  }
}

class GroupInvitation {
  const GroupInvitation({
    required this.groupId,
    required this.inviter,
    this.groupName,
    this.reason,
  });

  final String groupId;
  final String? groupName;
  final String inviter;
  final String? reason;

  String get displayName {
    final name = groupName?.trim();
    return name == null || name.isEmpty ? groupId : name;
  }
}
