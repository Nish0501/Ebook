import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  final Map<String, List<dynamic>> bookSections = {
    "Popular Fiction": [],
    "Science & Tech": [],
    "Fantasy & Magic": [],
    "Mystery & Thriller": [],
  };
  bool isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    final List<String> subjects = ["fiction", "science", "fantasy", "mystery"];

    try {
      final List<Future<void>> fetchTasks = [];

      for (int i = 0; i < subjects.length; i++) {
        final sectionTitle = bookSections.keys.elementAt(i);
        final url = Uri.parse(
            "https://openlibrary.org/subjects/${subjects[i]}.json?limit=10");

        fetchTasks.add(http.get(url).timeout(const Duration(seconds: 15)).then((response) {
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (mounted) {
              setState(() {
                bookSections[sectionTitle] = data['works'] ?? [];
              });
            }
          }
        }));
      }

      await Future.wait(fetchTasks);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load books. Pull to refresh.";
        });
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchBooks,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome, Reader!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),

                isLoading
                    ? _buildSkeletonLoading()
                    : Column(
                  children: bookSections.entries.map((entry) =>
                      _BookSection(
                        title: entry.key,
                        books: entry.value,
                      ),
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Column(
      children: List.generate(
        4,
            (index) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 20,
                color: Colors.grey[800],
                margin: const EdgeInsets.only(bottom: 10),
              ),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) => Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookSection extends StatelessWidget {
  final String title;
  final List<dynamic> books;

  const _BookSection({required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          books.isEmpty
              ? const Text(
            "No books available.",
            style: TextStyle(color: Colors.grey),
          )
              : SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return _BookCard(book: book);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final dynamic book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final coverId = book['cover_id'];
    final coverUrl = coverId != null
        ? "https://covers.openlibrary.org/b/id/$coverId-M.jpg"
        : null;
    final title = book['title'] ?? "No Title";
    final bookKey = book['key'] ?? "0"; // Use original key without modification

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/book_details', // Must match your route name exactly
          arguments: {
            'key': bookKey, // Pass the original key
            'title': title,
            'cover': coverUrl ?? "", // Empty string for fallback
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: coverUrl != null
                  ? CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
                  : Image.asset("assets/images/book_placeholder.png"),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 120,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}