import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  // Load bookmarks from SharedPreferences
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedBookmarks = prefs.getStringList('bookmarks') ?? [];

    setState(() {
      bookmarks = savedBookmarks
          .map((bookmark) => json.decode(bookmark) as Map<String, dynamic>)
          .toList();
    });
  }

  // Remove bookmark function
  Future<void> _removeBookmark(int index) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      bookmarks.removeAt(index);
    });

    List<String> updatedBookmarks =
    bookmarks.map((bookmark) => jsonEncode(bookmark)).toList();
    await prefs.setStringList('bookmarks', updatedBookmarks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My Bookmarks"),
        backgroundColor: Colors.black,
      ),
      body: bookmarks.isEmpty
          ? const Center(
        child: Text(
          "No bookmarks yet!",
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      )
          : ListView.builder(
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final book = bookmarks[index];

          return ListTile(
            leading: Image.network(
              book['imageLinks'] != null
                  ? book['imageLinks']['thumbnail']
                  : 'assets/images/book_cover_placeholder.png',
              width: 50,
              height: 70,
              fit: BoxFit.cover,
            ),
            title: Text(
              book['title'] ?? "No Title",
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              book['authors'] != null
                  ? book['authors'].join(", ")
                  : "Unknown Author",
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _removeBookmark(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bookmark removed!")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
