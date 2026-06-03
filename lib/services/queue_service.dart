import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QueueService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Generate token - checks if user already has one first
  Future<int> generateToken(String userId) async {
    // Check if user already has a waiting token
    final existing = await _db
        .collection('tokens')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'waiting')
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first['tokenNumber'];
    }

    // Get and increment counter atomically
    final counterRef = _db.collection('queue_counter').doc('counter');
    int newToken = 1;

    await _db.runTransaction((transaction) async {
      final counterSnap = await transaction.get(counterRef);
      if (counterSnap.exists) {
        newToken = (counterSnap['lastToken'] ?? 0) + 1;
      }
      transaction.set(counterRef, {
        'lastToken': newToken,
        'currentToken': counterSnap.exists
            ? (counterSnap['currentToken'] ?? 0)
            : 0,
      }, SetOptions(merge: true));
    });

    // Save token to Firestore
    await _db.collection('tokens').add({
      'userId': userId,
      'tokenNumber': newToken,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });

    return newToken;
  }

  // Get current serving token - real time
  Stream<int> getCurrentToken() {
    return _db
        .collection('queue_counter')
        .doc('counter')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0;
      return (doc['currentToken'] ?? 0) as int;
    });
  }

  // Get user's active token - real time
  Stream<int?> getUserToken(String userId) {
    return _db
        .collection('tokens')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return snap.docs.first['tokenNumber'] as int;
    });
  }

  // People ahead = waiting tokens with smaller number than mine
  Stream<int> getPeopleAhead(int myToken) {
    return _db
        .collection('tokens')
        .where('status', isEqualTo: 'waiting')
        .where('tokenNumber', isLessThan: myToken)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Admin: serve next
  Future<void> serveNext() async {
    final counterRef = _db.collection('queue_counter').doc('counter');

    await _db.runTransaction((transaction) async {
      final counterSnap = await transaction.get(counterRef);
      int current = counterSnap.exists ? (counterSnap['currentToken'] ?? 0) : 0;
      int next = current + 1;

      transaction.set(counterRef, {
        'currentToken': next,
        'lastToken': counterSnap.exists ? (counterSnap['lastToken'] ?? 0) : 0,
      });
    });

    // Mark that token as served
    final counterSnap = await counterRef.get();
    int current = counterSnap['currentToken'];

    final tokenQuery = await _db
        .collection('tokens')
        .where('tokenNumber', isEqualTo: current)
        .where('status', isEqualTo: 'waiting')
        .get();

    for (var doc in tokenQuery.docs) {
      await doc.reference.update({'status': 'served'});
    }
  }

  // Reset everything
  Future<void> resetQueue() async {
    await _db.collection('queue_counter').doc('counter').set({
      'currentToken': 0,
      'lastToken': 0,
    });

    final tokens = await _db.collection('tokens').get();
    for (var doc in tokens.docs) {
      await doc.reference.delete();
    }
  }
}