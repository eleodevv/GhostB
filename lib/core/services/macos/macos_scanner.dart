import 'dart:io';
import '../../models/installed_app.dart';
import '../platform_service.dart';

/// macOS — escanea /Applications, Homebrew, MacPorts.
class MacScanner implements PlatformService {
  @override
  Future<List<InstalledApp>> searchApps(String query) async {
    final q = query.toLowerCase();
    final apps = <InstalledApp>[];
    apps.addAll(await _searchApplications(q));
    apps.addAll(await _searchHomebrew(q));
    apps.addAll(await _searchMacPorts(q));

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
    apps.addAll(await _searchApplications(''));
    apps.addAll(await _searchHomebrew(''));
    apps.addAll(await _searchMacPorts(''));

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
      case PackageManagerType.appBundle:
        // Mover a la papelera con osascript
        result = await Process.run('osascript', [
          '-e', 'tell application "Finder" to delete POSIX file "${app.installPath}"',
        ]);
      case PackageManagerType.homebrew:
        result = await Process.run('brew', ['uninstall', '--force', app.name]);
      case PackageManagerType.macPorts:
        result = await Process.run('sudo', ['port', 'uninstall', app.name]);
      default:
        return false;
    }
    return result.exitCode == 0;
  }

  Future<void> _cleanResiduals(InstalledApp app) async {
    final home = Platform.environment['HOME'] ?? '/Users';
    final name = app.name.replaceAll('.app', '');

    // Buscar por nombre y bundle ID
    final paths = [
      '$home/Library/Caches/$name',
      '$home/Library/Preferences/$name.plist',
      '$home/Library/Application Support/$name',
      '$home/Library/Logs/$name',
      '$home/Library/Saved Application State/$name.savedState',
      '$home/Library/HTTPStorages/$name',
      '$home/Library/WebKit/$name',
    ];

    for (final path in paths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Buscar LaunchAgents
    final launchAgents = Directory('$home/Library/LaunchAgents');
    if (await launchAgents.exists()) {
      await for (final entity in launchAgents.list()) {
        if (entity.path.toLowerCase().contains(name.toLowerCase())) {
          await entity.delete();
        }
      }
    }
  }

  // ─── /Applications ─────────────────────────────────────────────────────

  Future<List<InstalledApp>> _searchApplications(String query) async {
    final apps = <InstalledApp>[];

    for (final dir in ['/Applications', '/Applications/Utilities']) {
      final appsDir = Directory(dir);
      if (!await appsDir.exists()) continue;

      await for (final entity in appsDir.list()) {
        if (entity is Directory && entity.path.endsWith('.app')) {
          final name = entity.path.split('/').last.replaceAll('.app', '');
          if (query.isNotEmpty && !name.toLowerCase().contains(query)) continue;

          // Obtener tamaño
          int size = 0;
          try {
            final duResult = await Process.run('du', ['-sk', entity.path]);
            if (duResult.exitCode == 0) {
              final sizeStr = (duResult.stdout as String).split('\t').first;
              size = (int.tryParse(sizeStr) ?? 0) * 1024;
            }
          } catch (_) {}

          // Obtener icono
          String? iconPath;
          final iconFile = File('${entity.path}/Contents/Resources/AppIcon.icns');
          if (await iconFile.exists()) iconPath = iconFile.path;

          apps.add(InstalledApp(
            id: 'app:$name',
            name: name,
            version: await _getAppVersion(entity.path),
            category: AppCategory.unknown,
            packageManager: PackageManagerType.appBundle,
            installPath: entity.path,
            sizeBytes: size,
            installDate: DateTime.now(),
            iconPath: iconPath,
          ));
        }
      }
    }
    return apps;
  }

  Future<String> _getAppVersion(String appPath) async {
    try {
      final result = await Process.run('defaults', [
        'read', '$appPath/Contents/Info', 'CFBundleShortVersionString',
      ]);
      if (result.exitCode == 0) return (result.stdout as String).trim();
    } catch (_) {}
    return '';
  }

  // ─── Homebrew ──────────────────────────────────────────────────────────

  Future<List<InstalledApp>> _searchHomebrew(String query) async {
    try {
      final result = await Process.run('brew', ['list', '--formula', '-1']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      for (final line in lines) {
        final name = line.trim();
        if (name.isEmpty) continue;
        if (query.isNotEmpty && !name.toLowerCase().contains(query)) continue;

        apps.add(InstalledApp(
          id: 'brew:$name',
          name: name,
          version: '',
          category: AppCategory.unknown,
          packageManager: PackageManagerType.homebrew,
          installPath: '/opt/homebrew/Cellar/$name',
          sizeBytes: 0,
          installDate: DateTime.now(),
        ));
      }

      // También casks
      final caskResult = await Process.run('brew', ['list', '--cask', '-1']);
      if (caskResult.exitCode == 0) {
        for (final line in (caskResult.stdout as String).split('\n')) {
          final name = line.trim();
          if (name.isEmpty) continue;
          if (query.isNotEmpty && !name.toLowerCase().contains(query)) continue;

          apps.add(InstalledApp(
            id: 'brew-cask:$name',
            name: name,
            version: '',
            category: AppCategory.unknown,
            packageManager: PackageManagerType.homebrew,
            installPath: '/opt/homebrew/Caskroom/$name',
            sizeBytes: 0,
            installDate: DateTime.now(),
          ));
        }
      }

      return apps;
    } catch (_) {
      return [];
    }
  }

  // ─── MacPorts ──────────────────────────────────────────────────────────

  Future<List<InstalledApp>> _searchMacPorts(String query) async {
    try {
      final result = await Process.run('port', ['installed']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('The following')) continue;

        // Formato: "  name @version_revision+variants (active)"
        final match = RegExp(r'^\s*(\S+)\s+@(\S+)').firstMatch(trimmed);
        if (match == null) continue;

        final name = match.group(1)!;
        final version = match.group(2)!;

        if (query.isNotEmpty && !name.toLowerCase().contains(query)) continue;

        apps.add(InstalledApp(
          id: 'port:$name',
          name: name,
          version: version,
          category: AppCategory.unknown,
          packageManager: PackageManagerType.macPorts,
          installPath: '/opt/local/var/macports/software/$name',
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
