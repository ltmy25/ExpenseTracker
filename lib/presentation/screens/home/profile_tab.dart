import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:expensetracker/presentation/providers/auth_providers.dart';
import 'package:expensetracker/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  static final Uri _githubUri = Uri.parse('https://github.com/ltmy25');
  static final Uri _facebookUri = Uri.parse('https://facebook.com/ltmy25');
  static final Uri _linkedinUri = Uri.parse('https://linkedin.com/in/ltmy25');
  static final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: 'ltmy25.dev@gmail.com',
    query: 'subject=ExpenseTracker%20Support',
  );

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _copyContact(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label')),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('GitHub'),
                  subtitle: const Text('github.com/ltmy25'),
                  trailing: IconButton(
                    tooltip: 'Sao chép link',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => _copyContact(sheetContext, _githubUri.toString(), 'link GitHub'),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openUri(context, _githubUri);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.facebook_rounded),
                  title: const Text('Facebook'),
                  subtitle: const Text('facebook.com/ltmy25'),
                  trailing: IconButton(
                    tooltip: 'Sao chép link',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => _copyContact(sheetContext, _facebookUri.toString(), 'link Facebook'),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openUri(context, _facebookUri);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business_center_rounded),
                  title: const Text('LinkedIn'),
                  subtitle: const Text('linkedin.com/in/ltmy25'),
                  trailing: IconButton(
                    tooltip: 'Sao chép link',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => _copyContact(sheetContext, _linkedinUri.toString(), 'link LinkedIn'),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openUri(context, _linkedinUri);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('E-mail'),
                  subtitle: const Text('ltmy25.dev@gmail.com'),
                  trailing: IconButton(
                    tooltip: 'Sao chép email',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => _copyContact(sheetContext, 'ltmy25.dev@gmail.com', 'email'),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openUri(context, _emailUri);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authActionState = ref.watch(authControllerProvider);
    final isLoading = authActionState.isLoading;
    final colors = Theme.of(context).colorScheme;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const Center(child: Text('Không tìm thấy thông tin tài khoản.'));

        final avatarBytes = _decodeAvatar(profile.avatarBase64);
        final hasAvatar = avatarBytes != null;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: colors.primary,
                            backgroundImage: hasAvatar ? MemoryImage(avatarBytes) : null,
                            child: hasAvatar
                                ? null
                                : Text(
                                    profile.displayName.isEmpty
                                        ? 'U'
                                        : profile.displayName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.displayName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(profile.email),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: isLoading ? null : () => _logout(context, ref),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.verified_user_rounded, size: 18),
                                label: Text('UID: ${profile.uid.substring(0, 8)}...'),
                              ),
                              const Chip(
                                avatar: Icon(Icons.update_rounded, size: 18),
                                label: Text('Hồ sơ users đã đồng bộ Firestore'),
                              ),
                              const Chip(
                                avatar: Icon(Icons.security_rounded, size: 18),
                                label: Text('Rules owner-only đã bật'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quản lý tài khoản',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(AppRoutes.profileSettings);
                                  },
                                  icon: const Icon(Icons.manage_accounts_rounded),
                                  label: const Text('Mở Hồ sơ và bảo mật'),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Liên hệ chúng tôi',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              const Text('Liên hệ với chúng tôi nếu bạn gặp bất kỳ vấn đề nào hoặc có góp ý để cải thiện ứng dụng.'),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showContactSheet(context),
                                  icon: const Icon(Icons.support_agent_rounded),
                                  label: const Text('Mở thông tin liên hệ'),
                                ),
                              ),
                            ],
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
    );
  }

  static Uint8List? _decodeAvatar(String? avatarBase64) {
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
