import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'book_details_screen.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<MyLibraryScreen> {
  List<Map<String, dynamic>> bookmarkedBooks = [];
  bool isLoading = true;
  bool isGridView = false; // Toggle between grid and list view
  String sortBy = 'recent'; // Sorting options: recent, title, author

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks') ?? [];

    setState(() {
      bookmarkedBooks = bookmarks.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
      _sortBooks();
      isLoading = false;
    });
  }

  void _sortBooks() {
    bookmarkedBooks.sort((a, b) {
      switch (sortBy) {
        case 'title':
          return (a['title'] ?? '').compareTo(b['title'] ?? '');
        case 'author':
          return (a['authors']?.join(', ') ?? '').compareTo(b['authors']?.join(', ') ?? '');
        case 'recent':
        default:
          return (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? '');
      }
    });
  }

  Future<void> _removeBookmark(String bookKey) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bookmark'),
        content: const Text('Are you sure you want to remove this bookmark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final prefs = await SharedPreferences.getInstance();
      final updatedBookmarks = bookmarkedBooks
          .where((book) => book['key'] != bookKey)
          .map((book) => jsonEncode(book))
          .toList();

      await prefs.setStringList('bookmarks', updatedBookmarks);
      _loadBookmarks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearAllBookmarks() async {
    bool confirmClear = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Bookmarks'),
        content: const Text('Are you sure you want to remove all bookmarks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmClear == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bookmarks');
      _loadBookmarks();
    }
  }

  Map<String, List<Map<String, dynamic>>> get _booksByCategory {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final book in bookmarkedBooks) {
      final category = book['category'] ?? 'Uncategorized';
      map.putIfAbsent(category, () => []).add(book);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => isGridView = !isGridView),
            tooltip: isGridView ? 'List view' : 'Grid view',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortBy = value;
                _sortBooks();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recent',
                child: Text('Sort by Recent'),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Text('Sort by Title'),
              ),
              const PopupMenuItem(
                value: 'author',
                child: Text('Sort by Author'),
              ),
            ],
          ),
          if (bookmarkedBooks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: _clearAllBookmarks,
              tooltip: 'Clear all bookmarks',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarkedBooks.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadBookmarks,
        child: isGridView ? _buildGridView() : _buildListView(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Your library is empty',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            'Bookmark books to see them here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: bookmarkedBooks.length,
      itemBuilder: (context, index) {
        final book = bookmarkedBooks[index];
        return _buildBookCard(book, true);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _booksByCategory.length,
      itemBuilder: (context, index) {
        final category = _booksByCategory.keys.elementAt(index);
        final books = _booksByCategory[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...books.map((book) => _buildBookCard(book, false)),
          ],
        );
      },
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, bool isGrid) {
    return Card(
      color: Colors.grey[900],
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _navigateToDetails(book),
        child: isGrid ? _buildGridItem(book) : _buildListItem(book),
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> book) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildBookCover(book['cover']),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book['title'] ?? 'Untitled',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book['authors']?.join(', ') ?? 'Unknown Author',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> book) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildBookCover(book['cover']),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'Untitled',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book['authors']?.join(', ') ?? 'Unknown Author',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${book['category'] ?? 'General'}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeBookmark(book['key']),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover(String? coverUrl) {
    if (coverUrl?.isNotEmpty ?? false) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(Icons.book, color: Colors.white70),
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.book, color: Colors.white70),
      ),
    );
  }

  void _navigateToDetails(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailsScreen(
          bookKey: book['key'],
          title: book['title'],
          cover: book['cover'],
        ),
      ),
    );
  }
}


