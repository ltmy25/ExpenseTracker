import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expensetracker/presentation/providers/auth_providers.dart';
import 'package:expensetracker/routes/app_routes.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
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
                            child: Text(
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
                              const Text(
                                'Cập nhật hồ sơ và đổi mật khẩu đã được tách sang một màn hình riêng để thao tác rõ ràng hơn.',
                              ),
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
}
