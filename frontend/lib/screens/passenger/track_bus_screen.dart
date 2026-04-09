import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/bus_route.dart';
import '../../models/bus_routes_repository.dart';

class TrackBusScreen extends StatefulWidget {
  final String? routeId;

  const TrackBusScreen({super.key, this.routeId});

  @override
  State<TrackBusScreen> createState() => _TrackBusScreenState();
}

class _TrackBusScreenState extends State<TrackBusScreen> {
  GoogleMapController? mapController;
  BusRoute? selectedRoute;
  MapType _mapType = MapType.normal;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  LatLng? currentLocation;
  bool _isLoading = true;
  bool _mapReady = false;
  double _tilt = 0.0;
  double _bearing = 0.0;
  double _zoom = 14.0;
  Timer? _busMovementTimer;
  int _busStopIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load route data
    if (widget.routeId != null) {
      selectedRoute = BusRoutesRepository.getRouteById(widget.routeId!);
    } else {
      selectedRoute = BusRoutesRepository.allRoutes.first;
    }

    // Get current location
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentLocation = LatLng(position.latitude, position.longitude);
    } catch (_) {
      currentLocation = LatLng(28.6139, 77.2090); // Default to Delhi
    }

    _updateMapMarkers();
    setState(() => _isLoading = false);
  }

  void _updateMapMarkers() {
    if (selectedRoute == null) return;

    markers.clear();
    polylines.clear();
    final stops = selectedRoute!.stops;

    // Start marker (green)
    if (stops.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(stops.first.latitude, stops.first.longitude),
          infoWindow: InfoWindow(
            title: 'Start: ${stops.first.stopName}',
            snippet: 'Route starts here',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Stop markers (blue)
    for (int i = 1; i < stops.length - 1; i++) {
      final stop = stops[i];
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(stop.latitude, stop.longitude),
          infoWindow: InfoWindow(
            title: stop.stopName,
            snippet: 'ETA: ${stop.arrivalMinutes} mins',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // End marker (red)
    if (stops.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(stops.last.latitude, stops.last.longitude),
          infoWindow: InfoWindow(
            title: 'End: ${stops.last.stopName}',
            snippet: 'Route ends here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Live bus marker (simulated movement)
    if (stops.isNotEmpty) {
      final busStop = stops[_busStopIndex % stops.length];
      markers.add(
        Marker(
          markerId: const MarkerId('live_bus'),
          position: LatLng(busStop.latitude, busStop.longitude),
          infoWindow: InfoWindow(
            title: 'Live Bus',
            snippet: 'Current: ${busStop.stopName}',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    // Draw polyline
    final coordinates =
        stops.map((s) => LatLng(s.latitude, s.longitude)).toList();

    if (coordinates.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: coordinates,
          color: const Color(0xFFFFC107),
          width: 5,
          geodesic: true,
        ),
      );
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    _mapReady = true;
    if (selectedRoute != null && selectedRoute!.stops.isNotEmpty) {
      _fitRouteBounds();
    }
    _startLiveBusSimulation();
  }

  void _fitRouteBounds() {
    if (!_mapReady || mapController == null) return;
    if (selectedRoute == null || selectedRoute!.stops.isEmpty) return;

    final stops = selectedRoute!.stops;
    double minLat = stops.first.latitude;
    double maxLat = stops.first.latitude;
    double minLng = stops.first.longitude;
    double maxLng = stops.first.longitude;

    for (final stop in stops) {
      minLat = minLat > stop.latitude ? stop.latitude : minLat;
      maxLat = maxLat < stop.latitude ? stop.latitude : maxLat;
      minLng = minLng > stop.longitude ? stop.longitude : minLng;
      maxLng = maxLng < stop.longitude ? stop.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _updateCamera() {
    if (!_mapReady || mapController == null) return;
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLocation ?? const LatLng(28.6139, 77.2090),
          zoom: _zoom,
          tilt: _tilt,
          bearing: _bearing,
        ),
      ),
    );
  }

  void _startLiveBusSimulation() {
    _busMovementTimer?.cancel();
    _busMovementTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || selectedRoute == null || selectedRoute!.stops.isEmpty) {
        return;
      }
      setState(() {
        _busStopIndex = (_busStopIndex + 1) % selectedRoute!.stops.length;
        _updateMapMarkers();
      });
    });
  }

  @override
  void dispose() {
    _busMovementTimer?.cancel();
    if (!kIsWeb && _mapReady) {
      mapController?.dispose();
    }
    mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showFixedSidePanel = screenWidth >= 980;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bus Tracking - ${selectedRoute?.routeNumber ?? "N/A"}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (selectedRoute != null)
              Text(
                '${selectedRoute!.source} → ${selectedRoute!.destination}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.8),
                    ),
              ),
          ],
        ),
        actions: [
          if (!showFixedSidePanel)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_open),
                tooltip: 'Map Features',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      endDrawer: showFixedSidePanel
          ? null
          : Drawer(
              width: 340,
              child: SafeArea(
                child: _buildSidePanel(colorScheme, isDrawer: true),
              ),
            ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: currentLocation ?? const LatLng(28.6139, 77.2090),
                      zoom: _zoom,
                      tilt: _tilt,
                      bearing: _bearing,
                    ),
                    mapType: _mapType,
                    markers: markers,
                    polylines: polylines,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    buildingsEnabled: true,
                    trafficEnabled: false,
                  ),
                ),
                if (showFixedSidePanel)
                  SizedBox(
                    width: 360,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B24),
                        border: Border(
                          left: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: _buildSidePanel(colorScheme),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSidePanel(ColorScheme colorScheme, {bool isDrawer = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Control Panel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Bus-line colors, route controls, and live stop navigation.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 14),
          _stepHeader('1. Map Type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _mapTypeButton('Normal', MapType.normal, colorScheme),
              _mapTypeButton('Satellite', MapType.satellite, colorScheme),
              _mapTypeButton('Hybrid', MapType.hybrid, colorScheme),
              _mapTypeButton('Terrain', MapType.terrain, colorScheme),
            ],
          ),
          const Divider(height: 20),
          _stepHeader('2. Route Information'),
          if (selectedRoute != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distance: ${selectedRoute!.distance.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  'Duration: ${selectedRoute!.estimatedMinutes} mins',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  'Fare: ₹${selectedRoute!.fare}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: colorScheme.primary),
                ),
                Text(
                  'Operator: ${selectedRoute!.operator}',
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Type: ${selectedRoute!.busType}',
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          const Divider(height: 20),
          _stepHeader('3. 3D Camera Controls'),
          _sliderRow(
            label: 'Tilt',
            unit: '°',
            value: _tilt,
            min: 0,
            max: 60,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() => _tilt = value);
              _updateCamera();
            },
          ),
          const SizedBox(height: 8),
          _sliderRow(
            label: 'Bearing',
            unit: '°',
            value: _bearing,
            min: 0,
            max: 360,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() => _bearing = value);
              _updateCamera();
            },
          ),
          const SizedBox(height: 8),
          _sliderRow(
            label: 'Zoom',
            value: _zoom,
            min: 8,
            max: 20,
            colorScheme: colorScheme,
            decimals: 1,
            onChanged: (value) {
              setState(() => _zoom = value);
              _updateCamera();
            },
          ),
          const Divider(height: 20),
          _stepHeader('4. Route Stops'),
          if (selectedRoute != null)
            ...List.generate(selectedRoute!.stops.length, (index) {
              final stop = selectedRoute!.stops[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.18),
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                ),
                title: Text(
                  stop.stopName,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                subtitle: Text(
                  'ETA: ${stop.arrivalMinutes} min',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 10),
                ),
                onTap: () {
                  if (mapController == null) return;
                  mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(stop.latitude, stop.longitude),
                    ),
                  );
                  if (isDrawer) Navigator.of(context).maybePop();
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _stepHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    String unit = '',
    required double value,
    required double min,
    required double max,
    required ColorScheme colorScheme,
    required ValueChanged<double> onChanged,
    int decimals = 0,
  }) {
    final displayValue = value.toStringAsFixed(decimals);
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            '$label: $displayValue$unit',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.primary.withValues(alpha: 0.2),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _mapTypeButton(String label, MapType type, ColorScheme colorScheme) {
    final isSelected = _mapType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _mapType = type),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.2)
                : const Color(0xFF1A232D),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? colorScheme.primary : Colors.grey[400],
                  fontSize: 11,
                ),
          ),
        ),
      ),
    );
  }
}
