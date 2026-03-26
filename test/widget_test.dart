import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/routes/app_routes.dart';

void main() {
  test('Route constants should stay stable', () {
    expect(AppRoutes.authGate, '/');
    expect(AppRoutes.login, '/login');
    expect(AppRoutes.register, '/register');
    expect(AppRoutes.home, '/home');
  });
}
