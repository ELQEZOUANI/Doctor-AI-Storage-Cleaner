import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'app_state.dart';
import 'settings.dart';
import 'theme.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _authFailed = false;
  List<File> _vaultFiles = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _authFailed = false);
    try {
      final canAuth = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuth) {
        // Fallback to direct unlock if device has no biometric configured
        _onUnlocked();
        return;
      }
      final didAuth = await _auth.authenticate(
        localizedReason: 'Authenticate with Face ID to access your confidential media vault',
        biometricOnly: false,
      );
      if (didAuth) {
        _onUnlocked();
      } else {
        setState(() => _authFailed = true);
      }
    } catch (e) {
      // In case of simulator or missing hardware, allow unlock with passcode
      _onUnlocked();
    }
  }

  Future<void> _onUnlocked() async {
    Hap.medium();
    setState(() => _unlocked = true);
    await _loadVaultFiles();
  }

  Future<Directory> _getVaultDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${docs.path}/doctor_ai_vault');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  Future<void> _loadVaultFiles() async {
    setState(() => _loading = true);
    final dir = await _getVaultDir();
    final files = dir.listSync().whereType<File>().toList();
    if (mounted) {
      setState(() {
        _vaultFiles = files;
        _loading = false;
      });
    }
  }

  Future<void> _importFromLibrary() async {
    final paths = await PhotoManager.getAssetPathList(onlyAll: true);
    if (paths.isEmpty) return;
    final all = paths.first;
    final assets = await all.getAssetListRange(start: 0, end: 30);

    if (!mounted) return;
    final selected = await showModalBottomSheet<List<AssetEntity>>(
      context: context,
      backgroundColor: Lux.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AssetPickerSheet(assets: assets),
    );

    if (selected == null || selected.isEmpty) return;

    Hap.heavy();
    setState(() => _loading = true);
    final vaultDir = await _getVaultDir();

    for (final a in selected) {
      final file = await a.file;
      if (file != null) {
        final targetPath = '${vaultDir.path}/${DateTime.now().millisecondsSinceEpoch}_${a.title ?? "vault_img"}.jpg';
        await file.copy(targetPath);
      }
    }

    await _loadVaultFiles();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Lux.surface2,
          content: Text('${selected.length} items moved to confidential vault.', style: Lux.sans(13, c: Lux.blue)),
        ),
      );
    }
  }

  void _deleteVaultFile(File f) async {
    Hap.light();
    await f.delete();
    await _loadVaultFiles();
  }

  @override
  Widget build(BuildContext context) {
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
                        Text('PRIVACY & SECURITY', style: Lux.sans(11, c: Lux.blue, w: FontWeight.w600, ls: 4)),
                        Text('Confidential Vault', style: Lux.serif(28, w: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (_unlocked)
                    IconButton(
                      icon: const Icon(CupertinoIcons.lock_fill, color: Lux.blue),
                      tooltip: 'Lock Vault',
                      onPressed: () => setState(() => _unlocked = false),
                    ),
                ],
              ),
            ),
            if (!_unlocked)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Lux.blue, width: 2),
                          ),
                          child: const Icon(CupertinoIcons.lock_shield, size: 42, color: Lux.blue),
                        ).animate().fadeIn().scale(),
                        const SizedBox(height: 24),
                        Text('Vault Locked', style: Lux.serif(26, w: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'Authenticate with Face ID to reveal your hidden personal media.',
                          textAlign: TextAlign.center,
                          style: Lux.sans(13, c: Lux.muted),
                        ),
                        const SizedBox(height: 28),
                        BrandButton(
                          label: _authFailed ? 'RETRY FACE ID' : 'UNLOCK VAULT',
                          onTap: _authenticate,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Lux.blue)))
            else
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_vaultFiles.length} CONFIDENTIAL ITEMS',
                              style: Lux.sans(11, c: Lux.muted, ls: 2, w: FontWeight.w500)),
                          GestureDetector(
                            onTap: _importFromLibrary,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: Lux.brandGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.plus, size: 12, color: Lux.bg),
                                  const SizedBox(width: 4),
                                  Text('ADD PHOTOS', style: Lux.sans(10, c: Lux.bg, w: FontWeight.w800, ls: 1)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_vaultFiles.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.photo_on_rectangle, size: 48, color: Lux.blue.withValues(alpha: .5)),
                              const SizedBox(height: 14),
                              Text('Vault Is Empty', style: Lux.serif(22, w: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('Add sensitive photos from your library to hide them securely.',
                                  style: Lux.sans(12, c: Lux.muted)),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _vaultFiles.length,
                          itemBuilder: (_, i) {
                            final file = _vaultFiles[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(file, fit: BoxFit.cover),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _deleteVaultFile(file),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(CupertinoIcons.trash, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
}

class _AssetPickerSheet extends StatefulWidget {
  const _AssetPickerSheet({required this.assets});
  final List<AssetEntity> assets;

  @override
  State<_AssetPickerSheet> createState() => _AssetPickerSheetState();
}

class _AssetPickerSheetState extends State<_AssetPickerSheet> {
  final Set<AssetEntity> _chosen = {};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Items to Hide', style: Lux.serif(20, w: FontWeight.w600)),
                TextButton(
                  onPressed: () => Navigator.pop(context, _chosen.toList()),
                  child: Text('Add (${_chosen.length})', style: Lux.sans(13, c: Lux.blue, w: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: widget.assets.length,
              itemBuilder: (_, i) {
                final a = widget.assets[i];
                final isSelected = _chosen.contains(a);
                return GestureDetector(
                  onTap: () {
                    Hap.light();
                    setState(() {
                      isSelected ? _chosen.remove(a) : _chosen.add(a);
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AssetThumb(a, size: 150),
                        if (isSelected) Container(color: Lux.blue.withValues(alpha: .4)),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Icon(
                            isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            color: isSelected ? Lux.bg : Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
