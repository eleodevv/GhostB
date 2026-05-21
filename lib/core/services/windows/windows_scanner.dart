import 'dart:io';
import '../../models/installed_app.dart';
import '../platform_service.dart';

/// Windows — escanea registro, Winget, Chocolatey, Scoop.
class WindowsScanner implements PlatformService {
  @override
  Future<List<InstalledApp>> searchApps(String query) async {
    final q = query.toLowerCase();
    final apps = <InstalledApp>[];
    apps.addAll(await _searchRegistry(q));
    apps.addAll(await _searchWinget(q));
    apps.addAll(await _searchChocolatey(q));
    apps.addAll(await _searchScoop(q));

    final seen = <String>{};
    final unique = <InstalledApp>[];
    for (final app in apps) {
      if (seen.add(app.id)) unique.add(app);
    }
    unique.sort((a, b) => a.name.compareTo(b.name));
    return unique;
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    final apps = <InstalledApp>[];
    apps.addAll(await _getAllRegistry());
    apps.addAll(await _searchWinget(''));
    apps.addAll(await _searchChocolatey(''));
    apps.addAll(await _searchScoop(''));

    final seen = <String>{};
    final unique = <InstalledApp>[];
    for (final app in apps) {
      if (seen.add(app.id)) unique.add(app);
    }
    unique.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return unique;
  }

  @override
  Future<List<InstalledApp>> getHeavyApps() async {
    final all = await getInstalledApps();
    return all.where((a) => a.sizeBytes > 50 * 1024 * 1024).toList();
  }

  @override
  Future<bool> removeApp(InstalledApp app) async {
    try {
      final uninstalled = await _uninstall(app);
      await _cleanResiduals(app);
      return uninstalled;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _uninstall(InstalledApp app) async {
    ProcessResult result;
    switch (app.packageManager) {
      case PackageManagerType.winget:
        result = await Process.run('winget', ['uninstall', '--id', app.id.replaceFirst('winget:', ''), '--silent']);
      case PackageManagerType.chocolatey:
        result = await Process.run('choco', ['uninstall', app.name, '-y']);
      case PackageManagerType.scoop:
        result = await Process.run('scoop', ['uninstall', app.name]);
      case PackageManagerType.registry:
        // Intentar con el UninstallString del registro
        if (app.installPath.isNotEmpty) {
          result = await Process.run('cmd', ['/c', app.installPath]);
        } else {
          return false;
        }
      default:
        return false;
    }
    return result.exitCode == 0;
  }

  Future<void> _cleanResiduals(InstalledApp app) async {
    final appData = Platform.environment['APPDATA'] ?? '';
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final temp = Platform.environment['TEMP'] ?? '';
    final name = app.name;

    final paths = [
      '$appData\\$name',
      '$localAppData\\$name',
      '$temp\\$name',
      '$localAppData\\Temp\\$name',
    ];

    for (final path in paths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  // ─── Registry ──────────────────────────────────────────────────────────

  Future<List<InstalledApp>> _searchRegistry(String query) async {
    final all = await _getAllRegistry();
    if (query.isEmpty) return all;
    return all.where((a) => a.name.toLowerCase().contains(query)).toList();
  }

  Future<List<InstalledApp>> _getAllRegistry() async {
    final apps = <InstalledApp>[];
    // Buscar en ambas ramas del registro
    for (final key in [
      r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
      r'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
      r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    ]) {
      apps.addAll(await _queryRegistryKey(key));
    }
    return apps;
  }

  Future<List<InstalledApp>> _queryRegistryKey(String key) async {
    try {
      final result = await Process.run('reg', ['query', key, '/s']);
      if (result.exitCode != 0) return [];

      final output = result.stdout as String;
      final apps = <InstalledApp>[];
      String? currentName;
      String? currentVersion;
      String? currentUninstall;
      int currentSize = 0;

      for (final line in output.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          if (currentName != null && currentName.isNotEmpty) {
            // Filtrar entradas del sistema
            if (!_isSystemEntry(currentName)) {
              apps.add(InstalledApp(
                id: 'reg:$currentName',
                name: currentName,
                version: currentVersion ?? '',
                category: AppCategory.unknown,
                packageManager: PackageManagerType.registry,
                installPath: currentUninstall ?? '',
                sizeBytes: currentSize,
                installDate: DateTime.now(),
              ));
            }
          }
          currentName = null;
          currentVersion = null;
          currentUninstall = null;
          currentSize = 0;
          continue;
        }

        if (trimmed.contains('DisplayName')) {
          currentName = _extractRegValue(trimmed);
        } else if (trimmed.contains('DisplayVersion')) {
          currentVersion = _extractRegValue(trimmed);
        } else if (trimmed.contains('UninstallString')) {
          currentUninstall = _extractRegValue(trimmed);
        } else if (trimmed.contains('EstimatedSize')) {
          final sizeStr = _extractRegValue(trimmed);
          currentSize = (int.tryParse(sizeStr) ?? 0) * 1024; // KB to bytes
        }
      }
      return apps;
    } catch (_) {
      return [];
    }
  }

  String _extractRegValue(String line) {
    final parts = line.split(RegExp(r'\s{2,}'));
    return parts.length >= 3 ? parts.last.trim() : '';
  }

  bool _isSystemEntry(String name) {
    final lower = name.toLowerCase();
    return lower.startsWith('microsoft') ||
        lower.startsWith('windows') ||
        lower.contains('update for') ||
        lower.contains('security update') ||
        lower.contains('hotfix') ||
        lower.startsWith('{');
  }

  // ─── Winget ────────────────────────────────────────────────────────────

  Future<List<InstalledApp>> _searchWinget(String query) async {
    try {
      final args = query.isEmpty
          ? ['list', '--accept-source-agreements']
          : ['list', '--name', query, '--accept-source-agreements'];
      final result = await Process.run('winget', args);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      // Saltar headers (primeras 2-3 líneas)
      for (int i = 2; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || line.startsWith('-')) continue;

        final parts = line.split(RegExp(r'\s{2,}'));
        if (parts.length < 2) continue;

        final name = parts[0].trim();
        final id = parts.length > 1 ? parts[1].trim() : name;
        final version = parts.length > 2 ? parts[2].trim() : '';

        if (name.isEmpty || name.startsWith('-')) continue;

        apps.add(InstalledApp(
          id: 'winget:$id',
          name: name,
          version: version,
          category: AppCategory.unknown,
          packageManager: PackageManagerType.winget,
          installPath: '',
          sizeBytes: 0,
          installDate: DateTime.now(),
        ));
      }
      return apps;
    } catch (_) {
      return [];
    }
  }

  // ─── Chocolatey ────────────────────────────────────────────────────────

  Future<List<InstalledApp>> _searchChocolatey(String query) async {
    try {
      final result = await Process.run('choco', ['list', '--local-only']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.contains('packages installed')) continue;

        final parts = trimmed.split(' ');
        if (parts.length < 2) continue;

        final name = parts[0];
        final version = parts[1];

        if (query.isNotEmpty && !name.toLowerCase().contains(query)) continue;

        apps.add(InstalledApp(
          id: 'choco:$name',
          name: name,
          version: version,
          category: AppCategory.unknown,
          packageManager: PackageManagerType.chocolatey,
          installPath: '',
          sizeBytes: 0,
          installDate: DateTime.now(),
        ));
      }
      return apps;
    } catch (_) {
      return [];
    }
  }

  // ─── Scoop ─────────────────────────────────────────────────────────────

  Future<List<InstalledApp>> _searchScoop(String query) async {
    try {
      final result = await Process.run('scoop', ['list']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      for (int i = 2; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.isEmpty) continue;

        final name = parts[0];
        final version = parts.length > 1 ? parts[1] : '';

        if (query.isNotEmpty && !name.toLowerCase().contains(query)) continue;

        apps.add(InstalledApp(
          id: 'scoop:$name',
          name: name,
          version: version,
          category: AppCategory.unknown,
          packageManager: PackageManagerType.scoop,
          installPath: '',
          sizeBytes: 0,
          installDate: DateTime.now(),
        ));
      }
      return apps;
    } catch (_) {
      return [];
    }
  }
}
