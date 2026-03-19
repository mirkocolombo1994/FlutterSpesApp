import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedPosition;
  String? _selectedPlaceName;
  bool _isLoadingName = false;
  bool _isLocating = false;

  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(41.9028, 12.4964); // Roma

  @override
  void initState() {
    super.initState();
    _locateMe();
  }

  Future<void> _locateMe() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Servizi di localizzazione disabilitati.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permessi negati.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permessi negati permanentemente.');
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        _mapController.move(latLng, 17.0); // Zoom stretto
        _handleTap(TapPosition(const Offset(0, 0), const Offset(0, 0)), latLng);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _handleTap(TapPosition tapPosition, LatLng latlng) async {
    setState(() {
      _selectedPosition = latlng;
      _selectedPlaceName = null;
      _isLoadingName = true;
    });

    try {
      // 1. Prova prima con il Reverse Geocoding Standard (preciso al tap)
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${latlng.latitude}&lon=${latlng.longitude}&format=json&zoom=18&addressdetails=1');
      final response = await http.get(uri, headers: {
        'User-Agent': 'FlutterSpesApp/1.0.0 (mirkocolombo1994@github.com)',
        'Accept-Language': 'it'
      }).timeout(const Duration(seconds: 10));

      String? placeName;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['error'] == null) {
          if (data['display_name'] != null) {
            placeName = data['display_name'].toString().split(',').first.trim();
          }
        }
      } else {
        placeName = "HTTP Nom: ${response.statusCode} - ${response.body}";
      }

      // Se Nominatim ha fallito (es. 403) o non ha trovato nulla
      if (placeName == null || placeName.toLowerCase().startsWith('via ') || placeName.toLowerCase().startsWith('viale ')) {
        try {
          final overpassQuery = '''
            [out:json];
            (
              node["shop"="supermarket"](around:150, ${latlng.latitude}, ${latlng.longitude});
              way["shop"="supermarket"](around:150, ${latlng.latitude}, ${latlng.longitude});
              rel["shop"="supermarket"](around:150, ${latlng.latitude}, ${latlng.longitude});
              node["shop"="convenience"](around:150, ${latlng.latitude}, ${latlng.longitude});
            );
            out tags;
          ''';
          
          final overpassUri = Uri.parse('https://overpass-api.de/api/interpreter');
          final overpassResp = await http.post(overpassUri, body: overpassQuery, headers: {'User-Agent':'FlutterSpesApp/1.0.0 (mirkocolombo1994@github.com)'}).timeout(const Duration(seconds: 10));
          
          if (overpassResp.statusCode == 200) {
            final opData = json.decode(overpassResp.body);
            if (opData['elements'] != null && (opData['elements'] as List).isNotEmpty) {
               final elements = opData['elements'] as List;
               for (var el in elements) {
                 if (el['tags'] != null && el['tags']['name'] != null) {
                   placeName = el['tags']['name'] + " (Trovato nei dintorni)";
                   break;
                 }
               }
            }
          }
        } catch (_) {
        }
      }

      if (placeName == null || placeName.isEmpty || placeName.startsWith('HTTP')) {
         placeName = 'Coordinate scelte sulla mappa';
      }
      
      if (mounted) {
        setState(() {
          _selectedPlaceName = placeName;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedPlaceName = "Errore Rete/Timeout API";
        });
      }
      debugPrint("Errore Mappa: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona Posizione'),
        actions: [
          if (_selectedPosition != null)
            IconButton(
              icon: const Icon(Icons.check, size: 30),
              onPressed: () {
                Navigator.pop(context, {
                  'latLng': _selectedPosition,
                  'name': _selectedPlaceName,
                });
              },
            )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 6.0,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.task_master_app',
              ),
              if (_selectedPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      alignment: Alignment.topCenter,
                    ),
                  ],
                ),
            ],
          ),
          if (_selectedPosition != null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 80,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      if (_isLoadingName)
                         const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      if (!_isLoadingName)
                         const Icon(Icons.store, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isLoadingName ? 'Ricerca in corso...' : (_selectedPlaceName ?? 'Sconosciuto (Solo coordinate)'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
             right: 16,
             bottom: 30,
             child: FloatingActionButton(
                heroTag: 'gps_fab',
                onPressed: _locateMe,
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                child: _isLocating ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.my_location),
             )
          )
        ],
      ),
    );
  }
}
