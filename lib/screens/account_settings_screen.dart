import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:retroquest/services/firestore_service.dart';
import 'package:retroquest/services/storage_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      await _user!.reload();
      final freshUser = FirebaseAuth.instance.currentUser;
      setState(() {
        _nameController.text = freshUser?.displayName ?? '';
        _emailController.text = freshUser?.email ?? '';
        _photoUrl = freshUser?.photoURL;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final imageBytes = await pickedFile.readAsBytes();
        final imageName = pickedFile.name;
        final mimeType = pickedFile.mimeType;

        String downloadUrl = await _storageService.uploadProfilePicture(
            _user!.uid, imageBytes, imageName,
            mimeType: mimeType);

        await _user!.updatePhotoURL(downloadUrl);
        await _firestoreService.updateUserProfile(_user!.uid, {
          'photoURL': downloadUrl,
        });

        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_nameController.text != _user!.displayName) {
        await _user!.updateDisplayName(_nameController.text);
        final nameParts = _nameController.text.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        await _firestoreService.updateUserProfile(_user!.uid, {
          'displayName': _nameController.text,
          'first': firstName,
          'last': lastName,
        });
      }

      if (_emailController.text != _user!.email) {
        await _user!.verifyBeforeUpdateEmail(_emailController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Verification email sent. Please check your inbox.')),
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile update initiated!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred.';
      if (e.code == 'requires-recent-login') {
        message =
            'This action requires you to sign in again. Please log out and log back in.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already in use by another account.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_user == null || _passwordController.text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);
    Navigator.of(context).pop();

    try {
      await _user!.updatePassword(_passwordController.text);
      _passwordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password.';
      if (e.code == 'requires-recent-login') {
        message =
            'This action requires you to sign in again. Please log out and log back in.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unknown error occurred.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showChangePasswordDialog() {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: ThemeData.dark(),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E2336),
            title: const Text(
              'Change Password',
              style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
            ),
            content: TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('New Password'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel',
                    style: TextStyle(fontFamily: 'PressStart2P')),
              ),
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Update',
                    style: TextStyle(fontFamily: 'PressStart2P')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(
              fontFamily: "PressStart2P", color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.deepPurple.shade900.withAlpha(217),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/retro_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withAlpha(153)),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.greenAccent)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildAvatar(),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'PressStart2P'),
                              decoration: _inputDecoration('Full Name'),
                              validator: (value) =>
                                  value!.isEmpty ? 'Please enter a name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'PressStart2P'),
                              decoration: _inputDecoration('Email Address'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter an email'
                                  : null,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                textStyle: const TextStyle(
                                    fontFamily: 'PressStart2P',
                                    fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Update Profile'),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _showChangePasswordDialog,
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Colors.greenAccent),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                textStyle: const TextStyle(
                                    fontFamily: 'PressStart2P',
                                    fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Change Password'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600)),
      focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.greenAccent)),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.black54,
          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
          child: _photoUrl == null
              ? const Icon(Icons.person, size: 50, color: Colors.white70)
              : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickAndUploadImage,
          child: const Text('Pick an image',
              style: TextStyle(
                  color: Colors.greenAccent, fontFamily: 'PressStart2P')),
        ),
      ],
    );
  }
}
