import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker/domain/entities/app_user.dart';
import 'package:expensetracker/presentation/providers/auth_providers.dart';
import 'package:expensetracker/presentation/screens/auth/login_screen.dart';
import 'package:expensetracker/presentation/screens/home/home_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AppUser? _currentUser;
  bool _initialized = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(authStateProvider);

    initial.whenOrNull(
      data: (user) {
        _currentUser = user;
        _initialized = true;
      },
      error: (error, _) {
        _error = error;
        _initialized = true;
      },
    );

    ref.listenManual<AsyncValue<AppUser?>>(authStateProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _error = null;
              _currentUser = user;
              _initialized = true;
            });
          });
        },
        error: (error, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _error = error;
              _initialized = true;
            });
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);

    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Không thể tải trạng thái đăng nhập: $_error'),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _currentUser == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
