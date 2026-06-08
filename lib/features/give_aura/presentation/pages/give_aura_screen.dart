import 'package:aura_app/core/services/aura_service.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GiveAuraScreen extends ConsumerStatefulWidget {
  const GiveAuraScreen({super.key});

  @override
  ConsumerState<GiveAuraScreen> createState() => _GiveAuraScreenState();
}

class _GiveAuraScreenState extends ConsumerState<GiveAuraScreen> {
  final _commentController = TextEditingController();
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _commentFocusNode = FocusNode();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];

  UserModel? _selectedUser;
  int _selectedPoints = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _commentController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ref.read(auraServiceProvider).getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.displayName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _submitAura() async {
    if (_selectedUser == null || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user and write a comment'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(auraServiceProvider)
          .giveAuraPoints(
            toUserId: _selectedUser!.id,
            points: _selectedPoints,
            comment: _commentController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aura given successfully!')),
        );
        setState(() {
          _selectedUser = null;
          _commentController.clear();
          _selectedPoints = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to give aura: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Give Aura Points'),
          backgroundColor: theme.colorScheme.surfaceVariant,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Box
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Give +1 for positive behavior or -1 for negative behavior. Include a meaningful comment.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  labelText: 'Search users',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),

              const SizedBox(height: 16),

              // User List
              Text(
                'Select User',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _filteredUsers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 40),
                            SizedBox(height: 8),
                            Text('No users found'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return ListTile(
                            title: Text(user.displayName),
                            subtitle: Text(user.email),
                            leading: CircleAvatar(
                              backgroundImage: user.photoURL != null
                                  ? NetworkImage(user.photoURL!)
                                  : null,
                              child: user.photoURL == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            trailing: _selectedUser?.id == user.id
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() => _selectedUser = user);
                            },
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Points Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Aura Points:', style: theme.textTheme.titleMedium),
                  ToggleButtons(
                    isSelected: [_selectedPoints == 1, _selectedPoints == -1],
                    onPressed: (index) {
                      FocusScope.of(context).unfocus();
                      setState(() => _selectedPoints = index == 0 ? 1 : -1);
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('+1'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('-1'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Comment Field
              TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),

              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Sending...' : 'Submit'),
                  onPressed: _isLoading ? null : _submitAura,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
