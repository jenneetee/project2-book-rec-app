import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'discussion_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookDetailsScreen extends StatefulWidget {
  final dynamic book;

  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  int _selectedIndex = 1;
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  String _readingStatus = 'Want to Read';

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
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

  Future<void> _saveReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final bookId = widget.book['id'];
    final volumeInfo = widget.book['volumeInfo'];
    final title = volumeInfo['title'] ?? '';
    final authors = (volumeInfo['authors'] as List<dynamic>?)?.join(', ') ?? '';
    final reviewText = _reviewController.text.trim();

    final reviewData = {
      'rating': _rating,
      'review': reviewText,
      'readingStatus': _readingStatus,
      'timestamp': FieldValue.serverTimestamp(),
      'userEmail': user.email,
      'title': title,
      'authors': authors,
    };

    // 1. Save to book-centric reviews
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(bookId)
        .collection('userReviews')
        .doc(userId)
        .set(reviewData);

    // 2. Save to user profile under reviews
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .doc(bookId)
        .set(reviewData);

    // 3. Save reading list info under user profile
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('readingList')
        .doc(bookId)
        .set({
      'title': title,
      'authors': authors,
      'status': _readingStatus,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review and reading list updated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final volumeInfo = widget.book['volumeInfo'];
    final title = volumeInfo['title'] ?? 'No Title';
    final authors = (volumeInfo['authors'] as List<dynamic>?)?.join(', ') ?? 'Unknown Author';
    final description = volumeInfo['description'] ?? 'No description available.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const Icon(
                Icons.book,
                size: 200,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(authors, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(description),
            const SizedBox(height: 24),
            const Text('Rate this book:'),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text('Add to Reading List:'),
            DropdownButton<String>(
              value: _readingStatus,
              items: <String>['Want to Read', 'Currently Reading', 'Finished']
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _readingStatus = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Write a review',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _saveReview,
                child: const Text('Submit Review'),
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
