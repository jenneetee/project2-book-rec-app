import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../widgets/bottom_nav_bar.dart';
import 'search_screen.dart';
import 'discussion_screen.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User? _user;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _readingList = [];
  List<Map<String, dynamic>> _groups = [];
  
// Add this function in _ProfileScreenState:
String generateGravatarUrl(String email) {
  final normalizedEmail = email.trim().toLowerCase();
  final emailBytes = utf8.encode(normalizedEmail);
  final digest = md5.convert(emailBytes);
  return 'https://www.gravatar.com/avatar/$digest?d=identicon';
}


final Map<String, List<String>> _genreSuggestions = {
  'Fantasy': [
    'The Hobbit',
    'Harry Potter',
    'Mistborn',
    'The Name of the Wind',
    'The Way of Kings',
    'A Song of Ice and Fire'
  ],
  'Science Fiction': [
    'Dune',
    'Ender\'s Game',
    'Neuromancer',
    'Snow Crash',
    'Foundation',
    'The Martian'
  ],
  'Mystery': [
    'Gone Girl',
    'Sherlock Holmes',
    'The Girl with the Dragon Tattoo',
    'The Da Vinci Code',
    'Big Little Lies',
    'In the Woods'
  ],
  'Romance': [
    'Pride and Prejudice',
    'Me Before You',
    'Outlander',
    'The Notebook',
    'Red, White & Royal Blue',
    'The Hating Game'
  ],
  'Horror': [
    'It',
    'The Shining',
    'The Haunting of Hill House',
    'Pet Sematary',
    'Bird Box',
    'The Exorcist'
  ],
  'Non-fiction': [
    'Sapiens',
    'Educated',
    'Atomic Habits',
    'Becoming',
    'The Power of Habit',
    'Can’t Hurt Me'
  ],
  'Historical': [
    'The Book Thief',
    'All the Light We Cannot See',
    'The Nightingale',
    'Beneath a Scarlet Sky',
    'The Alice Network',
    'The Tattooist of Auschwitz'
  ],
  'Thriller': [
    'The Silent Patient',
    'The Woman in the Window',
    'Behind Closed Doors',
    'The Girl on the Train',
    'The Couple Next Door',
    'The Chain'
  ],
  'Young Adult': [
    'The Fault in Our Stars',
    'The Hunger Games',
    'Divergent',
    'Six of Crows',
    'A Court of Thorns and Roses',
    'Shadow and Bone'
  ],
};





String? _selectedGenre;
final List<String> _genres = [
  'Fantasy',
  'Science Fiction',
  'Mystery',
  'Romance',
  'Horror',
  'Non-fiction',
  'Historical',
  'Thriller',
  'Young Adult',
];


List<String> _aiSuggestions = [];


  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _fetchUserDetails();
    }
  }

Future<void> _fetchUserDetails() async {
  if (_user == null) return;

  final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
  final customImage = userDoc.data()?['profileImage'];

  setState(() {
    if (customImage != null && customImage.isNotEmpty) {
      _profileImageUrl = customImage;
    } else {
      final email = _user!.email!;
      _profileImageUrl = generateGravatarUrl(email);
    }
  });

  final reviewsSnapshot = await _firestore
      .collection('users')
      .doc(_user!.uid)
      .collection('reviews')
      .get();
final genre = userDoc.data()?['preferredGenre'];

setState(() {
  if (customImage != null && customImage.isNotEmpty) {
    _profileImageUrl = customImage;
  } else {
    final email = _user!.email!;
    _profileImageUrl = generateGravatarUrl(email);
  }
  _selectedGenre = genre; // Load saved genre
  _aiSuggestions = _genreSuggestions[_selectedGenre!] ?? [];

});


  final userReviews = reviewsSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'bookId': doc.id,
      'title': data['title'] ?? 'Untitled',
      'rating': data['rating'] ?? 0,
      'review': data['review'] ?? '',
      'status': data['readingStatus'] ?? '',
    };
  }).toList();

  final readingListSnapshot = await _firestore
      .collection('users')
      .doc(_user!.uid)
      .collection('readingList')
      .get();

  final readingList = readingListSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'bookId': doc.id,
      'title': data['title'] ?? 'Untitled',
      'status': data['status'] ?? '',
    };
  }).toList();

  final joinedGroupsSnapshot = await _firestore
      .collection('users')
      .doc(_user!.uid)
      .collection('joinedGroups')
      .get();

  final groups = joinedGroupsSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'groupId': doc.id,
      'name': data['name'] ?? 'Unnamed Group',
      'description': data['description'] ?? '',
    };
  }).toList();

  setState(() {
    _reviews = userReviews;
    _readingList = readingList;
    _groups = groups;
  });
}


  void _onItemTapped(int index) {
    if (index == 1) {
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

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || _user == null) return;

    final file = File(pickedFile.path);
    final ref = _storage.ref().child('profileImages/${_user!.uid}.jpg');
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    await _firestore.collection('users').doc(_user!.uid).update({
      'profileImage': downloadUrl,
    });

    setState(() {
      _profileImageUrl = downloadUrl;
    });
  }

void _showEditDialog(String title, String hint, bool isPassword) {
  final newValueController = TextEditingController();
  final passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Update $title'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPassword)
            TextField(
              controller: newValueController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: hint),
            ),
          if (isPassword)
            TextField(
              controller: newValueController,
              obscureText: true,
              decoration: InputDecoration(hintText: hint),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter current password to confirm'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
TextButton(
  onPressed: () async {
    final newValue = newValueController.text.trim();
    final currentPassword = passwordController.text.trim();

    if (newValue.isEmpty || currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Reauthenticate first
      await user.reauthenticateWithCredential(cred);

      // Then update
      if (isPassword) {
        await user.updatePassword(newValue);
      } else {
        await user.verifyBeforeUpdateEmail(newValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification email sent to $newValue. Please check your inbox and spam folder.')),
        );
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title updated successfully')),
      );
    } catch (e) {
      String errorMessage = 'Failed to update $title';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already in use.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'weak-password':
            errorMessage = 'Password should be at least 6 characters.';
            break;
          case 'wrong-password':
            errorMessage = 'The current password is incorrect.';
            break;
          case 'requires-recent-login':
            errorMessage = 'Session expired. Please log out and log in again.';
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  },
  child: const Text('Save'),
),

      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
Center(
  child: CircleAvatar(
    radius: 50,
    backgroundImage: _profileImageUrl != null
        ? NetworkImage(_profileImageUrl!)
        : const AssetImage('assets/default_profile.jpg') as ImageProvider,
  ),
),
const SizedBox(height: 20),
Center(
  child: Text(

                  user?.email ?? 'No Email',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _showEditDialog("Email", "Enter new email", false),
                child: const Text('Edit Email'),
              ),
              ElevatedButton(
                onPressed: () => _showEditDialog("Password", "Enter new password", true),
                child: const Text('Change Password'),
              ),
             
              const SizedBox(height: 30),
              const Text(
                'Your Reading List',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _readingList.isEmpty
                  ? const Text('Your reading list is empty.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _readingList.length,
                      itemBuilder: (context, index) {
                        final book = _readingList[index];
                        return ListTile(
                          title: Text(book['title']),
                          subtitle: Text('Status: ${book['status']}'),
                        );
                      },
                    ),
              const SizedBox(height: 30),
const Text(
  'Your Ratings and Reviews',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
_reviews.isEmpty
    ? const Text('You have not left any reviews yet.')
    : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return ListTile(
            title: Text(review['title']), // Book title
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rating: ${review['rating']}'),
              
                const SizedBox(height: 5),
                Text('Review: ${review['review']}'), // The actual review text
              ],
            ),
          );
        },
      ),
const SizedBox(height: 30),
const Text(
  'Preferred Genre',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
DropdownButton<String>(
  value: _selectedGenre,
  hint: const Text('Select a genre'),
  items: _genres.map((genre) {
    return DropdownMenuItem<String>(
      value: genre,
      child: Text(genre),
    );
  }).toList(),
onChanged: (newValue) async {
  setState(() {
    _selectedGenre = newValue!;
      _aiSuggestions = _genreSuggestions[_selectedGenre!] ?? [];
  });
  if (_user != null) {
    await _firestore.collection('users').doc(_user!.uid).set({
      'preferredGenre': newValue,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Genre preference saved!')),
      );
    }
  },
),
const SizedBox(height: 30),
const Text(
  'AI Book Suggestions',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
_aiSuggestions.isEmpty
    ? const Text('No suggestions yet. Select a genre above!')
    : SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _aiSuggestions.length,
          itemBuilder: (context, index) {
            final suggestion = _aiSuggestions[index];
            return Card(
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    suggestion,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),

              const SizedBox(height: 30),
              const Text(
                'Joined Groups',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _groups.isEmpty
                  ? const Text('You are not a member of any groups.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return ListTile(
                          title: Text(group['name']),
                          subtitle: Text(group['description']),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
