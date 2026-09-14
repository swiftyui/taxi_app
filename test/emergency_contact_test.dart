import 'package:TaxiApp/src/core/models/emergency_contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EmergencyContact parses persisted contact details', () {
    final updatedAt = DateTime.utc(2026, 9, 14, 9);
    final contact = EmergencyContact.fromJson('contact-1', {
      'name': 'Lerato',
      'phoneNumber': '+27821234567',
      'relationship': 'Family',
      'isPrimary': true,
      'updatedAt': Timestamp.fromDate(updatedAt),
    });

    expect(contact.id, 'contact-1');
    expect(contact.phoneNumber, '+27821234567');
    expect(contact.relationship, 'Family');
    expect(contact.isPrimary, isTrue);
    expect(
      contact.updatedAt?.millisecondsSinceEpoch,
      updatedAt.millisecondsSinceEpoch,
    );
  });
}
