import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/installed_app.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';

final sidebarIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(isDark: isDark),
          Expanded(child: _Content(isDark: isDark)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIDEBAR — pixel-clean, minimal
// ═══════════════════════════════════════════════════════════════════════════════

class _Sidebar extends ConsumerWidget {
  final bool isDark;
  const _Sidebar({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(sidebarIndexProvider);
    final outline = isDark ? AppTheme.borderDark : const Color(0xFFE0E0E0);

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(right: BorderSide(color: outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/images/ghostb.png', width: 26, height: 26),
                ),
                const SizedBox(width: 8),
                Text('GhostB', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.inkDark : AppTheme.ink,
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SideItem(icon: LucideIcons.search, label: 'Buscar', idx: 0, sel: sel, isDark: isDark),
          _SideItem(icon: LucideIcons.grid, label: 'Instaladas', idx: 1, sel: sel, isDark: isDark),
          _SideItem(icon: LucideIcons.lock, label: 'Protegidas', idx: 3, sel: sel, isDark: isDark),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onTap: () => ref.read(themeModeProvider.notifier).toggle(),
              child: Row(
                children: [
                  Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 14,
                      color: isDark ? AppTheme.greyDark : AppTheme.grey),
                  const SizedBox(width: 8),
                  Text(isDark ? 'Claro' : 'Oscuro', style: TextStyle(
                      fontSize: 10, color: isDark ? AppTheme.greyDark : AppTheme.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SideItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final int idx;
  final int sel;
  final bool isDark;

  const _SideItem({required this.icon, required this.label,
      required this.idx, required this.sel, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = idx == sel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => ref.read(sidebarIndexProvider.notifier).state = idx,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14,
                  color: active
                      ? (isDark ? AppTheme.inkDark : AppTheme.ink)
                      : (isDark ? AppTheme.greyDark : AppTheme.grey)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active
                    ? (isDark ? AppTheme.inkDark : AppTheme.ink)
                    : (isDark ? AppTheme.greyDark : AppTheme.grey),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONTENT — buscador visible en TODAS las vistas
// ═══════════════════════════════════════════════════════════════════════════════

class _Content extends ConsumerWidget {
  final bool isDark;
  const _Content({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(sidebarIndexProvider);
    final query = ref.watch(searchQueryProvider);

    return Column(
      children: [
        const SizedBox(height: 16),
        // Search — siempre visible, filtra en cualquier vista
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _Search(isDark: isDark),
        ),
        const SizedBox(height: 14),
        // Body
        Expanded(
          child: switch (tab) {
            0 => _SearchOnly(query: query, isDark: isDark),
            1 => _AllAppsView(query: query, isDark: isDark),
            2 => _HeavyView(query: query, isDark: isDark),
            3 => _ProtectedList(query: query, isDark: isDark),
            _ => _SearchOnly(query: query, isDark: isDark),
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _Search extends ConsumerStatefulWidget {
  final bool isDark;
  const _Search({required this.isDark});

  @override
  ConsumerState<_Search> createState() => _SearchState();
}

class _SearchState extends ConsumerState<_Search> {
  final _controller = TextEditingController();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final outline = widget.isDark ? AppTheme.borderDark : const Color(0xFFE0E0E0);
    final query = ref.watch(searchQueryProvider);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outline),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(LucideIcons.search, size: 14, color: AppTheme.greyLight),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              style: TextStyle(fontSize: 12, color: widget.isDark ? AppTheme.inkDark : AppTheme.ink),
              decoration: InputDecoration(
                hintText: 'Buscar apps...',
                hintStyle: TextStyle(fontSize: 11, color: AppTheme.greyLight),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(LucideIcons.x, size: 14,
                    color: widget.isDark ? AppTheme.greyDark : AppTheme.grey),
              ),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VIEWS
// ═══════════════════════════════════════════════════════════════════════════════

/// Vista "Buscar" — vacía hasta que escribes, como antes.
class _SearchOnly extends ConsumerWidget {
  final String query;
  final bool isDark;
  const _SearchOnly({required this.query, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.length < 2) return _Welcome(isDark: isDark);
    final results = ref.watch(searchResultsProvider);
    return results.when(
      data: (apps) => apps.isEmpty ? _Empty(isDark: isDark) : _Grid(apps: apps, isDark: isDark),
      loading: () => const Center(child: _Loader()),
      error: (e, s) => _Empty(isDark: isDark),
    );
  }
}

/// Vista "Instaladas" — muestra todas, filtra por query.
class _AllAppsView extends ConsumerWidget {
  final String query;
  final bool isDark;
  const _AllAppsView({required this.query, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si hay query >= 2, busca con dpkg pattern matching (rápido)
    if (query.length >= 2) {
      final results = ref.watch(searchResultsProvider);
      return results.when(
        data: (apps) => apps.isEmpty ? _Empty(isDark: isDark) : _Grid(apps: apps, isDark: isDark),
        loading: () => const Center(child: _Loader()),
        error: (e, s) => _Empty(isDark: isDark),
      );
    }

    // Sin query — muestra las instaladas
    final data = ref.watch(installedAppsProvider);
    return data.when(
      data: (apps) => apps.isEmpty ? _Welcome(isDark: isDark) : _Grid(apps: apps, isDark: isDark),
      loading: () => const Center(child: _Loader()),
      error: (e, s) => _Empty(isDark: isDark),
    );
  }
}

/// Vista pesadas — filtra por query también.
class _HeavyView extends ConsumerWidget {
  final String query;
  final bool isDark;
  const _HeavyView({required this.query, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(heavyAppsProvider);
    return data.when(
      data: (apps) {
        final filtered = query.length >= 2
            ? apps.where((a) => a.name.toLowerCase().contains(query.toLowerCase())).toList()
            : apps;
        return filtered.isEmpty
            ? _Empty(isDark: isDark, msg: 'Sin apps pesadas (>50MB)')
            : _Grid(apps: filtered, isDark: isDark);
      },
      loading: () => const Center(child: _Loader()),
      error: (e, s) => _Empty(isDark: isDark),
    );
  }
}

/// Vista protegidas — busca las apps protegidas directamente.
class _ProtectedList extends ConsumerWidget {
  final String query;
  final bool isDark;
  const _ProtectedList({required this.query, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(protectedAppsProvider);
    if (ids.isEmpty) return _Empty(isDark: isDark, msg: 'Sin apps protegidas');
    final data = ref.watch(protectedAppsDataProvider);
    return data.when(
      data: (apps) {
        var list = apps;
        if (query.length >= 2) {
          list = list.where((a) => a.name.toLowerCase().contains(query.toLowerCase())).toList();
        }
        return list.isEmpty ? _Empty(isDark: isDark) : _Grid(apps: list, isDark: isDark);
      },
      loading: () => const Center(child: _Loader()),
      error: (e, s) => _Empty(isDark: isDark),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRID — paginado
// ═══════════════════════════════════════════════════════════════════════════════

class _Grid extends StatefulWidget {
  final List<InstalledApp> apps;
  final bool isDark;
  const _Grid({required this.apps, required this.isDark});

  @override
  State<_Grid> createState() => _GridState();
}

class _GridState extends State<_Grid> {
  int _page = 0;
  static const _perPage = 18;

  @override
  void didUpdateWidget(_Grid old) {
    super.didUpdateWidget(old);
    if (old.apps != widget.apps) _page = 0;
  }

  int get _pages => (widget.apps.length / _perPage).ceil();

  @override
  Widget build(BuildContext context) {
    final start = _page * _perPage;
    final end = (start + _perPage).clamp(0, widget.apps.length);
    final items = widget.apps.sublist(start, end);

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisExtent: 180,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _Card(key: ValueKey(items[i].id), app: items[i], isDark: widget.isDark),
          ),
        ),
        if (_pages > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Arrow(left: true, enabled: _page > 0, isDark: widget.isDark,
                    onTap: () => setState(() => _page--)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${_page + 1}/$_pages',
                      style: TextStyle(fontSize: 10, color: AppTheme.grey)),
                ),
                _Arrow(left: false, enabled: _page < _pages - 1, isDark: widget.isDark,
                    onTap: () => setState(() => _page++)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final bool left;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;
  const _Arrow({required this.left, required this.enabled, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? AppTheme.borderDark : const Color(0xFFE0E0E0)),
        ),
        child: Icon(
          left ? Icons.chevron_left : Icons.chevron_right,
          size: 16,
          color: enabled ? (isDark ? AppTheme.inkDark : AppTheme.ink) : AppTheme.greyLight,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CARD — estilo pixel ghost: fondo blanco, borde sólido, sin sombras
// ═══════════════════════════════════════════════════════════════════════════════

class _Card extends ConsumerStatefulWidget {
  final InstalledApp app;
  final bool isDark;
  const _Card({super.key, required this.app, required this.isDark});

  @override
  ConsumerState<_Card> createState() => _CardState();
}

class _CardState extends ConsumerState<_Card> {
  bool _deleting = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final isDark = widget.isDark;
    final theme = Theme.of(context);
    final isProtected = ref.watch(protectedAppsProvider).contains(app.id);
    final outline = isDark ? AppTheme.borderDark : const Color(0xFFE0E0E0);

    if (_deleting) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
        ),
        child: const Center(child: _Loader(color: AppTheme.danger)),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark
              ? (_hover ? const Color(0xFF1F1F1F) : AppTheme.surfaceDark)
              : (_hover ? const Color(0xFFFAFAFA) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isProtected
                ? AppTheme.success.withValues(alpha: 0.5)
                : (_hover ? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCCCCCC)) : outline),
            width: isProtected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
        children: [
          const SizedBox(height: 4),
          // Icono
          _Icon(app: app, isDark: isDark, size: 44),
          const SizedBox(height: 8),
          // Nombre
          Text(app.name, style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          // Info
          Text('${app.packageManager.label} · ${app.formattedSize}',
              style: theme.textTheme.labelSmall, textAlign: TextAlign.center),

          const Spacer(),

          // Botones
          if (isProtected)
            _Btn(label: '🔓 Desbloquear', color: AppTheme.warning,
                isDark: isDark, onTap: () => ref.read(protectedAppsProvider.notifier).toggle(app.id))
          else
            Row(
              children: [
                Expanded(child: _Btn(label: '🗑 Eliminar', color: AppTheme.danger,
                    isDark: isDark, onTap: () => _remove(context, app))),
                const SizedBox(width: 4),
                _Btn(label: '🔒', color: AppTheme.grey, isDark: isDark, square: true,
                    onTap: () => ref.read(protectedAppsProvider.notifier).toggle(app.id)),
              ],
            ),
        ],
      ),
      ),
    );
  }

  void _remove(BuildContext context, InstalledApp app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Image.asset('assets/images/ghostb.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Expanded(child: Text('¿Eliminar ${app.name}?', style: const TextStyle(fontSize: 14))),
          ],
        ),
        content: const Text('Se eliminará el paquete y todos sus archivos residuales.',
            style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _deleting = true);
              await ref.read(removeAppProvider(app).future);
              if (mounted) setState(() => _deleting = false);
              ref.invalidate(searchResultsProvider);
              ref.invalidate(installedAppsProvider);
              ref.invalidate(heavyAppsProvider);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED
// ═══════════════════════════════════════════════════════════════════════════════

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool square;

  const _Btn({required this.label, required this.color,
      required this.isDark, required this.onTap, this.square = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        width: square ? 28 : null,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ),
      ),
    );
  }
}

class _Icon extends StatefulWidget {
  final InstalledApp app;
  final bool isDark;
  final double size;
  const _Icon({required this.app, required this.isDark, this.size = 44});

  @override
  State<_Icon> createState() => _IconState();
}

class _IconState extends State<_Icon> {
  String? _path;

  @override
  void initState() {
    super.initState();
    if (widget.app.iconPath != null) { _path = widget.app.iconPath; return; }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = _find(widget.app.name);
      if (p != null && mounted) setState(() => _path = p);
    });
  }

  static String? _find(String name) {
    final n = name.toLowerCase();
    for (final dir in ['/usr/share/icons/hicolor/128x128/apps',
        '/usr/share/icons/hicolor/64x64/apps', '/usr/share/icons/hicolor/48x48/apps',
        '/usr/share/pixmaps']) {
      final f = File('$dir/$n.png');
      if (f.existsSync()) return f.path;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_path != null) {
      final f = File(_path!);
      if (f.existsSync() && !_path!.endsWith('.svg')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.size * 0.2),
          child: Image.file(f, width: widget.size, height: widget.size,
              fit: BoxFit.cover, cacheWidth: (widget.size * 2).toInt(),
              errorBuilder: (ctx, err, st) => _fb()),
        );
      }
    }
    return _fb();
  }

  Widget _fb() {
    return Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(widget.size * 0.2),
      ),
      child: Center(child: Text(widget.app.category.emoji,
          style: TextStyle(fontSize: widget.size * 0.4))),
    );
  }
}

class _Loader extends StatelessWidget {
  final Color color;
  const _Loader({this.color = AppTheme.grey});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color));
  }
}

class _Welcome extends StatelessWidget {
  final bool isDark;
  const _Welcome({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/ghostb.png', width: 48, height: 48,
              opacity: const AlwaysStoppedAnimation(0.5)),
          const SizedBox(height: 12),
          Text('Escribe para buscar', style: TextStyle(
              fontSize: 11, color: isDark ? AppTheme.greyDark : AppTheme.grey)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isDark;
  final String msg;
  const _Empty({required this.isDark, this.msg = 'Sin resultados'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(msg, style: TextStyle(
          fontSize: 11, color: isDark ? AppTheme.greyDark : AppTheme.grey)),
    );
  }
}
