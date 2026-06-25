import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PlaceLocationSelection {
  final double latitude;
  final double longitude;

  const PlaceLocationSelection({
    required this.latitude,
    required this.longitude,
  });
}

class PlaceLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialSearchQuery;

  const PlaceLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialSearchQuery,
  });

  @override
  State<PlaceLocationPickerScreen> createState() =>
      _PlaceLocationPickerScreenState();
}

class _PlaceLocationPickerScreenState extends State<PlaceLocationPickerScreen> {
  static const _turkeyCenter = LatLng(39.0, 35.0);
  final _mapController = MapController();
  final _searchController = TextEditingController();
  LatLng? _selectedPoint;
  List<_LocationSearchResult> _searchResults = const [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    }
    _searchController.text = widget.initialSearchQuery?.trim() ?? '';
    if (_selectedPoint == null && _searchController.text.length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchLocation(_searchController.text, selectFirst: false);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(
    String rawQuery, {
    bool selectFirst = false,
  }) async {
    final query = rawQuery.trim();
    if (query.length < 3 || _isSearching) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'countrycodes': 'tr',
        'limit': '5',
        'q': query,
      });
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'UniSec/1.0 (com.unisec.app)',
              'Accept-Language': 'tr',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Arama servisi ${response.statusCode} döndürdü.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException('Geçersiz yanıt');
      final results = decoded
          .whereType<Map>()
          .map(
            (item) =>
                _LocationSearchResult.fromMap(Map<String, dynamic>.from(item)),
          )
          .where((item) => item != null)
          .cast<_LocationSearchResult>()
          .toList();

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searchError = results.isEmpty ? 'Sonuç bulunamadı.' : null;
      });
      if (results.isNotEmpty) {
        _focusResult(results.first, select: selectFirst);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _searchError = 'Konum aranamadı. İnternet bağlantını kontrol et.';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _focusResult(_LocationSearchResult result, {bool select = true}) {
    final point = LatLng(result.latitude, result.longitude);
    _mapController.move(point, select ? 16 : 14);
    setState(() {
      if (select) {
        _selectedPoint = point;
        _searchController.text = result.shortLabel;
        _searchResults = const [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedPoint ?? _turkeyCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        actions: [
          TextButton(
            onPressed: _selectedPoint == null
                ? null
                : () => Navigator.of(context).pop(
                    PlaceLocationSelection(
                      latitude: _selectedPoint!.latitude,
                      longitude: _selectedPoint!.longitude,
                    ),
                  ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: _selectedPoint == null ? 5.5 : 16,
              minZoom: 3,
              maxZoom: 19,
              onTap: (_, point) => setState(() {
                _selectedPoint = point;
                _searchResults = const [];
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.unisec.app',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.error,
                        size: 46,
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: AppColors.surfaceFor(context),
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchLocation,
                      decoration: InputDecoration(
                        hintText: 'Üniversite, mekan veya adres ara',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Ara',
                                onPressed: () =>
                                    _searchLocation(_searchController.text),
                                icon: const Icon(Icons.arrow_forward_rounded),
                              ),
                        border: InputBorder.none,
                      ),
                    ),
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _searchError!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    if (_searchResults.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                result.shortLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                result.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _focusResult(result),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Material(
                color: AppColors.surfaceFor(context),
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPoint == null
                            ? Icons.touch_app_rounded
                            : Icons.location_on_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedPoint == null
                              ? 'Önce ara, sonra doğru noktaya dokun.'
                              : '${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                                    '${_selectedPoint!.longitude.toStringAsFixed(6)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_selectedPoint != null)
                        IconButton(
                          tooltip: 'Seçimi temizle',
                          onPressed: () =>
                              setState(() => _selectedPoint = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const _LocationSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  String get shortLabel => displayName.split(',').first.trim();

  static _LocationSearchResult? fromMap(Map<String, dynamic> map) {
    final displayName = map['display_name'] as String?;
    final latitude = double.tryParse(map['lat']?.toString() ?? '');
    final longitude = double.tryParse(map['lon']?.toString() ?? '');
    if (displayName == null || latitude == null || longitude == null) {
      return null;
    }
    return _LocationSearchResult(
      displayName: displayName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
