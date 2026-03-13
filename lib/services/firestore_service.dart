import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checkin_record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'checkins';

  /// Create a new check-in record
  Future<String> createCheckIn(CheckInRecord record) async {
    final docRef = await _db.collection(_collection).add(record.toMap());
    return docRef.id;
  }

  /// Update an existing record with check-out data
  Future<void> updateCheckOut({
    required String docId,
    required DateTime checkOutTime,
    required double checkOutLatitude,
    required double checkOutLongitude,
    required String qrCodeDataOut,
    required String whatLearned,
    required String feedback,
  }) async {
    await _db.collection(_collection).doc(docId).update({
      'checkOutTime': Timestamp.fromDate(checkOutTime),
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'qrCodeDataOut': qrCodeDataOut,
      'whatLearned': whatLearned,
      'feedback': feedback,
      'isCompleted': true,
    });
  }

  /// Get active (uncompleted) check-in for a student
  Future<CheckInRecord?> getActiveCheckIn(String studentId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .where('isCompleted', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return null;

    // Sort client-side to avoid needing composite index
    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final aTime = (a.data()['checkInTime'] as Timestamp).toDate();
        final bTime = (b.data()['checkInTime'] as Timestamp).toDate();
        return bTime.compareTo(aTime); // descending
      });

    final doc = docs.first;
    return CheckInRecord.fromMap(doc.data(), doc.id);
  }

  /// Get all check-in records for a student
  Future<List<CheckInRecord>> getCheckInHistory(String studentId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .get();

    final records = snapshot.docs
        .map((doc) => CheckInRecord.fromMap(doc.data(), doc.id))
        .toList();

    // Sort client-side to avoid needing composite index
    records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    return records;
  }
}
