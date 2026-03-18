import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedPosition;
  
  // Posizione di default (Italia / Roma)
  final LatLng _initialCenter = const LatLng(41.9028, 12.4964);

  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedPosition = latlng;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona Posizione'),
        actions: [
          if (_selectedPosition != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _selectedPosition);
              },
            )
        ],
      ),
      body: FlutterMap(
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
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
