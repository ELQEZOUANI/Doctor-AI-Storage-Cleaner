import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactDuplicateGroup {
  ContactDuplicateGroup({required this.reason, required this.contacts});
  final String reason;
  final List<Contact> contacts;
}

class ContactsScanResult {
  ContactsScanResult({
    required this.totalContacts,
    required this.duplicateGroups,
    required this.incompleteContacts,
  });
  final int totalContacts;
  final List<ContactDuplicateGroup> duplicateGroups;
  final List<Contact> incompleteContacts;

  int get duplicateCount => duplicateGroups.fold(0, (s, g) => s + g.contacts.length - 1);
}

class ContactsManager {
  static Future<bool> requestPermission() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.readWrite);
      return status == PermissionStatus.granted || status == PermissionStatus.limited;
    } catch (_) {
      return false;
    }
  }

  static Future<ContactsScanResult> scan() async {
    final hasPerm = await FlutterContacts.permissions.has(PermissionType.readWrite);
    if (!hasPerm) {
      final req = await requestPermission();
      if (!req) {
        return ContactsScanResult(totalContacts: 0, duplicateGroups: [], incompleteContacts: []);
      }
    }

    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone, ContactProperty.email},
    );

    final incomplete = <Contact>[];
    final byName = <String, List<Contact>>{};
    final byPhone = <String, List<Contact>>{};
    final byEmail = <String, List<Contact>>{};

    for (final c in contacts) {
      final name = c.displayName?.trim().toLowerCase() ?? '';
      final hasPhone = c.phones.isNotEmpty;
      final hasEmail = c.emails.isNotEmpty;

      if (!hasPhone && !hasEmail) {
        incomplete.add(c);
      }

      if (name.isNotEmpty) {
        byName.putIfAbsent(name, () => []).add(c);
      }

      for (final p in c.phones) {
        final cleanPhone = p.number.replaceAll(RegExp(r'[^\d+]'), '');
        if (cleanPhone.length >= 7) {
          byPhone.putIfAbsent(cleanPhone, () => []).add(c);
        }
      }

      for (final e in c.emails) {
        final cleanEmail = e.address.trim().toLowerCase();
        if (cleanEmail.isNotEmpty) {
          byEmail.putIfAbsent(cleanEmail, () => []).add(c);
        }
      }
    }

    final seenGroupKeys = <String>{};
    final duplicateGroups = <ContactDuplicateGroup>[];

    // Group duplicates by identical name
    byName.forEach((name, list) {
      if (list.length > 1) {
        final key = list.map((e) => e.id).toSet().toList()..sort();
        final keyStr = key.join(',');
        if (seenGroupKeys.add(keyStr)) {
          duplicateGroups.add(ContactDuplicateGroup(
            reason: 'Identical Name: ${list.first.displayName}',
            contacts: list,
          ));
        }
      }
    });

    // Group duplicates by identical phone
    byPhone.forEach((phone, list) {
      if (list.length > 1) {
        final key = list.map((e) => e.id).toSet().toList()..sort();
        final keyStr = key.join(',');
        if (seenGroupKeys.add(keyStr)) {
          duplicateGroups.add(ContactDuplicateGroup(
            reason: 'Shared Phone: $phone',
            contacts: list,
          ));
        }
      }
    });

    // Group duplicates by identical email
    byEmail.forEach((email, list) {
      if (list.length > 1) {
        final key = list.map((e) => e.id).toSet().toList()..sort();
        final keyStr = key.join(',');
        if (seenGroupKeys.add(keyStr)) {
          duplicateGroups.add(ContactDuplicateGroup(
            reason: 'Shared Email: $email',
            contacts: list,
          ));
        }
      }
    });

    return ContactsScanResult(
      totalContacts: contacts.length,
      duplicateGroups: duplicateGroups,
      incompleteContacts: incomplete,
    );
  }

  /// Merges a list of duplicate contacts into the primary contact and removes duplicates.
  static Future<bool> mergeGroup(List<Contact> group) async {
    if (group.length < 2) return false;
    final primary = group.first;
    final others = group.sublist(1);

    // Collect all unique phones and emails
    final existingPhones = primary.phones.map((p) => p.number.replaceAll(RegExp(r'[^\d+]'), '')).toSet();
    final existingEmails = primary.emails.map((e) => e.address.trim().toLowerCase()).toSet();

    for (final other in others) {
      for (final p in other.phones) {
        final clean = p.number.replaceAll(RegExp(r'[^\d+]'), '');
        if (existingPhones.add(clean)) {
          primary.phones.add(p);
        }
      }
      for (final e in other.emails) {
        final clean = e.address.trim().toLowerCase();
        if (existingEmails.add(clean)) {
          primary.emails.add(e);
        }
      }
      // Delete the secondary duplicate contact
      if (other.id != null) {
        await FlutterContacts.delete(other.id!);
      }
    }

    // Update primary contact
    await FlutterContacts.update(primary);
    return true;
  }

  /// Deletes multiple contacts
  static Future<int> deleteContacts(List<Contact> list) async {
    var deleted = 0;
    for (final c in list) {
      try {
        if (c.id != null) {
          await FlutterContacts.delete(c.id!);
          deleted++;
        }
      } catch (e) {
        debugPrint('Failed to delete contact: $e');
      }
    }
    return deleted;
  }

  /// Exports all contacts using native VCard engine
  static Future<String> exportVCardBackup() async {
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone, ContactProperty.email},
    );
    return FlutterContacts.vCard.exportAll(contacts);
  }
}
