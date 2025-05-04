import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';

import '../widgets/bottom_nav_bar.dart';
import 'search_screen.dart';
import 'discussion_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User? _user;
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _readingList = [];
  List<Map<String, dynamic>> _groups = [];

  String? _profileImageUrl;
  String? _selectedGenre;
  List<String> _aiSuggestions = [];

  final List<String> _genres = [
    'Fantasy', 'Science Fiction', 'Mystery', 'Romance', 'Horror',
    'Non-fiction', 'Historical', 'Thriller', 'Young Adult',
  ];

  final Map<String, List<String>> _genreSuggestions = {
    'Fantasy': ['The Hobbit', 'Harry Potter', 'Mistborn'],
    'Science Fiction': ['Dune', 'Ender\'s Game', 'Neuromancer'],
    'Mystery': ['Gone Girl', 'Sherlock Holmes', 'The Da Vinci Code'],
    'Romance': ['Pride and Prejudice', 'The Notebook', 'Outlander'],
    'Horror': ['It', 'The Shining', 'Bird Box'],
    'Non-fiction': ['Sapiens', 'Educated', 'Atomic Habits'],
    'Historical': ['The Book Thief', 'All the Light We Cannot See'],
    'Thriller': ['The Silent Patient', 'The Girl on the Train'],
    'Young Adult': ['The Fault in Our Stars', 'The Hunger Games'],
  };

  String generateGravatarUrl(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final emailBytes = utf8.encode(normalizedEmail);
    final digest = md5.convert(emailBytes);
    return 'https://www.gravatar.com/avatar/$digest?d=identicon';
  }

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
    final userData = userDoc.data();
    final customImage = userData?['profileImage'];
    final genre = userData?['preferredGenre'];

    final reviewsSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('reviews')
        .get();

    final readingListSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('readingList')
        .get();

    final joinedGroupsSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('joinedGroups')
        .get();

    setState(() {
      _profileImageUrl = (customImage != null && customImage.isNotEmpty)
          ? customImage
          : generateGravatarUrl(_user!.email!);
      _selectedGenre = genre;
      _aiSuggestions = _genreSuggestions[genre] ?? [];

      _reviews = reviewsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'bookId': doc.id,
          'title': data['title'] ?? 'Untitled',
          'rating': data['rating'] ?? 0,
          'review': data['review'] ?? '',
          'status': data['readingStatus'] ?? '',
        };
      }).toList();

      _readingList = readingListSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'bookId': doc.id,
          'title': data['title'] ?? 'Untitled',
          'status': data['status'] ?? '',
        };
      }).toList();

      _groups = joinedGroupsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'groupId': doc.id,
          'name': data['name'] ?? 'Unnamed Group',
          'description': data['description'] ?? '',
        };
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DiscussionScreen()));
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
            TextField(
              controller: newValueController,
              obscureText: isPassword,
              keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Enter current password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newValue = newValueController.text.trim();
              final currentPassword = passwordController.text.trim();

              if (newValue.isEmpty || currentPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
                return;
              }

              try {
                final user = _auth.currentUser!;
                final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
                await user.reauthenticateWithCredential(cred);

                if (isPassword) {
                  await user.updatePassword(newValue);
                } else {
                  await user.verifyBeforeUpdateEmail(newValue);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification email sent to $newValue')),
                  );
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title updated')));
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
                      errorMessage = 'Session expired. Please log in again.';
                      break;
                  }
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
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
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickAndUploadProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : const AssetImage('assets/default_profile.jpg') as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(child: Text(user?.email ?? 'No Email', style: const TextStyle(fontSize: 18))),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showEditDialog("Email", "Enter new email", false),
                child: const Text('Edit Email'),
              ),
              ElevatedButton(
                onPressed: () => _showEditDialog("Password", "Enter new password", true),
                child: const Text('Change Password'),
              ),
              const Divider(height: 40),
              const Text('Preferred Genre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedGenre,
                hint: const Text('Select a genre'),
                items: _genres.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (newGenre) async {
                  setState(() {
                    _selectedGenre = newGenre;
                    _aiSuggestions = _genreSuggestions[newGenre!] ?? [];
                  });
                  if (_user != null) {
                    await _firestore.collection('users').doc(_user!.uid).set(
                      {'preferredGenre': newGenre},
                      SetOptions(merge: true),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Genre preference saved')),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text('AI Book Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _aiSuggestions.isEmpty
                  ? const Text('No suggestions yet. Select a genre.')
                  : SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _aiSuggestions.map((s) {
                          return Card(
                            child: Container(
                              width: 120,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8),
                              child: Text(s, textAlign: TextAlign.center),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
              const SizedBox(height: 20),
              const Text('Your Reading List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._readingList.map((b) => ListTile(title: Text(b['title']), subtitle: Text('Status: ${b['status']}'))),
              const SizedBox(height: 20),
              const Text('Your Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._reviews.map((r) => ListTile(
                    title: Text(r['title']),
                    subtitle: Text('Rating: ${r['rating']}\n${r['review']}'),
                  )),
              const SizedBox(height: 20),
              const Text('Joined Communities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._groups.map((g) => ListTile(
                    title: Text(g['name']),
                    subtitle: Text(g['description']),
                  )),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped),
    );
  }
}
