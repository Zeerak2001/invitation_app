import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const _dark = Color(0xFF222222);
const _bg = Color(0xFFF6F6F6);

// Nominatim requires an identifying User-Agent. Put your real app id here.
const _userAgent = 'InvitationApp/1.0 (com.example.invitation_app)';

/// Builds a SHORT label like "ABX Lawn, FB Area, Karachi" from a Nominatim
/// result instead of the full street address.
String shortLabel(Map<String, dynamic> j) {
  final a = (j['address'] as Map?)?.cast<String, dynamic>() ?? {};

  String? pick(List<String> keys) {
    for (final k in keys) {
      final v = a[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  final name = (j['name'] as String?)?.trim();
  final place = (name != null && name.isNotEmpty)
      ? name
      : pick(['amenity', 'tourism', 'leisure', 'building', 'shop', 'road']);
  final area = pick(['suburb', 'neighbourhood', 'quarter', 'city_district']);
  final city = pick(['city', 'town', 'village', 'county']);

  final parts = <String>[];
  for (final p in [place, area, city]) {
    if (p != null && !parts.contains(p)) parts.add(p);
  }
  return parts.join(', ');
}

class _Place {
  final String label;
  final LatLng point;
  const _Place(this.label, this.point);
}

/// Returns the short venue label via Navigator.pop(context, label).
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _searchCtl = TextEditingController();
  final _labelCtl = TextEditingController();

  LatLng? _picked;
  List<_Place> _results = [];
  bool _loading = false;
  Timer? _debounce;
  double? _userLat;
  double? _userLon;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    _labelCtl.dispose();
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('Location services are disabled. Opening settings...');
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _snack('Location permission denied. Opening app settings...');
          await Geolocator.openAppSettings();
          return;
        }
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) {
        _snack('Could not get GPS fix. Please check location settings.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _userLat = pos!.latitude;
        _userLon = pos.longitude;
      });
      _map.move(LatLng(pos.latitude, pos.longitude), 15);
    } catch (e) {
      _snack('Location error: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    q = q.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(q);
    });
  }

  Future<void> _search(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _results = [];
    });
    try {
      final params = <String, String>{
        'q': q,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '6',
        'accept-language': 'en',
      };
      if (_userLat != null && _userLon != null) {
        params['lat'] = '$_userLat';
        params['lon'] = '$_userLon';
        final d = 0.5;
        params['viewbox'] =
            '${_userLon! - d},${_userLat! + d},${_userLon! + d},${_userLat! - d}';
      }
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
      final res = await http.get(
        uri,
        headers: {'User-Agent': _userAgent, 'Accept-Language': 'en'},
      );
      final list = jsonDecode(res.body) as List;
      final found = list.map((e) {
        final j = e as Map<String, dynamic>;
        return _Place(
          shortLabel(j),
          LatLng(double.parse(j['lat']), double.parse(j['lon'])),
        );
      }).toList();
      if (!mounted) return;
      setState(() => _results = found);
      if (found.isEmpty) _snack('No places found');
    } catch (_) {
      if (mounted) _snack('Search failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(LatLng p, String label) {
    setState(() {
      _picked = p;
      _results = [];
    });
    _labelCtl.text = label;
    _map.move(p, 16);
  }

  Future<void> _onTapMap(LatLng p) async {
    setState(() {
      _picked = p;
      _results = [];
    });
    _labelCtl.text = '';
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '${p.latitude}',
        'lon': '${p.longitude}',
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '18',
        'accept-language': 'en',
      });
      final res = await http.get(
        uri,
        headers: {'User-Agent': _userAgent, 'Accept-Language': 'en'},
      );
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted && _picked == p) _labelCtl.text = shortLabel(j);
    } catch (_) {
      // Leave empty; the user can type the venue name.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: const LatLng(24.8607, 67.0011), // Karachi
              initialZoom: 12,
              onTap: (_, point) => _onTapMap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.invitation_app',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: _dark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtl,
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search venue or area',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _loading
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _initUserLocation,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.my_location, color: _dark),
                        ),
                      ),
                    ],
                  ),
                  if (_results.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (final r in _results)
                            ListTile(
                              leading: const Icon(Icons.place_outlined),
                              title: Text(
                                r.label.isEmpty ? 'Unnamed place' : r.label,
                              ),
                              onTap: () => _select(r.point, r.label),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_picked != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Venue on the card',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Edit it if needed, e.g. ABX Lawn, FB Area, Karachi',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _labelCtl,
                      cursorColor: _dark,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        final t = _labelCtl.text.trim();
                        if (t.isEmpty) {
                          _snack('Type a venue name first');
                          return;
                        }
                        Navigator.pop(context, t);
                      },
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _dark,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Use this location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
