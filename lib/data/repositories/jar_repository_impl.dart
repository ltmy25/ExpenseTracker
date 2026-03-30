import 'package:expensetracker/data/datasources/remote/jar_remote_datasource.dart';
import 'package:expensetracker/data/models/jar_model.dart';
import 'package:expensetracker/domain/entities/jar.dart';
import 'package:expensetracker/domain/entities/transaction.dart';
import 'package:expensetracker/domain/repositories/jar_repository.dart';

class JarRepositoryImpl implements JarRepository {
  final JarRemoteDataSource _remoteDataSource;

  JarRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<Jar>> watchJars(String uid) {
    return _remoteDataSource.watchJars(uid);
  }

  @override
  Future<void> createJar(String uid, Jar jar) async {
    final jarModel = JarModel(
      id: '',
      name: jar.name,
      currentBalance: jar.currentBalance,
      categoryIds: jar.categoryIds,
      budgetLimit: jar.budgetLimit,
      color: jar.color,
      icon: jar.icon,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _remoteDataSource.createJar(uid, jarModel);
  }

  @override
  Future<void> updateJar(String uid, Jar jar) async {
    final jarModel = JarModel(
      id: jar.id,
      name: jar.name,
      currentBalance: jar.currentBalance,
      categoryIds: jar.categoryIds,
      budgetLimit: jar.budgetLimit,
      color: jar.color,
      icon: jar.icon,
      createdAt: jar.createdAt,
      updatedAt: DateTime.now(),
    );
    await _remoteDataSource.updateJar(uid, jarModel);
  }

  @override
  Future<void> deleteJar(String uid, String jarId) async {
    await _remoteDataSource.deleteJar(uid, jarId);
  }

  @override
  Future<void> addTransactionWithJarUpdate(String uid, Transaction tx) async {
    await _remoteDataSource.addTransactionWithJarUpdate(uid, tx);
  }

  @override
  Future<void> transferBetweenJars({
    required String uid,
    required String fromJarId,
    required String toJarId,
    required double amount,
    String? note,
  }) async {
    await _remoteDataSource.transferBetweenJars(
      uid: uid,
      fromJarId: fromJarId,
      toJarId: toJarId,
      amount: amount,
      note: note,
    );
  }
}
