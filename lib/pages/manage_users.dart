import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _users = [];
  String _searchText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await supabase.from('profiles').select();

      setState(() {
        _users = List<Map<String, dynamic>>.from(data).map((u) {
          return {
            'name': u['full_name'] ?? 'No Name',
            'student id': u['student_id'] ?? '',
            'program': u['program'] ?? '',
          };
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching users: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    final filteredUsers = _users.where((user) {
      final query = _searchText.toLowerCase();
      return user['name'].toString().toLowerCase().contains(query) ||
          user['student id'].toString().toLowerCase().contains(query) ||
          user['program'].toString().toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: tp.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: tp.accentColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tp.accentColor))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tp.accentColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchText = value),
                    style: TextStyle(color: tp.textColor),
                    decoration: InputDecoration(
                      hintText: 'Search by name, student ID, or program',
                      hintStyle: TextStyle(color: tp.textColor.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search_rounded, color: tp.accentColor),
                      filled: true,
                      fillColor: tp.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _UserCard(user: filteredUsers[index], tp: tp);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add user workflow coming soon.')),
          );
        },
        backgroundColor: tp.accentColor,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.tp});

  final Map<String, dynamic> user;
  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tp.accentColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user['name'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tp.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user['student id'],
            style: TextStyle(color: tp.textColor.withOpacity(0.7), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.badge_rounded, size: 16, color: tp.accentColor),
              const SizedBox(width: 6),
              Text(
                user['program'],
                style: TextStyle(
                  color: tp.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: tp.accentColor),
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}