import 'dart:io';
import '../../models/installed_app.dart';
import '../platform_service.dart';
import 'icon_resolver.dart';

class LinuxScanner implements PlatformService {
  @override
  Future<List<InstalledApp>> searchApps(String query) async {
    final q = query.toLowerCase();
    final apps = <InstalledApp>[];

    apps.addAll(await _searchDpkg(q));
    apps.addAll(await _searchSnap(q));
    apps.addAll(await _searchFlatpak(q));

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
    // Top 50 apps instaladas (no libs del sistema) — SIN resolver iconos aquí
    try {
      final result = await Process.run('dpkg-query', [
        '--show',
        '--showformat',
        r'${Package}\t${Version}\t${Installed-Size}\t${Section}\n',
      ]);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('\t');
        if (parts.length < 3) continue;

        final name = parts[0].trim();
        final version = parts[1].trim();
        final sizeKb = int.tryParse(parts[2].trim()) ?? 0;
        final section = parts.length > 3 ? parts[3].trim() : '';

        if (_isSystem(name, section)) continue;
        if (sizeKb < 100) continue;

        apps.add(InstalledApp(
          id: 'dpkg:$name',
          name: name,
          version: version,
          category: _categorize(section),
          packageManager: PackageManagerType.apt,
          installPath: '/usr/bin/$name',
          sizeBytes: sizeKb * 1024,
          installDate: DateTime.now(),
          isSystemApp: false,
          iconPath: null, // Se resuelve lazy en el widget
        ));
      }

      // Ordenar por tamaño descendente
      apps.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      return apps;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<InstalledApp>> getHeavyApps() async {
    // Apps > 50MB
    final all = await getInstalledApps();
    final heavy = all.where((a) => a.sizeBytes > 50 * 1024 * 1024).toList();
    heavy.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return heavy;
  }

  @override
  Future<bool> removeApp(InstalledApp app) async {
    try {
      // 1. Desinstalar paquete
      final uninstalled = await _uninstallPackage(app);

      // 2. Limpiar residuales (cache, config, datos)
      await _cleanResiduals(app);

      return uninstalled;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _uninstallPackage(InstalledApp app) async {
    ProcessResult result;
    switch (app.packageManager) {
      case PackageManagerType.apt:
        result = await Process.run(
            'pkexec', ['apt-get', 'remove', '--purge', '-y', app.name]);
      case PackageManagerType.snap:
        result = await Process.run('snap', ['remove', app.name]);
      case PackageManagerType.flatpak:
        final appId = app.id.replaceFirst('flatpak:', '');
        result = await Process.run('flatpak', ['uninstall', '-y', appId]);
      default:
        return false;
    }
    return result.exitCode == 0;
  }

  /// Elimina archivos residuales: cache, config, datos, logs.
  Future<void> _cleanResiduals(InstalledApp app) async {
    final home = Platform.environment['HOME'] ?? '/home';
    final name = app.name.toLowerCase();

    final paths = [
      '$home/.config/$name',
      '$home/.local/share/$name',
      '$home/.cache/$name',
      '$home/.$name',
      '$home/.local/state/$name',
      '/tmp/$name',
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
  }

  // ─── Búsqueda rápida por package manager ─────────────────────────────

  Future<List<InstalledApp>> _searchDpkg(String query) async {
    try {
      // Usa dpkg-query con pattern matching — mucho más rápido que cargar todo
      final result = await Process.run('dpkg-query', [
        '--show',
        '--showformat',
        r'${Package}\t${Version}\t${Installed-Size}\t${Section}\n',
        '*$query*',
      ]);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('\t');
        if (parts.length < 3) continue;

        final name = parts[0].trim();
        final version = parts[1].trim();
        final sizeKb = int.tryParse(parts[2].trim()) ?? 0;
        final section = parts.length > 3 ? parts[3].trim() : '';

        apps.add(InstalledApp(
          id: 'dpkg:$name',
          name: name,
          version: version,
          category: _categorize(section),
          packageManager: PackageManagerType.apt,
          installPath: '/usr/bin/$name',
          sizeBytes: sizeKb * 1024,
          installDate: DateTime.now(),
          isSystemApp: _isSystem(name, section),
          iconPath: IconResolver.findIcon(name),
        ));
      }
      return apps;
    } catch (_) {
      return [];
    }
  }

  Future<List<InstalledApp>> _searchSnap(String query) async {
    try {
      final result = await Process.run('snap', ['list']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.isEmpty) continue;

        final name = parts[0];
        if (!name.toLowerCase().contains(query)) continue;

        apps.add(InstalledApp(
          id: 'snap:$name',
          name: name,
          version: parts.length > 1 ? parts[1] : '',
          category: AppCategory.unknown,
          packageManager: PackageManagerType.snap,
          installPath: '/snap/$name',
          sizeBytes: 0,
          installDate: DateTime.now(),
          iconPath: IconResolver.findIcon(name),
        ));
      }
      return apps;
    } catch (_) {
      return [];
    }
  }

  Future<List<InstalledApp>> _searchFlatpak(String query) async {
    try {
      final result = await Process.run(
          'flatpak', ['list', '--app', '--columns=application,name,version']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split('\n');
      final apps = <InstalledApp>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('\t');
        if (parts.length < 2) continue;

        final appId = parts[0].trim();
        final name = parts[1].trim();
        if (!name.toLowerCase().contains(query) &&
            !appId.toLowerCase().contains(query)) {
          continue;
        }

        apps.add(InstalledApp(
          id: 'flatpak:$appId',
          name: name,
          version: parts.length > 2 ? parts[2].trim() : '',
          category: AppCategory.unknown,
          packageManager: PackageManagerType.flatpak,
          installPath: '/var/lib/flatpak/app/$appId',
          sizeBytes: 0,
          installDate: DateTime.now(),
          iconPath: IconResolver.findIcon(name) ??
              IconResolver.findIcon(appId.split('.').last),
        ));
      }
      return apps;
    } catch (_) {
      return [];
    }
  }

  AppCategory _categorize(String section) {
    final s = section.toLowerCase();
    if (s.contains('devel') || s.contains('libs')) return AppCategory.development;
    if (s.contains('game')) return AppCategory.games;
    if (s.contains('util') || s.contains('admin')) return AppCategory.utilities;
    if (s.contains('sound') || s.contains('video') || s.contains('graphics')) return AppCategory.multimedia;
    if (s.contains('web') || s.contains('net')) return AppCategory.internet;
    if (s.contains('text') || s.contains('doc')) return AppCategory.office;
    if (s.contains('base') || s.contains('kernel')) return AppCategory.system;
    return AppCategory.unknown;
  }

  bool _isSystem(String name, String section) {
    return ['lib', 'linux-', 'base-', 'systemd', 'init']
            .any((p) => name.startsWith(p)) ||
        ['base', 'kernel'].any((s) => section.toLowerCase().contains(s));
  }
}
