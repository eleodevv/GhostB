/// Represents an installed application detected by GhostB.
class InstalledApp {
  final String id;
  final String name;
  final String version;
  final AppCategory category;
  final PackageManagerType packageManager;
  final String installPath;
  final int sizeBytes;
  final DateTime installDate;
  final bool isProtected;
  final bool isSystemApp;
  final String? iconPath;
  final String? publisher;
  final String? description;

  const InstalledApp({
    required this.id,
    required this.name,
    required this.version,
    required this.category,
    required this.packageManager,
    required this.installPath,
    required this.sizeBytes,
    required this.installDate,
    this.isProtected = false,
    this.isSystemApp = false,
    this.iconPath,
    this.publisher,
    this.description,
  });

  InstalledApp copyWith({
    String? id,
    String? name,
    String? version,
    AppCategory? category,
    PackageManagerType? packageManager,
    String? installPath,
    int? sizeBytes,
    DateTime? installDate,
    bool? isProtected,
    bool? isSystemApp,
    String? iconPath,
    String? publisher,
    String? description,
  }) {
    return InstalledApp(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      category: category ?? this.category,
      packageManager: packageManager ?? this.packageManager,
      installPath: installPath ?? this.installPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      installDate: installDate ?? this.installDate,
      isProtected: isProtected ?? this.isProtected,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      iconPath: iconPath ?? this.iconPath,
      publisher: publisher ?? this.publisher,
      description: description ?? this.description,
    );
  }

  /// Human-readable size string.
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum AppCategory {
  system('System', '🖥️'),
  development('Development', '💻'),
  games('Games', '🎮'),
  utilities('Utilities', '🔧'),
  multimedia('Multimedia', '🎵'),
  internet('Internet', '🌐'),
  office('Office', '📄'),
  unknown('Unknown', '📦');

  final String label;
  final String emoji;
  const AppCategory(this.label, this.emoji);
}

enum PackageManagerType {
  // Linux
  apt('APT/DEB'),
  snap('Snap'),
  flatpak('Flatpak'),
  appImage('AppImage'),
  pacman('Pacman'),
  rpm('RPM'),
  dnf('DNF'),
  yum('Yum'),
  tarBased('Tar'),
  // Windows
  registry('Registry'),
  winget('Winget'),
  chocolatey('Chocolatey'),
  scoop('Scoop'),
  msi('MSI'),
  portable('Portable'),
  // macOS
  appBundle('.app'),
  homebrew('Homebrew'),
  macPorts('MacPorts');

  final String label;
  const PackageManagerType(this.label);
}
