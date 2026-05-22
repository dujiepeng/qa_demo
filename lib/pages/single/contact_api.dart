import 'package:im_flutter_sdk/im_flutter_sdk.dart';

Future<List<EMContact>> fetchContactsFromSdk() {
  return EMClient.getInstance.contactManager.fetchAllContacts();
}

Future<List<String>> fetchSelfIdsOnOtherPlatformFromSdk() {
  return EMClient.getInstance.contactManager.getSelfIdsOnOtherPlatform();
}

Future<List<EMDeviceInfo>> fetchLoggedInDevices({
  required String userId,
  required String password,
}) {
  return EMClient.getInstance.fetchLoggedInDevices(
    userId: userId,
    pwdOrToken: password,
    isPwd: true,
  );
}

Future<void> kickLoggedInDevice({
  required String userId,
  required String password,
  required String resource,
}) {
  return EMClient.getInstance.kickDevice(
    userId: userId,
    pwdOrToken: password,
    resource: resource,
    isPwd: true,
  );
}

Future<void> addUserToBlockListFromSdk(String userId) {
  return EMClient.getInstance.contactManager.addUserToBlockList(userId);
}

Future<void> setContactRemarkFromSdk({
  required String userId,
  required String remark,
}) {
  return EMClient.getInstance.contactManager.setContactRemark(
    userId: userId,
    remark: remark,
  );
}

Future<List<String>> fetchSubscribedMembersFromSdk() {
  return EMClient.getInstance.presenceManager.fetchSubscribedMembers();
}

Future<List<EMPresence>> subscribePresenceFromSdk(String userId) {
  return EMClient.getInstance.presenceManager.subscribe(
    members: [userId],
    expiry: 3600,
  );
}

Future<void> unsubscribePresenceFromSdk(String userId) {
  return EMClient.getInstance.presenceManager.unsubscribe(members: [userId]);
}

Future<List<EMPresence>> queryPresenceFromSdk(String userId) {
  return EMClient.getInstance.presenceManager.fetchPresenceStatus(
    members: [userId],
  );
}

Future<List<EMPresence>> queryPresenceForMembersFromSdk(
  List<String> userIds,
) {
  return EMClient.getInstance.presenceManager.fetchPresenceStatus(
    members: userIds,
  );
}
