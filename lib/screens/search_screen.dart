import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:async';
import 'book_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty || query == _lastQuery) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastQuery = query;
    });

    try {
      // Changed to Open Library API
      final response = await http.get(
        Uri.parse("https://openlibrary.org/search.json?q=$query&limit=20"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['docs'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchBooks(query);
    });
  }

  void _navigateToBookDetails(Map<String, dynamic> bookInfo) {
    final coverId = bookInfo['cover_i'];
    final coverUrl = coverId != null
        ? "https://covers.openlibrary.org/b/id/$coverId-M.jpg"
        : '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailsScreen(
          bookKey: bookInfo['key'] ?? '',
          title: bookInfo['title'] ?? 'No Title',
          cover: coverUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Search Books"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.requestFocus();
                    setState(() {
                      _searchResults = [];
                      _hasSearched = false;
                    });
                  },
                )
                    : null,
                hintText: "Search by title, author, or ISBN...",
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _searchBooks,
            ),
            const SizedBox(height: 16),

            // Status Indicators
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else if (_searchResults.isEmpty && _hasSearched)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "No books found. Try a different search.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else if (!_hasSearched)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Search for books by title, author, or keywords",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

            // Search Results
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final book = _searchResults[index];
                  final authors = book['author_name'] != null
                      ? book['author_name'].join(", ")
                      : "Unknown Author";
                  final coverId = book['cover_i'];
                  final thumbnail = coverId != null
                      ? "https://covers.openlibrary.org/b/id/$coverId-S.jpg"
                      : '';

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 0,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: SizedBox(
                        width: 50,
                        height: 70,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: thumbnail.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.book),
                          )
                              : Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.book,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        book['title'] ?? 'Untitled',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authors,
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (book['first_publish_year'] != null)
                            Text(
                              book['first_publish_year'].toString(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                      onTap: () => _navigateToBookDetails(book),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}