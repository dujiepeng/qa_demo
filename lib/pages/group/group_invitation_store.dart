import 'package:flutter/foundation.dart';

class GroupInvitationStore extends ChangeNotifier {
  GroupInvitationStore._();

  static final GroupInvitationStore instance = GroupInvitationStore._();

  final List<GroupInvitation> _invitations = [];
  final List<GroupJoinRequest> _joinRequests = [];

  List<GroupInvitation> get invitations => List.unmodifiable(_invitations);
  List<GroupJoinRequest> get joinRequests => List.unmodifiable(_joinRequests);

  void record(GroupInvitation invitation) {
    _invitations.removeWhere((item) => item.groupId == invitation.groupId);
    _invitations.insert(0, invitation);
    notifyListeners();
  }

  void recordJoinRequest(GroupJoinRequest request) {
    _joinRequests.removeWhere(
      (item) =>
          item.groupId == request.groupId &&
          item.applicant == request.applicant,
    );
    _joinRequests.insert(0, request);
    notifyListeners();
  }

  void remove(String groupId) {
    final before = _invitations.length;
    _invitations.removeWhere((item) => item.groupId == groupId);
    if (_invitations.length != before) {
      notifyListeners();
    }
  }

  void removeJoinRequest(String groupId, String applicant) {
    final before = _joinRequests.length;
    _joinRequests.removeWhere(
      (item) => item.groupId == groupId && item.applicant == applicant,
    );
    if (_joinRequests.length != before) {
      notifyListeners();
    }
  }

  void clear() {
    if (_invitations.isEmpty && _joinRequests.isEmpty) {
      return;
    }
    _invitations.clear();
    _joinRequests.clear();
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

class GroupJoinRequest {
  const GroupJoinRequest({
    required this.groupId,
    required this.applicant,
    this.groupName,
    this.reason,
  });

  final String groupId;
  final String? groupName;
  final String applicant;
  final String? reason;

  String get displayName {
    final name = groupName?.trim();
    return name == null || name.isEmpty ? groupId : name;
  }
}
