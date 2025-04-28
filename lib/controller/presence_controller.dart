import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class PresenceController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;

  Future<void> setupPresence() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final DatabaseReference statusRef = _db.ref('status/${user.uid}');

    final isOnline = {'isOnline': true, 'lastSeen': ServerValue.timestamp};

    final isOffline = {'isOnline': false, 'lastSeen': ServerValue.timestamp};

    // Set online now
    await statusRef.set(isOnline);

    // Set offline automatically if the connection drops or app is closed
    await statusRef.onDisconnect().set(isOffline);
  }

  Future<void> setOfflineStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final DatabaseReference statusRef = _db.ref('status/${user.uid}');
    final isOffline = {'isOnline': false, 'lastSeen': ServerValue.timestamp};

    await statusRef.set(isOffline);
  }
}
