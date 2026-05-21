import 'dart:io';
import '../models/installed_app.dart';
import 'linux/linux_scanner.dart';
import 'windows/windows_scanner.dart';
import 'macos/macos_scanner.dart';

abstract class PlatformService {
  Future<List<InstalledApp>> searchApps(String query);
  Future<List<InstalledApp>> getInstalledApps();
  Future<List<InstalledApp>> getHeavyApps();
  Future<bool> removeApp(InstalledApp app);

  factory PlatformService() {
    if (Platform.isLinux) return LinuxScanner();
    if (Platform.isWindows) return WindowsScanner();
    if (Platform.isMacOS) return MacScanner();
    return LinuxScanner();
  }
}
