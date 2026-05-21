import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/installed_app.dart';
import '../services/platform_service.dart';

final platformServiceProvider = Provider<PlatformService>((ref) => PlatformService());

/// SharedPreferences instance.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

/// Query del usuario.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Resultados de búsqueda — lazy.
final searchResultsProvider = FutureProvider<List<InstalledApp>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 2) return [];
  final service = ref.read(platformServiceProvider);
  return service.searchApps(query);
});

/// Top 50 apps instaladas.
final installedAppsProvider = FutureProvider<List<InstalledApp>>((ref) async {
  final service = ref.read(platformServiceProvider);
  return service.getInstalledApps();
});

/// Apps pesadas (>50MB).
final heavyAppsProvider = FutureProvider<List<InstalledApp>>((ref) async {
  final service = ref.read(platformServiceProvider);
  return service.getHeavyApps();
});

/// Apps protegidas — persistidas con SharedPreferences.
final protectedAppsProvider =
    StateNotifierProvider<ProtectedAppsNotifier, List<String>>(
  (ref) {
    final prefs = ref.read(sharedPrefsProvider);
    return ProtectedAppsNotifier(prefs);
  },
);

class ProtectedAppsNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;
  static const _key = 'ghostb_protected_apps';

  ProtectedAppsNotifier(this._prefs)
      : super(_prefs.getStringList(_key) ?? []);

  void toggle(String appId) {
    if (state.contains(appId)) {
      state = state.where((id) => id != appId).toList();
    } else {
      state = [...state, appId];
    }
    _prefs.setStringList(_key, state);
  }

  bool isProtected(String appId) => state.contains(appId);
}

/// Apps protegidas — busca cada una por su nombre en dpkg/snap/flatpak.
final protectedAppsDataProvider = FutureProvider<List<InstalledApp>>((ref) async {
  final ids = ref.watch(protectedAppsProvider);
  if (ids.isEmpty) return [];

  final service = ref.read(platformServiceProvider);
  final results = <InstalledApp>[];

  for (final id in ids) {
    // El id tiene formato "dpkg:nombre" o "snap:nombre" o "flatpak:id"
    final parts = id.split(':');
    if (parts.length < 2) continue;
    final name = parts.sublist(1).join(':');

    // Buscar por nombre
    final found = await service.searchApps(name);
    final match = found.where((a) => a.id == id).toList();
    if (match.isNotEmpty) {
      results.add(match.first);
    }
  }
  return results;
});

/// Eliminar app.
final removeAppProvider =
    FutureProvider.family<bool, InstalledApp>((ref, app) async {
  final service = ref.read(platformServiceProvider);
  return service.removeApp(app);
});
