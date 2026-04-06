import 'package:expensetracker/domain/entities/jar.dart';
import 'package:expensetracker/domain/entities/transaction.dart';

abstract class JarRepository {
  Stream<List<Jar>> watchJars(String uid);
  Future<void> createJar(String uid, Jar jar);
  Future<void> updateJar(String uid, Jar jar);
  Future<void> deleteJar(String uid, String jarId);
  Future<void> addTransactionWithJarUpdate(String uid, Transaction tx);
  Future<void> transferBetweenJars({
    required String uid,
    required String fromJarId,
    required String toJarId,
    required double amount,
    String? note,
  });
}
