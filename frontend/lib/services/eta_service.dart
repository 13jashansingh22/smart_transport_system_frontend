class EtaService {
  const EtaService._();

  /// Calculates ETA in minutes from distance (km) and speed (m/s).
  ///
  /// Returns a rounded, non-negative minute value.
  /// If speed is zero/invalid, returns only the delay component.
  static int calculateEtaMinutes({
    required double distanceKm,
    required double speedMps,
    int delayMinutes = 0,
  }) {
    final safeDelay = delayMinutes < 0 ? 0 : delayMinutes;
    if (distanceKm <= 0) {
      return safeDelay;
    }

    // Convert m/s to km/h.
    final speedKmh = speedMps * 3.6;

    // Avoid division by zero and unstable tiny speeds.
    if (speedKmh <= 0) {
      return safeDelay;
    }

    final travelMinutes = (distanceKm / speedKmh) * 60;
    final eta = travelMinutes + safeDelay;

    return eta.isFinite ? eta.round().clamp(0, 1 << 30) : safeDelay;
  }
}
