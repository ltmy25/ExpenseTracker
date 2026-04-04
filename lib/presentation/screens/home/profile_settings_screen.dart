import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:expensetracker/presentation/providers/auth_providers.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _selectedAvatarBytes;
  bool _removeAvatar = false;
  bool _didPrefillProfile = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (pickedFile == null) {
      return;
    }

    final imageBytes = await pickedFile.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAvatarBytes = imageBytes;
      _removeAvatar = false;
    });
  }

  void _clearAvatarSelection() {
    setState(() {
      _selectedAvatarBytes = null;
      _removeAvatar = true;
    });
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    await ref.read(authControllerProvider.notifier).updateProfile(
          displayName: _displayNameController.text.trim(),
          avatarBytes: _selectedAvatarBytes,
          removeAvatar: _removeAvatar,
        );

    if (!mounted) {
      return;
    }

    ref.invalidate(currentUserProfileProvider);

    final result = ref.read(authControllerProvider);
    result.whenOrNull(
      data: (_) {
        setState(() {
          _selectedAvatarBytes = null;
          _removeAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công.')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      },
    );
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    final result = ref.read(authControllerProvider);
    result.whenOrNull(
      data: (_) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công.')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authActionState = ref.watch(authControllerProvider);
    final isLoading = authActionState.isLoading;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ và bảo mật')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Không tìm thấy thông tin tài khoản.'));
          }

          if (!_didPrefillProfile) {
            _displayNameController.text = profile.displayName;
            _didPrefillProfile = true;
          }

          final shouldShowStoredAvatar =
              !_removeAvatar && _selectedAvatarBytes == null && (profile.avatarBase64?.isNotEmpty ?? false);
          final storedAvatarBytes = shouldShowStoredAvatar ? _decodeAvatar(profile.avatarBase64) : null;
          final currentInitial = profile.displayName.isEmpty
              ? 'U'
              : profile.displayName.substring(0, 1).toUpperCase();

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryContainer.withValues(alpha: 0.55),
                  const Color(0xFFF4F8F7),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: colors.primary,
                                  backgroundImage: _selectedAvatarBytes != null
                                      ? MemoryImage(_selectedAvatarBytes!)
                                      : (storedAvatarBytes != null
                                          ? MemoryImage(storedAvatarBytes)
                                          : null),
                                  child: (_selectedAvatarBytes == null && storedAvatarBytes == null)
                                      ? Text(
                                          currentInitial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.displayName,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(profile.email),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _profileFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cập nhật hồ sơ',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _displayNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tên hiển thị',
                                      prefixIcon: Icon(Icons.person_outline_rounded),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Vui lòng nhập tên hiển thị';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: isLoading ? null : _pickAvatar,
                                          icon: const Icon(Icons.photo_library_outlined),
                                          label: const Text('Chọn ảnh đại diện từ máy'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if ((profile.avatarBase64?.isNotEmpty ?? false) ||
                                          _selectedAvatarBytes != null ||
                                          _removeAvatar)
                                        OutlinedButton.icon(
                                          onPressed: isLoading ? null : _clearAvatarSelection,
                                          icon: const Icon(Icons.delete_outline_rounded),
                                          label: const Text('Xóa ảnh'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: isLoading ? null : _updateProfile,
                                      icon: const Icon(Icons.save_outlined),
                                      label: const Text('Lưu thay đổi hồ sơ'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _passwordFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đổi mật khẩu',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _currentPasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Mật khẩu hiện tại',
                                      prefixIcon: Icon(Icons.lock_outline_rounded),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nhập mật khẩu hiện tại';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _newPasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Mật khẩu mới',
                                      prefixIcon: Icon(Icons.password_rounded),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nhập mật khẩu mới';
                                      }
                                      if (value.length < 6) {
                                        return 'Mật khẩu mới tối thiểu 6 ký tự';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: isLoading ? null : _changePassword,
                                      icon: const Icon(Icons.key_rounded),
                                      label: const Text('Cập nhật mật khẩu'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Lỗi tải hồ sơ: $error')),
      ),
    );
  }

  Uint8List? _decodeAvatar(String? avatarBase64) {
    if (avatarBase64 == null || avatarBase64.isEmpty) {
      return null;
    }

    try {
      return base64Decode(avatarBase64);
    } catch (_) {
      return null;
    }
  }
}
