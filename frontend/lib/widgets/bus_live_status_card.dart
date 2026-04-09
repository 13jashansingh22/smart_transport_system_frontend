import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/eta_service.dart';

class BusLiveStatusCard extends StatefulWidget {
  const BusLiveStatusCard({
    super.key,
    this.busDocumentId = 'bus101',
    this.distanceKm,
    this.delayMinutes = 0,
  });

  final String busDocumentId;
  final double? distanceKm;
  final int delayMinutes;

  @override
  State<BusLiveStatusCard> createState() => _BusLiveStatusCardState();
}

class _BusLiveStatusCardState extends State<BusLiveStatusCard> {
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      // Recalculate status every second even without new Firestore writes.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('buses')
        .doc(widget.busDocumentId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Failed to load live bus updates. ${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        final document = snapshot.data;
        if (document == null || !document.exists) {
          return _ErrorState(
            message:
                'Live data is not available for ${widget.busDocumentId} yet.',
          );
        }

        final data = document.data();
        if (data == null) {
          return const _ErrorState(
            message: 'Live document exists but has no readable fields.',
          );
        }

        final latitude = _readDouble(data['latitude']);
        final longitude = _readDouble(data['longitude']);
        final speedMps = _readDouble(data['speed']);
        final timestamp = _readTimestamp(data['timestamp']);
        final lastUpdate = timestamp?.toDate();

        final speedKmh = speedMps != null ? speedMps * 3.6 : null;
        final etaMinutes = (speedMps != null && widget.distanceKm != null)
            ? EtaService.calculateEtaMinutes(
                distanceKm: widget.distanceKm!,
                speedMps: speedMps,
                delayMinutes: widget.delayMinutes,
              )
            : null;

        final status =
            lastUpdate != null ? getBusStatus(lastUpdate) : 'OFFLINE';
        final lastUpdatedLabel = lastUpdate != null
            ? 'Last updated: ${_elapsedSeconds(lastUpdate)} seconds ago'
            : 'Last updated: N/A';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_bus_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live Bus Status (${widget.busDocumentId})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _statusChip(context, status),
                  ],
                ),
                const SizedBox(height: 12),
                _dataRow(
                  context,
                  label: 'Latitude',
                  value: latitude?.toStringAsFixed(6) ?? 'N/A',
                ),
                _dataRow(
                  context,
                  label: 'Longitude',
                  value: longitude?.toStringAsFixed(6) ?? 'N/A',
                ),
                _dataRow(
                  context,
                  label: 'Speed',
                  value: speedKmh != null
                      ? '${speedKmh.toStringAsFixed(2)} km/h'
                      : 'N/A',
                ),
                _dataRow(
                  context,
                  label: 'ETA',
                  value: etaMinutes != null
                      ? '$etaMinutes min'
                      : 'N/A (set distanceKm)',
                ),
                _dataRow(
                  context,
                  label: 'Status',
                  value: status,
                ),
                _dataRow(
                  context,
                  label: 'Last Updated',
                  value: lastUpdatedLabel,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _dataRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  static Widget _statusChip(BuildContext context, String status) {
    final normalized = status.trim().toLowerCase();

    Color color;
    switch (normalized) {
      case 'online':
        color = Colors.green;
        break;
      case 'delayed':
        color = Colors.orange;
        break;
      case 'offline':
        color = Colors.red;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  static String getBusStatus(DateTime lastUpdate) {
    final ageSeconds = DateTime.now().difference(lastUpdate).inSeconds;

    if (ageSeconds > 20) {
      return 'OFFLINE';
    }
    if (ageSeconds > 10) {
      return 'DELAYED';
    }
    return 'ONLINE';
  }

  static double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static Timestamp? _readTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value;
    }
    return null;
  }

  static int _elapsedSeconds(DateTime lastUpdate) {
    final seconds = DateTime.now().difference(lastUpdate).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Loading live bus data...')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
