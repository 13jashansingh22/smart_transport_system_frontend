import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../models/bus_route.dart';
import '../models/bus_routes_repository.dart';

class SimulatedBusSnapshot {
  final String busId;
  final String routeId;
  final String routeNumber;
  final String routeName;
  final double latitude;
  final double longitude;
  final int currentStopIndex;
  final int nextStopIndex;
  final String currentStopName;
  final String nextStopName;
  final int etaToNextStopMinutes;
  final int occupancyPercent;

  const SimulatedBusSnapshot({
    required this.busId,
    required this.routeId,
    required this.routeNumber,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.currentStopIndex,
    required this.nextStopIndex,
    required this.currentStopName,
    required this.nextStopName,
    required this.etaToNextStopMinutes,
    required this.occupancyPercent,
  });
}

class NearbyBusEntry {
  final SimulatedBusSnapshot snapshot;
  final double distanceKm;

  const NearbyBusEntry({required this.snapshot, required this.distanceKm});
}

class _SimBusState {
  final BusRoute route;
  int currentIndex;
  int direction;
  int occupancy;

  _SimBusState({
    required this.route,
    required this.currentIndex,
    required this.direction,
    required this.occupancy,
  });
}

class LiveBusSimulatorService {
  LiveBusSimulatorService._();

  static final LiveBusSimulatorService instance = LiveBusSimulatorService._();

  final ValueNotifier<List<SimulatedBusSnapshot>> liveBuses =
      ValueNotifier<List<SimulatedBusSnapshot>>(<SimulatedBusSnapshot>[]);

  final latlng.Distance _distance = const latlng.Distance();
  final List<_SimBusState> _states = <_SimBusState>[];
  final math.Random _random = math.Random();
  Timer? _timer;
  Duration _tickDuration = const Duration(seconds: 6);
  bool _fastForTesting = false;

  void start({bool fastForTesting = false}) {
    final requestedTick = fastForTesting
        ? const Duration(seconds: 2)
        : const Duration(seconds: 6);

    if (_timer != null &&
        _tickDuration == requestedTick &&
        _fastForTesting == fastForTesting) {
      return;
    }

    _timer?.cancel();
    _tickDuration = requestedTick;
    _fastForTesting = fastForTesting;

    _seedIfNeeded();
    _publishSnapshots();
    _timer = Timer.periodic(_tickDuration, (_) {
      _tick();
      _publishSnapshots();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  List<SimulatedBusSnapshot> busesForRoute(String routeId) {
    return liveBuses.value
        .where((snapshot) => snapshot.routeId == routeId)
        .toList(growable: false);
  }

  List<NearbyBusEntry> nearbyBuses({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 8,
  }) {
    final origin = latlng.LatLng(latitude, longitude);
    final nearby = <NearbyBusEntry>[];

    for (final snapshot in liveBuses.value) {
      final distanceKm = _distance.as(
        latlng.LengthUnit.Kilometer,
        origin,
        latlng.LatLng(snapshot.latitude, snapshot.longitude),
      );
      if (distanceKm <= radiusKm) {
        nearby.add(NearbyBusEntry(snapshot: snapshot, distanceKm: distanceKm));
      }
    }

    nearby.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return nearby.take(limit).toList(growable: false);
  }

  void _seedIfNeeded() {
    if (_states.isNotEmpty) {
      return;
    }

    for (final route in BusRoutesRepository.allRoutes.take(18)) {
      if (route.stops.length < 2) {
        continue;
      }
      _states.add(
        _SimBusState(
          route: route,
          currentIndex: _random.nextInt(route.stops.length - 1),
          direction: _random.nextBool() ? 1 : -1,
          occupancy: 30 + _random.nextInt(65),
        ),
      );
    }
  }

  void _tick() {
    for (final state in _states) {
      final hops = _fastForTesting ? 2 : 1;

      for (var hop = 0; hop < hops; hop++) {
        var nextIndex = state.currentIndex + state.direction;
        if (nextIndex >= state.route.stops.length) {
          state.direction = -1;
          nextIndex = state.route.stops.length - 2;
        }
        if (nextIndex < 0) {
          state.direction = 1;
          nextIndex = 1;
        }
        state.currentIndex = nextIndex;
      }

      final occupancyDelta = _random.nextInt(9) - 4;
      state.occupancy = (state.occupancy + occupancyDelta).clamp(10, 98);
    }
  }

  void _publishSnapshots() {
    final snapshots = <SimulatedBusSnapshot>[];

    for (var i = 0; i < _states.length; i++) {
      final state = _states[i];
      final currentStop = state.route.stops[state.currentIndex];
      final nextIndex = (state.currentIndex + state.direction)
          .clamp(0, state.route.stops.length - 1);
      final nextStop = state.route.stops[nextIndex];

      snapshots.add(
        SimulatedBusSnapshot(
          busId: 'sim_${state.route.id}_$i',
          routeId: state.route.id,
          routeNumber: state.route.routeNumber,
          routeName: state.route.name,
          latitude: currentStop.latitude,
          longitude: currentStop.longitude,
          currentStopIndex: currentStop.sequenceNumber,
          nextStopIndex: nextStop.sequenceNumber,
          currentStopName: currentStop.stopName,
          nextStopName: nextStop.stopName,
          etaToNextStopMinutes: _fastForTesting
              ? math.max(
                  1,
                  ((nextStop.arrivalMinutes - currentStop.arrivalMinutes) / 2)
                      .round(),
                )
              : math.max(
                  2,
                  nextStop.arrivalMinutes - currentStop.arrivalMinutes,
                ),
          occupancyPercent: state.occupancy,
        ),
      );
    }

    liveBuses.value = snapshots;
  }
}
