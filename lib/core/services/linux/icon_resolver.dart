import 'dart:io';

/// Busca el icono real de una app en el sistema de archivos de Linux.
class IconResolver {
  static final _iconDirs = [
    '/usr/share/icons/hicolor/128x128/apps',
    '/usr/share/icons/hicolor/96x96/apps',
    '/usr/share/icons/hicolor/64x64/apps',
    '/usr/share/icons/hicolor/48x48/apps',
    '/usr/share/icons/hicolor/scalable/apps',
    '/usr/share/pixmaps',
    '/usr/share/icons/Adwaita/48x48/apps',
    '/usr/share/icons/Adwaita/scalable/apps',
    '/snap/*/current/meta/gui',
    '/var/lib/flatpak/exports/share/icons/hicolor/128x128/apps',
    '/var/lib/flatpak/exports/share/icons/hicolor/64x64/apps',
  ];

  static final _extensions = ['png', 'svg', 'xpm'];

  /// Retorna la ruta al icono si existe, null si no.
  static String? findIcon(String appName) {
    final name = appName.toLowerCase().replaceAll(' ', '-');

    for (final dir in _iconDirs) {
      // Manejar wildcards en snap paths
      if (dir.contains('*')) {
        final parts = dir.split('*');
        final baseDir = Directory(parts[0]);
        if (!baseDir.existsSync()) continue;
        try {
          for (final sub in baseDir.listSync()) {
            if (sub is Directory) {
              final expandedDir = '${sub.path}${parts[1]}';
              final found = _searchInDir(expandedDir, name);
              if (found != null) return found;
            }
          }
        } catch (_) {}
        continue;
      }

      final found = _searchInDir(dir, name);
      if (found != null) return found;
    }

    return null;
  }

  static String? _searchInDir(String dirPath, String name) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return null;

    for (final ext in _extensions) {
      final file = File('$dirPath/$name.$ext');
      if (file.existsSync()) return file.path;
    }

    // Buscar coincidencia parcial
    try {
      for (final entity in dir.listSync()) {
        if (entity is File) {
          final fileName = entity.path.split('/').last.toLowerCase();
          if (fileName.startsWith(name) || fileName.contains(name)) {
            return entity.path;
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
