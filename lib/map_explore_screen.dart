import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_feedback.dart';
import 'item_detail_screen.dart';
import 'map_items_service.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  static const LatLng _fallbackCenter = LatLng(-6.966667, 110.416664);
  final MapController _mapController = MapController();
  final MapItemsService _itemsService = const MapItemsService();
  final TextEditingController _searchController = TextEditingController();

  final List<_UiCategory> _categories = [_UiCategory.all()];

  LatLng _center = _fallbackCenter;
  LatLng? _pendingMoveCenter;
  double? _pendingMoveZoom;
  bool _isMapReady = false;
  double _currentZoom = 13;
  int _radiusKm = 5;
  bool _isLoadingMap = true;
  bool _isRefreshingInfo = false;
  bool _isSearching = false;
  bool _isResolvingAddress = false;
  String? _error;
  String _centerAddressLabel = 'Memuat alamat titik...';
  List<MapItem> _items = const [];
  MapItem? _selected;
  String _selectedCategoryKey = 'all';
  int _fetchVersion = 0;

  Timer? _moveDebounce;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadCategories();
    await _resolveInitialCenter();
    _queueOrMoveMap(_center, 14);
    await _resolveCenterAddress();
    await _fetchItems(firstLoad: true);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _itemsService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories.addAll(
          categories.map(
            (cat) => _UiCategory(
              key: cat.id,
              label: cat.label,
              apiCategoryId: cat.id,
            ),
          ),
        );
      });
    } catch (_) {
      // Keep "All" fallback silently.
    }
  }

  Future<void> _resolveInitialCenter() async {
    LatLng? savedCenter;
    String? savedLabel;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('user_default_lat');
      final lng = prefs.getDouble('user_default_lng');
      final label = prefs.getString('user_default_location');
      if (lat != null && lng != null) {
        savedCenter = LatLng(lat, lng);
      }
      if (label != null && label.trim().isNotEmpty) {
        savedLabel = label.trim();
      }
    } catch (_) {}

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (savedCenter != null) {
          _center = savedCenter;
          _centerAddressLabel = savedLabel ?? 'Lokasi Utama';
        } else {
          _center = _fallbackCenter;
          _centerAddressLabel = 'Lokasi Utama';
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (savedCenter != null) {
          _center = savedCenter;
          _centerAddressLabel = savedLabel ?? 'Lokasi Utama';
        } else {
          _center = _fallbackCenter;
          _centerAddressLabel = 'Lokasi Utama';
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _center = LatLng(position.latitude, position.longitude);
    } catch (_) {
      if (savedCenter != null) {
        _center = savedCenter;
        _centerAddressLabel = savedLabel ?? 'Lokasi Utama';
      } else {
        _center = _fallbackCenter;
        _centerAddressLabel = 'Lokasi Utama';
      }
    }
  }

  _UiCategory get _selectedCategory {
    for (final category in _categories) {
      if (category.key == _selectedCategoryKey) {
        return category;
      }
    }
    return _categories.first;
  }

  int get _activeFilterCount => _selectedCategory.isAll ? 0 : 1;

  List<MapItem> get _visibleItems {
    final base = _items;
    if (_selectedCategory.isAll) return base;
    final label = _selectedCategory.label.toLowerCase();
    return base.where((item) {
      final categoryName = item.categoryName.toLowerCase();
      return categoryName.contains(label) || item.categoryId == _selectedCategory.apiCategoryId;
    }).toList();
  }

  Future<void> _fetchItems({bool firstLoad = false}) async {
    final requestVersion = ++_fetchVersion;
    setState(() {
      if (firstLoad) {
        _isLoadingMap = true;
      } else {
        _isRefreshingInfo = true;
      }
      _error = null;
    });

    try {
      final selected = _selectedCategory;
      final items = await _itemsService.fetchNearbyItems(
        lat: _center.latitude,
        lng: _center.longitude,
        radiusKm: _radiusKm,
        categoryId: selected.isAll ? null : selected.apiCategoryId,
      );
      if (!mounted || requestVersion != _fetchVersion) return;
      setState(() {
        _items = items;
        if (_selected != null) {
          final stillExists = _visibleItems.any((item) => item.id == _selected!.id);
          if (!stillExists) _selected = null;
        }
      });
    } catch (e) {
      if (!mounted || requestVersion != _fetchVersion) return;
      setState(() {
        _error = e.toString();
      });
      if (!firstLoad) {
        showAppErrorSnack(context, _error ?? 'Gagal memuat barang terdekat.');
      }
    } finally {
      if (mounted && requestVersion == _fetchVersion) {
        setState(() {
          _isLoadingMap = false;
          _isRefreshingInfo = false;
        });
      }
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _currentZoom = camera.zoom;
    if (!hasGesture) return;
    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 550), () async {
      if (!mounted) return;
      setState(() {
        _center = camera.center;
        _selected = null;
      });
      await _resolveCenterAddress();
      await _fetchItems();
    });
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        showAppErrorSnack(context, 'Layanan lokasi di perangkat sedang mati.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        showAppErrorSnack(context, 'Izin lokasi belum diberikan.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final next = LatLng(position.latitude, position.longitude);
      _queueOrMoveMap(next, 14);
      setState(() {
        _center = next;
        _selected = null;
      });
      await _resolveCenterAddress();
      await _fetchItems();
    } catch (_) {
      if (!mounted) return;
      showAppErrorSnack(context, 'Gagal mengambil lokasi GPS saat ini.');
    }
  }

  Future<void> _searchLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
        queryParameters: {
          'q': trimmed,
          'format': 'jsonv2',
          'limit': '1',
          'countrycodes': 'id',
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'sewainaja-mobile/1.0 (map-search)',
        },
      );
      final list = jsonDecode(response.body) as List<dynamic>;
      if (response.statusCode != 200 || list.isEmpty) {
        if (!mounted) return;
        showAppErrorSnack(context, 'Lokasi tidak ditemukan. Coba kata kunci lain.');
        return;
      }

      final result = list.first as Map<String, dynamic>;
      final lat = double.tryParse((result['lat'] ?? '').toString());
      final lon = double.tryParse((result['lon'] ?? '').toString());
      if (lat == null || lon == null) {
        if (!mounted) return;
        showAppErrorSnack(context, 'Koordinat lokasi tidak valid.');
        return;
      }

      final next = LatLng(lat, lon);
      _queueOrMoveMap(next, 14);
      setState(() {
        _center = next;
        _selected = null;
      });
      await _resolveCenterAddress(prefilled: result['display_name']?.toString());
      await _fetchItems();
    } catch (_) {
      if (!mounted) return;
      showAppErrorSnack(context, 'Gagal mencari lokasi.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _resolveCenterAddress({String? prefilled}) async {
    if (prefilled != null && prefilled.trim().isNotEmpty) {
      setState(() => _centerAddressLabel = _shortAddress(prefilled));
      return;
    }
    setState(() => _isResolvingAddress = true);
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
        queryParameters: {
          'lat': _center.latitude.toString(),
          'lon': _center.longitude.toString(),
          'format': 'jsonv2',
          'zoom': '16',
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'sewainaja-mobile/1.0 (reverse-geocode)',
        },
      );
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = (body['display_name'] ?? '').toString();
      if (displayName.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _centerAddressLabel = _shortAddress(displayName);
      });
    } catch (_) {
      // Keep last label.
    } finally {
      if (mounted) setState(() => _isResolvingAddress = false);
    }
  }

  String _shortAddress(String raw) {
    final parts = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 3) {
      return '${parts[0]}, ${parts[1]}, ${parts[2]}';
    }
    if (parts.isNotEmpty) return parts.join(', ');
    return 'Alamat tidak tersedia';
  }

  String _formatPrice(double value) {
    final raw = value.round().toString();
    final chars = raw.split('').reversed.toList();
    final chunks = <String>[];
    for (int i = 0; i < chars.length; i += 3) {
      final end = (i + 3 < chars.length) ? i + 3 : chars.length;
      chunks.add(chars.sublist(i, end).join());
    }
    final joined = chunks.map((c) => c.split('').reversed.join()).toList().reversed.join('.');
    return 'Rp.$joined/jam';
  }

  bool _useCompactMarkers(List<MapItem> items) {
    final zoom = _currentZoom;
    return items.length >= 8 || zoom <= 12.8;
  }

  void _queueOrMoveMap(LatLng center, double zoom) {
    _currentZoom = zoom;
    if (_isMapReady) {
      _mapController.move(center, zoom);
      return;
    }
    _pendingMoveCenter = center;
    _pendingMoveZoom = zoom;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final compactMarkers = _useCompactMarkers(items);
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onMapReady: () {
                _isMapReady = true;
                final pendingCenter = _pendingMoveCenter;
                final pendingZoom = _pendingMoveZoom;
                if (pendingCenter != null && pendingZoom != null) {
                  _mapController.move(pendingCenter, pendingZoom);
                  _pendingMoveCenter = null;
                  _pendingMoveZoom = null;
                }
              },
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sewainaja.app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _center,
                    radius: _radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: const Color(0xFF2F6743).withValues(alpha: 0.15),
                    borderColor: const Color(0xFF012D1D),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: items
                    .map(
                      (item) => Marker(
                        point: LatLng(item.latitude, item.longitude),
                        width: compactMarkers ? 62 : 88,
                        height: compactMarkers ? 85 : 105,
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = item),
                          child: _PhotoMarker(
                            item: item,
                            selected: _selected?.id == item.id,
                            priceLabel: _formatPrice(item.pricePerHour).replaceAll('/jam', ''),
                            compact: compactMarkers,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: const Icon(
                Icons.place_rounded,
                size: 40,
                color: Color(0xFF012D1D),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _ActionBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF012D1D),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                  ),
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: _searchLocation,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Cari lokasi...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: Color(0xFF717973),
                                    ),
                                  ),
                                ),
                              ),
                              if (_isSearching)
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF012D1D),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final selected = category.key == _selectedCategoryKey;
                        return GestureDetector(
                          onTap: () async {
                            if (selected) return;
                            setState(() {
                              _selectedCategoryKey = category.key;
                              _selected = null;
                            });
                            await _fetchItems();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF012D1D)
                                  : const Color(0xFFFDF9F4),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF012D1D)
                                    : const Color(0xFFD9D9D9),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                category.label,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF012D1D),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_activeFilterCount > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF012D1D),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$_activeFilterCount filter aktif',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 238,
            child: Column(
              children: [
                _ActionBtn(
                  icon: Icons.my_location_rounded,
                  onTap: _moveToCurrentLocation,
                ),
                const SizedBox(height: 10),
                _ActionBtn(
                  icon: Icons.add_rounded,
                  onTap: () => _queueOrMoveMap(_center, _currentZoom + 1),
                ),
                const SizedBox(height: 10),
                _ActionBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => _queueOrMoveMap(_center, _currentZoom - 1),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EF),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          color: Color(0xFF012D1D),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _centerAddressLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF012D1D),
                            ),
                          ),
                        ),
                        if (_isResolvingAddress)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF012D1D),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Radius Pencarian',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_radiusKm km',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radiusKm.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: '$_radiusKm km',
                      onChanged: (value) {
                        final rounded = value.round();
                        if (rounded != _radiusKm) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() => _radiusKm = rounded);
                      },
                      onChangeEnd: (_) => _fetchItems(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1', style: _TickStyle.textStyle),
                          Text('5', style: _TickStyle.textStyle),
                          Text('10', style: _TickStyle.textStyle),
                          Text('20 km', style: _TickStyle.textStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingMap || _isRefreshingInfo)
                      const _InfoSkeleton()
                    else if (_error != null)
                      InlineErrorState(
                        message: _error!,
                        onRetry: _fetchItems,
                      )
                    else if (_selected != null)
                      _SelectedItemCard(
                        item: _selected!,
                        priceLabel: _formatPrice(_selected!.pricePerHour),
                      )
                    else if (items.isEmpty)
                      _EmptyResultCard(
                        onExpandRadius: () {
                          setState(() => _radiusKm = (_radiusKm + 5).clamp(1, 20));
                          _fetchItems();
                        },
                        onClearFilter: () {
                          setState(() => _selectedCategoryKey = 'all');
                          _fetchItems();
                        },
                      )
                    else
                      Text(
                        '${items.length} barang dalam jangkauan.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF414844),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickStyle {
  static const textStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF717973),
  );
}

class _UiCategory {
  final String key;
  final String label;
  final String? apiCategoryId;

  const _UiCategory({
    required this.key,
    required this.label,
    this.apiCategoryId,
  });

  factory _UiCategory.all() =>
      const _UiCategory(key: 'all', label: 'All', apiCategoryId: null);

  bool get isAll => key == 'all';
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF012D1D), size: 20),
      ),
    );
  }
}

class _PhotoMarker extends StatelessWidget {
  final MapItem item;
  final bool selected;
  final String priceLabel;
  final bool compact;

  const _PhotoMarker({
    required this.item,
    required this.selected,
    required this.priceLabel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(compact ? 3 : 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(
              color: selected ? const Color(0xFF012D1D) : const Color(0xFFD9D9D9),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x66012D1D)
                    : const Color(0x29000000),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(compact ? 9 : 10),
                child: SizedBox(
                  width: compact ? 40 : 52,
                  height: compact ? 32 : 40,
                  child: item.photoUrl.isNotEmpty
                      ? Image.network(
                              item.photoUrl,
                              fit: BoxFit.cover,
                              cacheWidth: compact ? 80 : 100, // Decode as tiny thumbnail to avoid lag
                              errorBuilder: (context, error, stackTrace) =>
                                  const _MarkerImageFallback(),
                            )
                          : const _MarkerImageFallback(),
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 56),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF012D1D) : const Color(0xFF2F6743),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            priceLabel,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _MarkerImageFallback extends StatelessWidget {
  const _MarkerImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8ECE8),
      child: const Center(
        child: Icon(
          Icons.photo_camera_back_outlined,
          size: 18,
          color: Color(0xFF56705F),
        ),
      ),
    );
  }
}

class _SelectedItemCard extends StatelessWidget {
  final MapItem item;
  final String priceLabel;

  const _SelectedItemCard({required this.item, required this.priceLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.photoUrl.isNotEmpty
                  ? Image.network(
                      item.photoUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 120, // Optimize memory for preview card
                      errorBuilder: (context, error, stackTrace) =>
                          const _MarkerImageFallback(),
                    )
                  : const _MarkerImageFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$priceLabel • ${item.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF414844),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(
                    itemId: item.id,
                    itemName: item.name,
                    pricePerHour: item.pricePerHour,
                    imagePath: item.photoUrl,
                  ),
                ),
              );
            },
            child: const Text(
              'Lihat Detail',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF012D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSkeleton extends StatelessWidget {
  const _InfoSkeleton();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.8),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, opacity, _) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECE8).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  final VoidCallback onExpandRadius;
  final VoidCallback onClearFilter;

  const _EmptyResultCard({
    required this.onExpandRadius,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Belum ada barang di area ini.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba perluas radius atau reset filter kategori.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Color(0xFF414844),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onExpandRadius,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2F6743)),
                  ),
                  child: const Text(
                    'Perluas Radius',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2F6743),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onClearFilter,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7B5804)),
                  ),
                  child: const Text(
                    'Hapus Filter',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B5804),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
