import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';

/// Screen for editing user profile
class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _avatarUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.user.displayName ?? widget.user.username);
    _avatarUrlController =
        TextEditingController(text: ''); // User entity doesn't have avatarUrl
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileBloc>(),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true); // Return true to indicate success
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isUpdating = state is ProfileUpdating;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Profile'),
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Avatar Preview
                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        backgroundImage: _avatarUrlController.text.isNotEmpty
                            ? NetworkImage(_avatarUrlController.text)
                            : null,
                        child: _avatarUrlController.text.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        if (value.length > 100) {
                          return 'Name cannot exceed 100 characters';
                        }
                        return null;
                      },
                      enabled: !isUpdating,
                    ),

                    const SizedBox(height: 16),

                    // Avatar URL Field
                    TextFormField(
                      controller: _avatarUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Avatar URL (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                        hintText: 'https://example.com/avatar.jpg',
                      ),
                      keyboardType: TextInputType.url,
                      enabled: !isUpdating,
                      onChanged: (value) {
                        // Trigger rebuild to update avatar preview
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 8),

                    // Helper text
                    Text(
                      'Enter a URL to your profile picture or leave empty',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUpdating ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final avatarUrl = _avatarUrlController.text.trim();

      // Check if anything changed
      final nameChanged =
          name != (widget.user.displayName ?? widget.user.username);
      final avatarChanged = false; // User entity doesn't support avatarUrl

      if (!nameChanged && !avatarChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
          ),
        );
        return;
      }

      context.read<ProfileBloc>().add(
            ProfileUpdateRequested(
              name: nameChanged ? name : null,
              avatarUrl:
                  avatarChanged ? (avatarUrl.isEmpty ? null : avatarUrl) : null,
            ),
          );
    }
  }
}
