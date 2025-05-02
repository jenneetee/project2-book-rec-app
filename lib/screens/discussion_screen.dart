import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'community_chat_screen.dart'; // <-- Add this import

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({Key? key}) : super(key: key);

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  int _selectedIndex = 2;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> _communities = [];
  List<DocumentSnapshot> _filteredCommunities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

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
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _loadCommunities() async {
    final snapshot = await FirebaseFirestore.instance.collection('communities').get();
    setState(() {
      _communities = snapshot.docs;
      _filteredCommunities = _communities;
      _isLoading = false;
    });
  }

  void _filterCommunities(String query) {
    final filtered = _communities.where((doc) {
      final name = doc['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredCommunities = filtered;
    });
  }

  Future<void> _joinCommunity(String communityId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final groupRef = FirebaseFirestore.instance.collection('communities').doc(communityId);

    final communitySnapshot = await groupRef.get();
    final communityData = communitySnapshot.data();

    if (communityData == null) return;

    final name = communityData['name'] ?? 'Unnamed Community';
    final description = communityData['description'] ?? '';

    // Add user to community's members array
    await groupRef.update({
      'members': FieldValue.arrayUnion([user.uid]),
    });

    // Add group info to the user’s joinedGroups
    await userRef.collection('joinedGroups').doc(communityId).set({
      'name': name,
      'description': description,
    });

    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityChatScreen(
          communityId: communityId,
          communityName: name,
        ),
      ),
    );
  }

  Widget _buildCommunityItem(DocumentSnapshot community) {
    final name = community['name'] ?? 'Unnamed Community';
    final description = community['description'] ?? '';

    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: () => _joinCommunity(community.id),
          child: const Text('Join Now'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Communities'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search communities...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _filterCommunities(_searchController.text),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCommunities.length,
                      itemBuilder: (context, index) =>
                          _buildCommunityItem(_filteredCommunities[index]),
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
