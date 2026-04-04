import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:expensetracker/core/constants/firestore_collections.dart';
import 'package:expensetracker/data/models/jar_model.dart';
import 'package:expensetracker/domain/entities/transaction.dart' as entity;

class JarRemoteDataSource {
  final FirebaseFirestore _firestore;

  JarRemoteDataSource(this._firestore);

  CollectionReference get _jarsRef => _firestore.collection(FirestoreCollections.jars);
  CollectionReference _txRef(String uid) => _firestore.collection(FirestoreCollections.transactions);

  Stream<List<JarModel>> watchJars(String uid) {
    return _jarsRef.where('userId', isEqualTo: uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => JarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> createJar(String uid, JarModel jar) async {
    final jarData = jar.toMap();
    jarData['userId'] = uid;
    await _jarsRef.add(jarData);
  }

  Future<void> updateJar(String uid, JarModel jar) async {
    final jarData = jar.toMap();
    jarData['userId'] = uid;
    await _jarsRef.doc(jar.id).update(jarData);
  }

  Future<void> deleteJar(String uid, String jarId) async {
    await _jarsRef.doc(jarId).delete();
  }

  Future<void> addTransactionWithJarUpdate(String uid, entity.Transaction tx) async {
    try {
      final querySnapshot = await _jarsRef
          .where('userId', isEqualTo: uid)
          .where('categoryIds', arrayContains: tx.categoryId)
          .get();
      
      final jars = querySnapshot.docs;
      final txDoc = _txRef(uid).doc();

      if (jars.isEmpty) {
        await txDoc.set({
          ..._txToMap(tx),
          'userId': uid,
          'id': txDoc.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        return;
      }

      await _firestore.runTransaction((transaction) async {
        // 1. Đọc tất cả các hũ liên quan trước
        final List<DocumentSnapshot> jarSnapshots = [];
        for (final jarDoc in jars) {
          jarSnapshots.add(await transaction.get(jarDoc.reference));
        }

        // 2. Thực hiện cập nhật số dư sau khi đã đọc xong
        for (final snap in jarSnapshots) {
          if (!snap.exists) continue;
          final data = snap.data() as Map<String, dynamic>;
          
          // QUAN TRỌNG: Đọc cả currentBalance hoặc balance (trường cũ)
          final currentBalance = (data['currentBalance'] ?? data['balance'] ?? 0.0).toDouble();
          double newBalance;

          if (tx.type == entity.TransactionType.income) {
            newBalance = currentBalance + tx.amount;
          } else if (tx.type == entity.TransactionType.expense) {
            newBalance = currentBalance - tx.amount;
          } else {
            continue;
          }

          transaction.update(snap.reference, {
            'currentBalance': newBalance,
            'updatedAt': Timestamp.now(),
          });
        }

        final String? linkedJarId = jars.length == 1 ? jars.first.id : null;
        transaction.set(txDoc, {
          ..._txToMap(tx),
          'userId': uid,
          'jarId': ?linkedJarId,
          'id': txDoc.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> transferBetweenJars({
    required String uid,
    required String fromJarId,
    required String toJarId,
    required double amount,
    String? note,
  }) async {
    final fromDoc = _jarsRef.doc(fromJarId);
    final toDoc = _jarsRef.doc(toJarId);
    final txDoc = _txRef(uid).doc();

    await _firestore.runTransaction((transaction) async {
      final fromSnap = await transaction.get(fromDoc);
      final toSnap = await transaction.get(toDoc);

      if (!fromSnap.exists || !toSnap.exists) throw Exception('Hũ không tồn tại');

      final fromData = fromSnap.data() as Map<String, dynamic>;
      final toData = toSnap.data() as Map<String, dynamic>;

      final fromBalance = (fromData['currentBalance'] ?? fromData['balance'] ?? 0.0).toDouble();
      final toBalance = (toData['currentBalance'] ?? toData['balance'] ?? 0.0).toDouble();

      transaction.update(fromDoc, {'currentBalance': fromBalance - amount, 'updatedAt': Timestamp.now()});
      transaction.update(toDoc, {'currentBalance': toBalance + amount, 'updatedAt': Timestamp.now()});

      transaction.set(txDoc, {
        'title': 'Chuyển tiền giữa các hũ',
        'amount': amount,
        'type': 'transfer',
        'jarId': fromJarId,
        'toJarId': toJarId,
        'occurredAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'userId': uid,
        'note': note,
      });
    });
  }

  Map<String, dynamic> _txToMap(entity.Transaction tx) {
    return {
      'userId': tx.userId,
      'title': tx.title,
      'amount': tx.amount,
      'occurredAt': Timestamp.fromDate(tx.occurredAt),
      'categoryId': tx.categoryId,
      'type': tx.type.name,
      'note': tx.note,
      'jarId': tx.jarId,
      'toJarId': tx.toJarId,
    };
  }
}
