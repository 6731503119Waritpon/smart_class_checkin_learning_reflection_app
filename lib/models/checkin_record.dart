import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInRecord {
  final String? id;
  final String studentId;
  final String studentName;
  final DateTime checkInTime;
  final double checkInLatitude;
  final double checkInLongitude;
  final String qrCodeData;
  final String previousTopic;
  final String expectedTopic;
  final int moodBefore;
  final DateTime? checkOutTime;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? qrCodeDataOut;
  final String? whatLearned;
  final String? feedback;
  final bool isCompleted;

  CheckInRecord({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.checkInTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    required this.qrCodeData,
    required this.previousTopic,
    required this.expectedTopic,
    required this.moodBefore,
    this.checkOutTime,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.qrCodeDataOut,
    this.whatLearned,
    this.feedback,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'qrCodeData': qrCodeData,
      'previousTopic': previousTopic,
      'expectedTopic': expectedTopic,
      'moodBefore': moodBefore,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'qrCodeDataOut': qrCodeDataOut,
      'whatLearned': whatLearned,
      'feedback': feedback,
      'isCompleted': isCompleted,
    };
  }

  factory CheckInRecord.fromMap(Map<String, dynamic> map, String docId) {
    return CheckInRecord(
      id: docId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      checkInTime: (map['checkInTime'] as Timestamp).toDate(),
      checkInLatitude: (map['checkInLatitude'] ?? 0).toDouble(),
      checkInLongitude: (map['checkInLongitude'] ?? 0).toDouble(),
      qrCodeData: map['qrCodeData'] ?? '',
      previousTopic: map['previousTopic'] ?? '',
      expectedTopic: map['expectedTopic'] ?? '',
      moodBefore: map['moodBefore'] ?? 3,
      checkOutTime: map['checkOutTime'] != null
          ? (map['checkOutTime'] as Timestamp).toDate()
          : null,
      checkOutLatitude: (map['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (map['checkOutLongitude'] as num?)?.toDouble(),
      qrCodeDataOut: map['qrCodeDataOut'],
      whatLearned: map['whatLearned'],
      feedback: map['feedback'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  String get moodEmoji {
    switch (moodBefore) {
      case 1:
        return '😡';
      case 2:
        return '🙁';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }
}
