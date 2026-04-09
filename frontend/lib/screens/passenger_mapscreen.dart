import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bus_route.dart';
import '../models/bus_routes_repository.dart';
import '../services/live_bus_simulator_service.dart';
import '../services/local_bus_alert_notification_service.dart';
import '../services/location_service.dart';
import '../widgets/branded_app_bar_title.dart';
import 'passenger/track_bus_screen.dart';

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  static const String _mapStylePreferenceKey = 'passenger_map_dark_style';
  static const LatLng _fallbackLocation = LatLng(30.7333, 76.7794);
  static const String _lightTileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const String _darkTileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const List<String> _tileSubdomains = ['a', 'b', 'c', 'd'];

  static const Map<String, LatLng> _searchLocations = {
    'Sector 17 Plaza': LatLng(30.7398, 76.7834),
    'ISBT Sector 43': LatLng(30.7190, 76.7579),
    'PGIMER': LatLng(30.7649, 76.7756),
    'Elante Mall': LatLng(30.7049, 76.8013),
    'IT Park': LatLng(30.7289, 76.8387),
  };

  final fmap.MapController _fallbackController = fmap.MapController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _panelController = PageController();
  final Distance _distance = const Distance();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _busesSubscription;
  List<SimulatedBusSnapshot> _liveFirestoreBuses =
      const <SimulatedBusSnapshot>[];

  gmaps.GoogleMapController? _googleController;

  bool _isLoading = true;
  bool _useFallbackMap = false;
  bool _useDarkMap = false;
  bool _googleReady = false;
  gmaps.MapType _googleMapType = gmaps.MapType.normal;

  LatLng _currentLocation = _fallbackLocation;
  LatLng _searchedLocation = _fallbackLocation;

  List<NearbyBusEntry> _nearbyBuses = const <NearbyBusEntry>[];
  List<BusRoute> _suggestedRoutes = const <BusRoute>[];
  List<_NearbyStopEntry> _nearbyStops = const <_NearbyStopEntry>[];

  SimulatedBusSnapshot? _selectedBus;
  int _currentPanel = 0;

  static const List<String> _panelTitles = [
    'Nearest buses',
    'Suggested routes',
    'Nearby stops',
    'Route sequence',
  ];

  bool get _supportsGoogleMaps {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  BusRoute? get _selectedRoute {
    final selected = _selectedBus;
    if (selected == null) return null;
    return BusRoutesRepository.getRouteById(selected.routeId);
  }

  String get _fallbackTileUrl {
    return _useDarkMap ? _darkTileUrlTemplate : _lightTileUrlTemplate;
  }

  @override
  void initState() {
    super.initState();
    _useFallbackMap = !_supportsGoogleMaps;
    _subscribeToFirestoreBuses();
    _initialize();
  }

  Future<void> _initialize() async {
    _searchController.text = 'Sector 17 Plaza';
    _searchedLocation = _fallbackLocation;
    _refreshNearbyBuses();

    _loadMapStylePreference();
    _loadCurrentLocation().then((_) {
      if (!mounted) return;
      setState(() {});
      _moveToLocation(_currentLocation);
    });

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadMapStylePreference() async {
    final pref = await SharedPreferences.getInstance();
    final isDark = pref.getBool(_mapStylePreferenceKey) ?? false;
    if (!mounted) {
      _useDarkMap = isDark;
      return;
    }
    setState(() => _useDarkMap = isDark);
  }

  Future<void> _saveMapStylePreference() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(_mapStylePreferenceKey, _useDarkMap);
  }

  Future<void> _loadCurrentLocation() async {
    final location = await LocationService.getCurrentCoordinates(
      fallbackLatitude: _fallbackLocation.latitude,
      fallbackLongitude: _fallbackLocation.longitude,
    );
    _currentLocation = LatLng(location.latitude, location.longitude);
  }

  void _subscribeToFirestoreBuses() {
    _busesSubscription =
        _firestore.collection('buses').snapshots().listen((snapshot) {
      final parsed = <SimulatedBusSnapshot>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final latitude = _readDouble(data['latitude']);
        final longitude = _readDouble(data['longitude']);

        if (latitude == null || longitude == null) {
          continue;
        }

        final routeId = _readString(data['routeId']) ?? '';
        final fallbackRoute = BusRoutesRepository.allRoutes.first;
        final route = routeId.isNotEmpty
            ? BusRoutesRepository.getRouteById(routeId)
            : null;

        final resolvedRoute = route ?? fallbackRoute;
        final routeNumber =
            _readString(data['routeNumber']) ?? resolvedRoute.routeNumber;
        final routeName =
            _readString(data['routeName']) ?? 'Live Bus ${doc.id}';
        final speedMps = _readDouble(data['speed']) ?? 0;
        final etaToNextStopMinutes = speedMps <= 0 ? 0 : 1;

        debugPrint(
          '[PassengerMap] Bus ${doc.id} -> lat=$latitude, lon=$longitude',
        );

        parsed.add(
          SimulatedBusSnapshot(
            busId: doc.id,
            routeId: resolvedRoute.id,
            routeNumber: routeNumber,
            routeName: routeName,
            latitude: latitude,
            longitude: longitude,
            currentStopIndex: 0,
            nextStopIndex: 0,
            currentStopName: 'Live Position',
            nextStopName: 'Updating',
            etaToNextStopMinutes: etaToNextStopMinutes,
            occupancyPercent: 0,
          ),
        );
      }

      debugPrint('[PassengerMap] Firestore buses fetched: ${parsed.length}');

      if (!mounted) {
        _liveFirestoreBuses = parsed;
        return;
      }

      setState(() {
        _liveFirestoreBuses = parsed;
      });
      _refreshNearbyBuses();
    }, onError: (Object error) {
      debugPrint('[PassengerMap] Firestore buses stream error: $error');
    });
  }

  void _refreshNearbyBuses() {
    // Demo mode: show all Firestore buses without distance-based filtering.
    final nearby = _liveFirestoreBuses
        .map(
          (snapshot) => NearbyBusEntry(
            snapshot: snapshot,
            distanceKm: _distance.as(
              LengthUnit.Kilometer,
              _currentLocation,
              LatLng(snapshot.latitude, snapshot.longitude),
            ),
          ),
        )
        .toList(growable: false);

    debugPrint('[PassengerMap] Buses used for map rendering: ${nearby.length}');

    nearby.sort(
      (a, b) =>
          a.snapshot.etaToNextStopMinutes == b.snapshot.etaToNextStopMinutes
              ? a.distanceKm.compareTo(b.distanceKm)
              : a.snapshot.etaToNextStopMinutes
                  .compareTo(b.snapshot.etaToNextStopMinutes),
    );

    if (!mounted) {
      _nearbyBuses = nearby;
      _suggestedRoutes = _buildSuggestedRoutes(nearby);
      _nearbyStops = _buildNearbyStops(_searchedLocation);
      return;
    }

    setState(() {
      _nearbyBuses = nearby;
      _suggestedRoutes = _buildSuggestedRoutes(nearby);
      _nearbyStops = _buildNearbyStops(_searchedLocation);
      if (_selectedBus != null) {
        final stillExists =
            nearby.any((e) => e.snapshot.busId == _selectedBus!.busId);
        _selectedBus = stillExists ? _selectedBus : null;
      }
      _selectedBus ??= nearby.isNotEmpty ? nearby.first.snapshot : null;
    });

    if (_useFallbackMap && nearby.isNotEmpty) {
      final firstBus = nearby.first.snapshot;
      _fallbackController.move(
        LatLng(firstBus.latitude, firstBus.longitude),
        14.2,
      );
    }

    for (final entry in nearby) {
      unawaited(
        LocalBusAlertNotificationService.instance.maybeNotifyBusApproaching(
          busId: entry.snapshot.busId,
          distanceKm: entry.distanceKm,
          etaMinutes: entry.snapshot.etaToNextStopMinutes,
        ),
      );
    }
  }

  List<BusRoute> _buildSuggestedRoutes(List<NearbyBusEntry> nearby) {
    final seen = <String>{};
    final routes = <BusRoute>[];

    for (final entry in nearby) {
      if (!seen.add(entry.snapshot.routeId)) continue;
      final route = BusRoutesRepository.getRouteById(entry.snapshot.routeId);
      if (route != null) routes.add(route);
      if (routes.length >= 3) break;
    }

    return routes;
  }

  List<_NearbyStopEntry> _buildNearbyStops(LatLng origin) {
    final stops = <_NearbyStopEntry>[];

    for (final route in BusRoutesRepository.allRoutes) {
      for (final stop in route.stops) {
        final km = _distance.as(
          LengthUnit.Kilometer,
          origin,
          LatLng(stop.latitude, stop.longitude),
        );
        stops.add(
          _NearbyStopEntry(
            routeNumber: route.routeNumber,
            stopName: stop.stopName,
            distanceKm: km,
          ),
        );
      }
    }

    stops.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return stops.take(5).toList(growable: false);
  }

  void _moveToLocation(LatLng target, {double zoom = 13.8}) {
    if (!_useFallbackMap && _supportsGoogleMaps && _googleReady) {
      _googleController?.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: gmaps.LatLng(target.latitude, target.longitude),
            zoom: zoom,
          ),
        ),
      );
      return;
    }

    _fallbackController.move(target, zoom);
  }

  void _applySearch(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) {
      _searchController.text = 'Sector 17 Plaza';
      _searchedLocation = _fallbackLocation;
      _refreshNearbyBuses();
      _moveToLocation(_searchedLocation);
      return;
    }

    MapEntry<String, LatLng>? matched;
    for (final entry in _searchLocations.entries) {
      if (entry.key.toLowerCase().contains(value)) {
        matched = entry;
        break;
      }
    }

    if (matched == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Search demo points like Sector 17, PGIMER, Elante, IT Park, ISBT 43.'),
        ),
      );
      return;
    }

    _searchController.text = matched.key;
    _searchedLocation = matched.value;
    _refreshNearbyBuses();
    _moveToLocation(_searchedLocation, zoom: 13.9);
  }

  Set<gmaps.Marker> _googleMarkers() {
    final markers = <gmaps.Marker>{
      gmaps.Marker(
        markerId: const gmaps.MarkerId('searched_location'),
        position: gmaps.LatLng(
            _searchedLocation.latitude, _searchedLocation.longitude),
        infoWindow: const gmaps.InfoWindow(title: 'Search location'),
      ),
    };

    for (final entry in _nearbyBuses) {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(entry.snapshot.busId),
          position:
              gmaps.LatLng(entry.snapshot.latitude, entry.snapshot.longitude),
          infoWindow: gmaps.InfoWindow(
            title: entry.snapshot.routeNumber,
            snippet:
                '${entry.snapshot.currentStopName} → ${entry.snapshot.nextStopName} • ETA ${entry.snapshot.etaToNextStopMinutes} min',
          ),
          icon: _selectedBus?.busId == entry.snapshot.busId
              ? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  gmaps.BitmapDescriptor.hueRose)
              : gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  gmaps.BitmapDescriptor.hueOrange),
          onTap: () => setState(() => _selectedBus = entry.snapshot),
        ),
      );
    }

    final route = _selectedRoute;
    if (route != null) {
      for (final stop in route.stops) {
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('stop_${route.id}_${stop.sequenceNumber}'),
            position: gmaps.LatLng(stop.latitude, stop.longitude),
            infoWindow: gmaps.InfoWindow(title: stop.stopName),
          ),
        );
      }
    }

    return markers;
  }

  Set<gmaps.Polyline> _googlePolylines() {
    final route = _selectedRoute;
    if (route == null) return const <gmaps.Polyline>{};

    return {
      gmaps.Polyline(
        polylineId: gmaps.PolylineId('route_${route.id}'),
        width: 5,
        color: const Color(0xFF22C55E),
        points: route.stops
            .map((stop) => gmaps.LatLng(stop.latitude, stop.longitude))
            .toList(growable: false),
      ),
    };
  }

  Widget _buildMap() {
    if (_useFallbackMap) {
      return fmap.FlutterMap(
        mapController: _fallbackController,
        options:
            fmap.MapOptions(initialCenter: _currentLocation, initialZoom: 13.8),
        children: [
          fmap.TileLayer(
            urlTemplate: _fallbackTileUrl,
            subdomains: _tileSubdomains,
            userAgentPackageName: 'bus_tracking_system',
          ),
          fmap.MarkerLayer(
            markers: [
              fmap.Marker(
                point: _searchedLocation,
                width: 50,
                height: 50,
                child: const Icon(Icons.search_rounded,
                    color: Color(0xFF7DD3FC), size: 30),
              ),
              ..._nearbyBuses.map(
                (entry) => fmap.Marker(
                  point:
                      LatLng(entry.snapshot.latitude, entry.snapshot.longitude),
                  width: 46,
                  height: 46,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBus = entry.snapshot),
                    child: const Icon(Icons.directions_bus_rounded,
                        color: Color(0xFFF97316), size: 30),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedRoute != null)
            fmap.PolylineLayer(
              polylines: [
                fmap.Polyline(
                  points: _selectedRoute!.stops
                      .map((stop) => LatLng(stop.latitude, stop.longitude))
                      .toList(growable: false),
                  strokeWidth: 5,
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),
        ],
      );
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target:
            gmaps.LatLng(_currentLocation.latitude, _currentLocation.longitude),
        zoom: 13.8,
      ),
      mapType: _googleMapType,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: _googleMarkers(),
      polylines: _googlePolylines(),
      onMapCreated: (controller) {
        _googleController = controller;
        if (!mounted) return;
        setState(() => _googleReady = true);
      },
    );
  }

  Widget _routeSequence() {
    final bus = _selectedBus;
    if (bus == null) {
      return const Text('Select a moving bus to view route sequence.');
    }

    final route = BusRoutesRepository.getRouteById(bus.routeId);
    if (route == null || route.stops.isEmpty) {
      return Text('No stop sequence available for ${bus.routeNumber}.');
    }

    return Column(
      children: route.stops.map((stop) {
        final isCurrent = stop.sequenceNumber == bus.currentStopIndex;
        final isNext = stop.sequenceNumber == bus.nextStopIndex;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isNext
                ? const Color(0x3322C55E)
                : (isCurrent
                    ? const Color(0x3338BDF8)
                    : const Color(0x2218232D)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                  radius: 10, child: Text('${stop.sequenceNumber + 1}')),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(stop.stopName,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('+${stop.arrivalMinutes}m'),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _panelShell(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(child: child),
          ),
        ],
      ),
    );
  }

  Widget _liveBusesPanel(BuildContext context) {
    if (_nearbyBuses.isEmpty) {
      return const Text('No live buses found in Firestore yet.',
          style: TextStyle(color: Colors.white70));
    }

    return Column(
      children: _nearbyBuses.take(6).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.snapshot.routeName,
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${entry.distanceKm.toStringAsFixed(1)} km • ETA ${entry.snapshot.etaToNextStopMinutes} min',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TrackBusScreen(routeId: entry.snapshot.routeId),
                ),
              );
            },
          ),
          onTap: () => setState(() => _selectedBus = entry.snapshot),
        );
      }).toList(growable: false),
    );
  }

  Widget _routesPanel() {
    if (_suggestedRoutes.isEmpty) {
      return const Text('No suggested routes yet.',
          style: TextStyle(color: Colors.white70));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestedRoutes
          .map(
            (route) => ActionChip(
              label: Text(
                '${route.routeNumber} • ${route.source} → ${route.destination}',
              ),
              onPressed: () {
                final matches = _nearbyBuses
                    .where((e) => e.snapshot.routeId == route.id)
                    .toList(growable: false);
                if (matches.isNotEmpty) {
                  setState(() => _selectedBus = matches.first.snapshot);
                }
              },
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _stopsPanel() {
    if (_nearbyStops.isEmpty) {
      return const Text('Nearby stop data unavailable.',
          style: TextStyle(color: Colors.white70));
    }

    return Column(
      children: _nearbyStops
          .map(
            (stop) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${stop.stopName} (${stop.routeNumber})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    '${stop.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _goToPanel(int index) async {
    if (!_panelController.hasClients) return;
    await _panelController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _busesSubscription?.cancel();
    _searchController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Chandigarh Live Bus Map'),
        actions: [
          IconButton(
            icon: Icon(_useFallbackMap ? Icons.layers : Icons.public),
            tooltip: _useFallbackMap
                ? 'Switch to Google map'
                : 'Switch to fallback map',
            onPressed: () {
              if (_useFallbackMap && !_supportsGoogleMaps) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Google Maps not supported on this platform.')),
                );
                return;
              }
              setState(() => _useFallbackMap = !_useFallbackMap);
              _moveToLocation(_searchedLocation);
            },
          ),
          IconButton(
            icon: Icon(_useDarkMap ? Icons.dark_mode : Icons.light_mode),
            tooltip: _useDarkMap ? 'Use light map' : 'Use dark map',
            onPressed: () {
              setState(() => _useDarkMap = !_useDarkMap);
              _saveMapStylePreference();
            },
          ),
          PopupMenuButton<gmaps.MapType>(
            icon: const Icon(Icons.satellite_alt_rounded),
            enabled: !_useFallbackMap,
            initialValue: _googleMapType,
            onSelected: (value) => setState(() => _googleMapType = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: gmaps.MapType.normal, child: Text('Normal')),
              PopupMenuItem(
                  value: gmaps.MapType.satellite, child: Text('Satellite')),
              PopupMenuItem(value: gmaps.MapType.hybrid, child: Text('Hybrid')),
              PopupMenuItem(
                  value: gmaps.MapType.terrain, child: Text('Terrain')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Stack(
              children: [
                Positioned.fill(child: _buildMap()),
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _applySearch,
                            decoration: InputDecoration(
                              hintText: 'Search Chandigarh points',
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    _applySearch(_searchController.text),
                                icon: const Icon(Icons.search_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _searchLocations.keys.map((label) {
                              return ActionChip(
                                label: Text(label),
                                onPressed: () {
                                  _searchController.text = label;
                                  _applySearch(label);
                                },
                              );
                            }).toList(growable: false),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Live Firestore stream: buses collection updates in real-time',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xEE0F1720),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(26)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: SizedBox(
                      height: 278,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panels in sequence (1 → 4)',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  List.generate(_panelTitles.length, (index) {
                                final selected = _currentPanel == index;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    selected: selected,
                                    label: Text(
                                        '${index + 1}. ${_panelTitles[index]}'),
                                    onSelected: (_) => _goToPanel(index),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: PageView(
                              controller: _panelController,
                              onPageChanged: (index) {
                                if (!mounted) return;
                                setState(() => _currentPanel = index);
                              },
                              children: [
                                _panelShell(
                                  context,
                                  title: '1. Nearest moving buses',
                                  subtitle:
                                      'Tap any bus to select it on map and open detailed tracking.',
                                  child: _liveBusesPanel(context),
                                ),
                                _panelShell(
                                  context,
                                  title: '2. Suggested routes',
                                  subtitle:
                                      'Choose a route chip to focus buses from that route.',
                                  child: _routesPanel(),
                                ),
                                _panelShell(
                                  context,
                                  title: '3. Nearby stops',
                                  subtitle:
                                      'Understand nearest boarding points with route and distance.',
                                  child: _stopsPanel(),
                                ),
                                _panelShell(
                                  context,
                                  title: '4. Selected route sequence',
                                  subtitle:
                                      'Current and next stop highlighting for easy trip understanding.',
                                  child: _routeSequence(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _currentPanel == 0
                                      ? null
                                      : () => _goToPanel(_currentPanel - 1),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Previous'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _currentPanel == _panelTitles.length - 1
                                          ? null
                                          : () => _goToPanel(_currentPanel + 1),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Next'),
                                ),
                              ),
                            ],
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

double? _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

String? _readString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

class _NearbyStopEntry {
  final String routeNumber;
  final String stopName;
  final double distanceKm;

  const _NearbyStopEntry({
    required this.routeNumber,
    required this.stopName,
    required this.distanceKm,
  });
}
