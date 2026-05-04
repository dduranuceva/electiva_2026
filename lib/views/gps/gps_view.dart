import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/permissions_service.dart';
import '../../widgets/base_view.dart';

const _green = Color.fromARGB(255, 20, 165, 97);
// Buga, Valle del Cauca — centro por defecto si no hay GPS
const _defaultCenter = LatLng(3.9003, -76.2987);

class GpsView extends StatefulWidget {
  const GpsView({super.key});

  @override
  State<GpsView> createState() => _GpsViewState();
}

class _GpsViewState extends State<GpsView> {
  Position? _position;
  StreamSubscription<Position>? _stream;
  final _mapController = MapController();
  bool _loading = true;
  bool _mapReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _stream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final granted = await PermissionsService.requestLocation();
    if (!granted) {
      setState(() {
        _error = 'Permiso de ubicación denegado.\n'
            'Ve a Configuración > Aplicaciones para activarlo.';
        _loading = false;
      });
      return;
    }

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      setState(() {
        _error = 'El GPS del dispositivo está desactivado.\n'
            'Actívalo en Configuración > Ubicación.';
        _loading = false;
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _position = pos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo obtener la ubicación: $e';
        _loading = false;
      });
      return;
    }

    _stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      setState(() => _position = pos);
      if (_mapReady) {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.camera.zoom,
        );
      }
    });
  }

  void _centerOnMe() {
    if (_position != null && _mapReady) {
      _mapController.move(
        LatLng(_position!.latitude, _position!.longitude),
        16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'GPS — Mi Ubicación',
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Obteniendo ubicación…'),
                ],
              ),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final center = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : _defaultCenter;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15.0,
                  onMapReady: () => setState(() => _mapReady = true),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.electiva_2026',
                  ),
                  if (_position != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _position!.latitude,
                            _position!.longitude,
                          ),
                          width: 56,
                          height: 56,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 48,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black38,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  onPressed: _centerOnMe,
                  backgroundColor: Colors.white,
                  foregroundColor: _green,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
        _buildInfoCard(),
      ],
    );
  }

  Widget _buildInfoCard() {
    final pos = _position;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: pos == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text('Esperando señal GPS…'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: _green, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Ubicación en tiempo real',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Activo',
                      style: TextStyle(fontSize: 12, color: _green),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip(
                      'Latitud',
                      pos.latitude.toStringAsFixed(6),
                      Icons.north,
                    ),
                    const SizedBox(width: 10),
                    _chip(
                      'Longitud',
                      pos.longitude.toStringAsFixed(6),
                      Icons.east,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip(
                      'Altitud',
                      '${pos.altitude.toStringAsFixed(1)} m',
                      Icons.height,
                    ),
                    const SizedBox(width: 10),
                    _chip(
                      'Precisión',
                      '±${pos.accuracy.toStringAsFixed(1)} m',
                      Icons.radar,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _green.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: _green),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
