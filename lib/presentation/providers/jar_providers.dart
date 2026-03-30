import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetracker/data/datasources/remote/jar_remote_datasource.dart';
import 'package:expensetracker/data/repositories/jar_repository_impl.dart';
import 'package:expensetracker/domain/entities/jar.dart';
import 'package:expensetracker/domain/repositories/jar_repository.dart';
import 'package:expensetracker/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jarRemoteDataSourceProvider = Provider<JarRemoteDataSource>((ref) {
  return JarRemoteDataSource(FirebaseFirestore.instance);
});

final jarRepositoryProvider = Provider<JarRepository>((ref) {
  final dataSource = ref.watch(jarRemoteDataSourceProvider);
  return JarRepositoryImpl(dataSource);
});

final jarsStreamProvider = StreamProvider<List<Jar>>((ref) {
  final repository = ref.watch(jarRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  
  if (user == null) return Stream.value([]);
  
  return repository.watchJars(user.uid);
});

final jarControllerProvider = Provider<JarController>((ref) {
  final repository = ref.watch(jarRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  return JarController(repository, user?.uid);
});

class JarController {
  final JarRepository _repository;
  final String? _uid;

  JarController(this._repository, this._uid);

  String? get uid => _uid;

  Future<void> createJar(Jar jar) async {
    if (_uid == null) throw Exception('Người dùng chưa đăng nhập');
    await _repository.createJar(_uid, jar);
  }

  Future<void> updateJar(Jar jar) async {
    if (_uid == null) throw Exception('Người dùng chưa đăng nhập');
    await _repository.updateJar(_uid, jar);
  }

  Future<void> deleteJar(String jarId) async {
    if (_uid == null) throw Exception('Người dùng chưa đăng nhập');
    await _repository.deleteJar(_uid, jarId);
  }

  Future<void> transferMoney({
    required String fromJarId,
    required String toJarId,
    required double amount,
    String? note,
  }) async {
    if (_uid == null) return;
    await _repository.transferBetweenJars(
      uid: _uid,
      fromJarId: fromJarId,
      toJarId: toJarId,
      amount: amount,
      note: note,
    );
  }
}
