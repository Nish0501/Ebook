import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'reader_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookKey;
  final String title;
  final String cover;

  const BookDetailsScreen({
    super.key,
    required this.bookKey,
    required this.title,
    required this.cover,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? bookDetails;
  bool hasFullContent = false;
  String? readOnlineUrl;
  bool isBookmarked = false;
  String selectedCategory = 'General';
  List<String> authorNames = [];

  final List<String> categories = [
    'Fiction',
    'Science',
    'Fantasy',
    'Biography',
    'General'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchBookDetails(),
      _checkIfBookmarked(),
    ]);
  }

  Future<void> _fetchBookDetails() async {
    try {
      final cleanKey = widget.bookKey.replaceAll('/works/', '').replaceAll('/', '');
      final url = Uri.parse("https://openlibrary.org/works/$cleanKey.json");

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Get author names
        if (data['authors'] != null) {
          authorNames = await _getAuthorNames(data['authors']);
        }

        if (mounted) {
          setState(() {
            bookDetails = data;
            hasFullContent = (data['lending_edition'] ?? data['ocaid']) != null;
            readOnlineUrl = hasFullContent
                ? "https://openlibrary.org/books/${data['lending_edition'] ?? data['ocaid']}"
                : "https://openlibrary.org${data['key']}";

            // Auto-detect category
            if (data['subjects'] != null) {
              final subjects = data['subjects'].map((s) => s.toString().toLowerCase()).toList();
              if (subjects.any((s) => s.contains('fiction'))) selectedCategory = 'Fiction';
              if (subjects.any((s) => s.contains('science'))) selectedCategory = 'Science';
              if (subjects.any((s) => s.contains('fantasy'))) selectedCategory = 'Fantasy';
              if (subjects.any((s) => s.contains('biography'))) selectedCategory = 'Biography';
            }

            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<List<String>> _getAuthorNames(List<dynamic> authors) async {
    List<String> names = [];

    try {
      for (var author in authors) {
        // Try to get name directly
        if (author['name'] != null) {
          names.add(author['name']);
        }
        // Otherwise fetch from author key
        else if (author['author'] != null && author['author']['key'] != null) {
          final authorKey = author['author']['key'].replaceAll('/authors/', '');
          final url = Uri.parse("https://openlibrary.org/authors/$authorKey.json");
          final response = await http.get(url).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['name'] != null) {
              names.add(data['name']);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching author names: $e");
    }

    return names.isEmpty ? ['Unknown author'] : names;
  }

  Future<void> _checkIfBookmarked() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks') ?? [];

    for (final bookmark in bookmarks) {
      final data = jsonDecode(bookmark) as Map<String, dynamic>;
      if (data['key'] == widget.bookKey) {
        setState(() {
          isBookmarked = true;
          selectedCategory = data['category'] ?? 'General';
        });
        break;
      }
    }
  }

  String _getBookDataJson() {
    return jsonEncode({
      'key': widget.bookKey,
      'title': widget.title,
      'cover': widget.cover,
      'category': selectedCategory,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks') ?? [];
    final bookData = _getBookDataJson();

    setState(() {
      isBookmarked = !isBookmarked;
      if (isBookmarked) {
        bookmarks.removeWhere((b) => jsonDecode(b)['key'] == widget.bookKey);
        bookmarks.add(bookData);
      } else {
        bookmarks.removeWhere((b) => jsonDecode(b)['key'] == widget.bookKey);
      }
    });

    await prefs.setStringList('bookmarks', bookmarks);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookmarked
            ? "Bookmarked in $selectedCategory!"
            : "Removed from bookmarks"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showCategoryDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Category"),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) => RadioListTile(
              title: Text(categories[index]),
              value: categories[index],
              groupValue: selectedCategory,
              onChanged: (value) {
                setState(() => selectedCategory = value.toString());
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              if (isBookmarked) {
                _toggleBookmark();
              } else {
                _showCategoryDialog().then((_) => _toggleBookmark());
              }
            },
            tooltip: isBookmarked ? "Remove bookmark" : "Add to library",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _buildBookCover(),
            ),
            const SizedBox(height: 20),
            _buildTitleSection(),
            if (authorNames.isNotEmpty) _buildAuthorsSection(),
            _buildDescriptionSection(),
            const SizedBox(height: 20),
            if (isBookmarked)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.category, size: 16, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(
                      'Category: $selectedCategory',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: _showCategoryDialog,
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCover() {
    final coverUrl = widget.cover.isNotEmpty
        ? widget.cover
        : bookDetails?['covers'] != null
        ? "https://covers.openlibrary.org/b/id/${bookDetails!['covers'][0]}-M.jpg"
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: coverUrl != null
            ? CachedNetworkImage(
          imageUrl: coverUrl,
          width: 150,
          height: 220,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _buildPlaceholderCover(),
        )
            : _buildPlaceholderCover(),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 150,
      height: 220,
      color: Colors.grey[800],
      child: const Icon(Icons.book, size: 50, color: Colors.white70),
    );
  }

  Widget _buildTitleSection() {
    return Text(
      widget.title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAuthorsSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        'By ${authorNames.join(', ')}',
        style: const TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _getDescriptionText(),
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  String _getDescriptionText() {
    if (bookDetails?['description'] == null) return 'No description available';

    if (bookDetails!['description'] is String) {
      return bookDetails!['description'];
    } else if (bookDetails!['description'] is Map) {
      return bookDetails!['description']['value'] ?? 'No description available';
    }
    return 'No description available';
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 20),
        if (hasFullContent) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToReader,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book),
                  SizedBox(width: 10),
                  Text("Read in App", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _launchReadOnline,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_browser),
                SizedBox(width: 10),
                Text("Read Online", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToReader() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          bookKey: widget.bookKey,
          title: widget.title, // Pass the title here
        ),
      ),
    );
  }

  Future<void> _launchReadOnline() async {
    if (readOnlineUrl == null) return;

    try {
      await launchUrl(
        Uri.parse(readOnlineUrl!),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Could not launch browser")),
        );
      }
    }
  }
}