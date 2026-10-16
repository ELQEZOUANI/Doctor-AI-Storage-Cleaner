import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'ad_service.dart';
import 'app_state.dart';
import 'contacts_cleaner.dart';
import 'settings.dart';
import 'theme.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  bool _permissionDenied = false;
  ContactsScanResult? _result;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });

    final hasPerm = await ContactsManager.requestPermission();
    if (!hasPerm) {
      if (mounted) {
        setState(() {
          _loading = false;
          _permissionDenied = true;
        });
      }
      return;
    }

    final res = await ContactsManager.scan();
    if (mounted) {
      setState(() {
        _result = res;
        _loading = false;
      });
    }
  }

  Future<void> _mergeAllDuplicates() async {
    final r = _result;
    if (r == null || r.duplicateGroups.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Lux.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Lux.blue.withValues(alpha: .3)),
        ),
        title: Text('Merge All Duplicates?', style: Lux.serif(24, w: FontWeight.w600)),
        content: Text(
          'This will merge ${r.duplicateCount} duplicate records across ${r.duplicateGroups.length} groups into primary contacts without losing phone numbers or emails.',
          style: Lux.sans(13, c: Lux.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: Lux.sans(14, c: Lux.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Merge All', style: Lux.sans(14, c: Lux.blue, w: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    Hap.heavy();

    setState(() => _loading = true);
    for (final group in r.duplicateGroups) {
      await ContactsManager.mergeGroup(group.contacts);
    }
    await _loadContacts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Lux.surface2,
          content: Text('All duplicate contacts successfully merged.', style: Lux.sans(13, c: Lux.blue)),
        ),
      );
    }
  }

  Future<void> _deleteIncomplete() async {
    final r = _result;
    if (r == null || r.incompleteContacts.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Lux.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Lux.blue.withValues(alpha: .3)),
        ),
        title: Text('Remove Incomplete Contacts?', style: Lux.serif(24, w: FontWeight.w600)),
        content: Text(
          'This will permanently delete ${r.incompleteContacts.length} contacts with no phone numbers and no emails.',
          style: Lux.sans(13, c: Lux.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: Lux.sans(14, c: Lux.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove All', style: Lux.sans(14, c: Colors.redAccent, w: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    Hap.heavy();

    setState(() => _loading = true);
    await ContactsManager.deleteContacts(r.incompleteContacts);
    await _loadContacts();

    AdService.i.showInterstitialAdIfAvailable(
      ignoreCooldown: true,
      onDismissed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Lux.surface2,
              content: Text('Incomplete contacts removed.', style: Lux.sans(13, c: Lux.blue)),
            ),
          );
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      backgroundColor: Lux.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.chevron_left, color: Lux.blue),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ADDRESS BOOK', style: Lux.sans(11, c: Lux.blue, w: FontWeight.w600, ls: 4)),
                        Text('Contacts Cleaner', style: Lux.serif(28, w: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_permissionDenied)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 54, color: Lux.blue),
                        const SizedBox(height: 18),
                        Text('Contact Access Required', style: Lux.serif(24, w: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'Allow Doctor AI to inspect contacts on-device to clean duplicates.',
                          textAlign: TextAlign.center,
                          style: Lux.sans(13, c: Lux.muted),
                        ),
                        const SizedBox(height: 24),
                        BrandButton(label: 'GRANT ACCESS', onTap: _loadContacts),
                      ],
                    ),
                  ),
                ),
              )
            else if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Lux.blue),
                ),
              )
            else if (r != null)
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: _statBox('${r.totalContacts}', 'TOTAL')),
                          const SizedBox(width: 12),
                          Expanded(child: _statBox('${r.duplicateCount}', 'DUPLICATES')),
                          const SizedBox(width: 12),
                          Expanded(child: _statBox('${r.incompleteContacts.length}', 'INCOMPLETE')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Lux.blue,
                      labelColor: Lux.blue,
                      unselectedLabelColor: Lux.muted,
                      labelStyle: Lux.sans(12, w: FontWeight.w600, ls: 1.5),
                      tabs: [
                        Tab(text: 'DUPLICATES (${r.duplicateGroups.length})'),
                        Tab(text: 'INCOMPLETE (${r.incompleteContacts.length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDuplicatesTab(r),
                          _buildIncompleteTab(r),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String val, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Lux.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Lux.blue.withValues(alpha: .2)),
        ),
        child: Column(
          children: [
            Text(val, style: Lux.serif(24, w: FontWeight.w600, c: Lux.blue)),
            const SizedBox(height: 2),
            Text(label, style: Lux.sans(10, c: Lux.muted, ls: 2, w: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildDuplicatesTab(ContactsScanResult r) {
    if (r.duplicateGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.checkmark_seal, color: Lux.blue.withValues(alpha: .6), size: 54),
            const SizedBox(height: 14),
            Text('No Duplicates Found', style: Lux.serif(22, w: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Your address book is clean.', style: Lux.sans(13, c: Lux.muted)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${r.duplicateGroups.length} DUPLICATE GROUPS',
                  style: Lux.sans(11, c: Lux.muted, ls: 2, w: FontWeight.w500)),
              GestureDetector(
                onTap: _mergeAllDuplicates,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: Lux.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('MERGE ALL', style: Lux.sans(10, c: Lux.bg, w: FontWeight.w800, ls: 1.5)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: r.duplicateGroups.length,
            itemBuilder: (_, i) {
              final g = r.duplicateGroups[i];
              return LuxCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(g.reason, style: Lux.sans(12, c: Lux.blue, w: FontWeight.w600)),
                        GestureDetector(
                          onTap: () async {
                            Hap.medium();
                            await ContactsManager.mergeGroup(g.contacts);
                            _loadContacts();
                          },
                          child: Text('Merge', style: Lux.sans(12, c: Lux.blue, w: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final c in g.contacts)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Lux.surface2,
                              child: Text(
                                (c.displayName?.isNotEmpty ?? false) ? c.displayName![0].toUpperCase() : '?',
                                style: Lux.sans(12, c: Lux.blue, w: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((c.displayName?.isNotEmpty ?? false) ? c.displayName! : 'Unnamed',
                                      style: Lux.sans(13, w: FontWeight.w500)),
                                  if (c.phones.isNotEmpty)
                                    Text(c.phones.first.number, style: Lux.sans(11, c: Lux.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncompleteTab(ContactsScanResult r) {
    if (r.incompleteContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.checkmark_seal, color: Lux.blue.withValues(alpha: .6), size: 54),
            const SizedBox(height: 14),
            Text('No Incomplete Contacts', style: Lux.serif(22, w: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('All contacts have phone numbers or emails.', style: Lux.sans(13, c: Lux.muted)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${r.incompleteContacts.length} EMPTY CONTACTS',
                  style: Lux.sans(11, c: Lux.muted, ls: 2, w: FontWeight.w500)),
              GestureDetector(
                onTap: _deleteIncomplete,
                child: Text('Delete All', style: Lux.sans(12, c: Colors.redAccent, w: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: r.incompleteContacts.length,
            itemBuilder: (_, i) {
              final c = r.incompleteContacts[i];
              return LuxCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Lux.surface2,
                      child: Text(
                        (c.displayName?.isNotEmpty ?? false) ? c.displayName![0].toUpperCase() : '?',
                        style: Lux.sans(12, c: Lux.muted),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((c.displayName?.isNotEmpty ?? false) ? c.displayName! : 'Unnamed Contact',
                              style: Lux.sans(14, w: FontWeight.w500)),
                          Text('No phone or email recorded', style: Lux.sans(11, c: Lux.muted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.trash, color: Lux.muted, size: 18),
                      onPressed: () async {
                        Hap.light();
                        if (c.id != null) {
                          await FlutterContacts.delete(c.id!);
                        }
                        _loadContacts();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
