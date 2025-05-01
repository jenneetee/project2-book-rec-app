import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../widgets/bottom_nav_bar.dart';
import 'search_screen.dart';
import 'discussion_screen.dart';

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
    setState(() {
      _profileImageUrl = userDoc.data()?['profileImage'];
    });

    final reviewsSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('reviews')
        .get();

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
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $title'),
        content: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (isPassword) {
                  await _user!.updatePassword(controller.text);
                } else {
                  await _user!.updateEmail(controller.text);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title updated successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update $title: $e')),
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
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage('assets/default_profile.jpg')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _pickAndUploadProfileImage,
                      ),
                    ),
                  ],
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
                'Your Reviews',
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
                          title: Text(review['title']),
                          subtitle: Text('Rating: ${review['rating']}'),
                          trailing: Text(review['status']),
                        );
                      },
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
