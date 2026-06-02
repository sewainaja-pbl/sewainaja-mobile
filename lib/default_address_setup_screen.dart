import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'address_service.dart';
import 'app_feedback.dart';
import 'main_navigation_screen.dart';
import 'map_common_widgets.dart';
import 'profile_sync_service.dart';

class DefaultAddressResult {
  final String label;
  final LatLng center;

  const DefaultAddressResult({required this.label, required this.center});
}

class DefaultAddressSetupScreen extends StatefulWidget {
  final bool returnSelectionOnSave;
  final LatLng? initialCenter;
  final String? initialLabel;

  const DefaultAddressSetupScreen({
    super.key,
    this.returnSelectionOnSave = false,
    this.initialCenter,
    this.initialLabel,
  });

  @override
  State<DefaultAddressSetupScreen> createState() => _DefaultAddressSetupScreenState();
}

class _DefaultAddressSetupScreenState extends State<DefaultAddressSetupScreen> {
  static const LatLng _fallback = LatLng(-6.966667, 110.416664);
  final AddressService _addressService = const AddressService();

  LatLng _center = _fallback;
  String _addressLabel = 'Semarang, Jawa Tengah';
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      _center = widget.initialCenter!;
      _isLoadingLocation = false;
    }
    if (widget.initialLabel != null && widget.initialLabel!.trim().isNotEmpty) {
      _addressLabel = widget.initialLabel!.trim();
    }
    
    if (widget.initialCenter == null) {
      _initLocation();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onMapCameraMove(LatLng newCenter) {
    setState(() {
      _center = newCenter;
    });
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode();
    });
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _center = LatLng(current.latitude, current.longitude);
      await _reverseGeocode();
    } catch (_) {
      // fallback
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _reverseGeocode() async {
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
        headers: {'User-Agent': 'sewainaja-mobile/1.0 (default-address)'},
      );
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = (body['display_name'] ?? '').toString().trim();
      if (raw.isEmpty) return;
      if (!mounted) return;
      setState(() => _addressLabel = _shortAddress(raw));
    } catch (_) {}
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
    return parts.isNotEmpty ? parts.join(', ') : 'Semarang, Jawa Tengah';
  }

  Future<void> _saveAndContinue() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_default_location', _addressLabel);
      await prefs.setDouble('user_default_lat', _center.latitude);
      await prefs.setDouble('user_default_lng', _center.longitude);

      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        try {
          await _addressService.upsertDefaultAddress(
            label: 'Alamat Utama',
            fullAddress: _addressLabel,
            latitude: _center.latitude,
            longitude: _center.longitude,
          );
        } catch (e) {
          if (!mounted) return;
          showAppErrorSnack(context, e.toString());
        }
      }

      ProfileSyncService.profileRevision.value++;
      if (!mounted) return;
      if (widget.returnSelectionOnSave) {
        Navigator.of(context).pop(
          DefaultAddressResult(label: _addressLabel, center: _center),
        );
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _skip() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EF),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF012D1D)),
        title: const Text(
          'Set Alamat Utama',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih alamat default untuk pencarian barang terdekat.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF414844),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF012D1D).withValues(alpha: 0.18),
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: ReusableMapCard(
                center: _center,
                zoom: 14,
                interactive: true,
                showCenterPin: true,
                onCenterChanged: _onMapCameraMove,
                overlayLabel: _addressLabel,
                height: 210,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingLocation)
              const LinearProgressIndicator(color: Color(0xFF012D1D), minHeight: 2),
            const SizedBox(height: 8),
            Text(
              _addressLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF012D1D),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _initLocation,
                icon: const Icon(Icons.my_location_rounded),
                label: const Text(
                  'Gunakan Lokasi Saat Ini',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2F6743),
                  side: const BorderSide(color: Color(0xFF2F6743)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5804),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Simpan & Lanjut',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            TextButton(
              onPressed: _skip,
              child: const Center(
                child: Text(
                  'Lewati Dulu',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF717973),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
