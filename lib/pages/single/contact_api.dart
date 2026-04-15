import 'package:im_flutter_sdk/im_flutter_sdk.dart';

Future<List<EMContact>> fetchContactsFromSdk() {
  return EMClient.getInstance.contactManager.fetchAllContacts();
}

Future<void> addUserToBlockListFromSdk(String userId) {
  return EMClient.getInstance.contactManager.addUserToBlockList(userId);
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
