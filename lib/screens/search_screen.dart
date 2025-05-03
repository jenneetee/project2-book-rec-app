import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/bottom_nav_bar.dart';
import 'profile_screen.dart';
import 'discussion_screen.dart';
import 'book_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  bool _isLoading = false;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DiscussionScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _searchBooks() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _books = [];
    });

    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=${_searchController.text}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _books = data['items'] ?? [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load books')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildBookItem(dynamic book) {
    final volumeInfo = book['volumeInfo'];
    final title = volumeInfo['title'] ?? 'No Title';
    final authors = (volumeInfo['authors'] as List<dynamic>?)?.join(', ') ?? 'Unknown Author';

    return ListTile(
      leading: const Icon(
        Icons.book,
        size: 50,
        color: Colors.grey, 
      ),
      title: Text(title),
      subtitle: Text(authors),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Books'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or author',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchBooks,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _books.length,
                      itemBuilder: (context, index) => _buildBookItem(_books[index]),
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
