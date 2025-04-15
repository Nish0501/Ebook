import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<void> addBookmark(Map<String, dynamic> bookData) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(bookData['key'])
        .set(bookData);
  }

  Future<void> removeBookmark(String bookKey) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(bookKey)
        .delete();
  }

  Future<bool> isBookBookmarked(String bookKey) async {
    if (userId == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(bookKey)
        .get();

    return doc.exists;
  }
}
