import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class BusLocationSyncException implements Exception {
  final String message;

  const BusLocationSyncException(this.message);

  @override
  String toString() => message;
}

class FirestoreBusLocationService {
  FirestoreBusLocationService._();

  static final FirestoreBusLocationService instance =
      FirestoreBusLocationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _timer;
  bool _isSending = false;
  String? _lastWriteSignature;

  bool get isRunning => _timer != null;

  Future<bool> updateBusLocation({
    required double latitude,
    required double longitude,
    required double speed,
    String busDocumentId = 'bus_1',
  }) async {
    if (latitude == 0 || longitude == 0) {
      debugPrint(
        'Skipping bus location update for $busDocumentId because coordinates are invalid: '
        'latitude=$latitude, longitude=$longitude',
      );
      return false;
    }

    final sanitizedSpeed = speed < 0 ? 0.0 : speed;
    final writeSignature = _buildWriteSignature(
      latitude: latitude,
      longitude: longitude,
      speed: sanitizedSpeed,
    );

    if (_lastWriteSignature == writeSignature) {
      return false;
    }

    try {
      await _firestore.collection('buses').doc(busDocumentId).set({
        'latitude': latitude,
        'longitude': longitude,
        'speed': sanitizedSpeed,
        'status': 'online',
        'lastUpdatedMillis': DateTime.now().millisecondsSinceEpoch,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _lastWriteSignature = writeSignature;
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Firestore update failed for buses/$busDocumentId '
        '[code=${error.code}]: ${error.message ?? 'Unknown Firebase error'}',
      );
      Error.throwWithStackTrace(
        BusLocationSyncException(
          'Firestore update failed (${error.code}): ${error.message ?? 'Unknown Firebase error'}',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Unexpected error while updating buses/$busDocumentId: $error',
      );
      Error.throwWithStackTrace(
        BusLocationSyncException('Unexpected location sync error: $error'),
        stackTrace,
      );
    }
  }

  void startPeriodicUpdates({
    Duration interval = const Duration(seconds: 5),
    String busDocumentId = 'bus_1',
    void Function(double latitude, double longitude, double speed)?
        onLocationUpdated,
    void Function(Object error)? onError,
  }) {
    if (_timer != null) {
      return;
    }

    Future<void> syncOnce() async {
      if (_isSending) {
        return;
      }

      _isSending = true;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );

        final speed = math.max(0, position.speed).toDouble();

        final didWrite = await updateBusLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          speed: speed,
          busDocumentId: busDocumentId,
        );

        if (didWrite) {
          onLocationUpdated?.call(position.latitude, position.longitude, speed);
        }
      } on FirebaseException catch (error) {
        final message =
            'Firebase sync error [${error.code}] for buses/$busDocumentId: '
            '${error.message ?? 'Unknown Firebase error'}';
        debugPrint(message);
        onError?.call(BusLocationSyncException(message));
      } catch (error) {
        debugPrint('Bus location sync failed: $error');
        onError?.call(error);
      } finally {
        _isSending = false;
      }
    }

    unawaited(syncOnce());
    _timer = Timer.periodic(interval, (_) => unawaited(syncOnce()));
  }

  void stopPeriodicUpdates() {
    _timer?.cancel();
    _timer = null;
  }

  String _buildWriteSignature({
    required double latitude,
    required double longitude,
    required double speed,
  }) {
    final latPart = latitude.toStringAsFixed(6);
    final lonPart = longitude.toStringAsFixed(6);
    final speedPart = speed.toStringAsFixed(2);
    return '$latPart|$lonPart|$speedPart';
  }
}
