import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/bus_routes_repository.dart';
import '../services/smart_transport_ai_service.dart';
import '../services/user_profile_context_service.dart';
import '../widgets/branded_app_bar_title.dart';

class PassengerScreen extends StatelessWidget {
  const PassengerScreen({super.key});

  Widget _profileContextCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<UserProfileContext?>(
      future: UserProfileContextService.read(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: ListTile(
            leading: Icon(Icons.location_city, color: colorScheme.primary),
            title: Text('${profile.town}, ${profile.city}'),
            subtitle: Text('State: ${profile.state} • Role: ${profile.role}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Profile',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colorScheme.primary),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerSos(BuildContext context) async {
    final service = SmartTransportAIService.instance;
    final selected = BusRoutesRepository.allRoutes.first;

    double latitude = 28.6139;
    double longitude = 77.2090;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (_) {}

    final payload = service.createEmergencyPayload(
      role: 'passenger',
      busId: selected.id,
      latitude: latitude,
      longitude: longitude,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SOS sent (${payload['status']}) • Bus ${payload['busId']}',
          ),
        ),
      );
    }
  }

  Widget _navTile(
      BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _quickCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required String route,
      required Color accentColor}) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Open',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: accentColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricChip(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      required Color accentColor}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.labelMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoSlideCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required List<Widget> chips,
  }) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.18),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: chips),
        ],
      ),
    );
  }

  Future<void> _quickCall(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri);
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling not supported on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalRoutes = BusRoutesRepository.allRoutes.length;

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Passenger Command Center'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/chatbot'),
            icon: const Icon(Icons.smart_toy),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(
                leading: SizedBox(
                  width: 34,
                  height: 34,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                title: const Text('Passenger Navigation'),
                subtitle: const Text('Features arranged in sequence'),
              ),
              const Divider(),
              _navTile(context, Icons.map_rounded, '1. City-wise Live Bus Map',
                  '/city-map'),
              _navTile(context, Icons.gps_fixed_rounded, '2. Live GPS Tracking',
                  '/trackbus'),
              _navTile(context, Icons.alt_route_rounded, '3. Routes & Stops',
                  '/routes'),
              _navTile(
                  context, Icons.schedule_rounded, '4. Schedule', '/schedule'),
              _navTile(context, Icons.qr_code_scanner_rounded,
                  '5. Smart Ticketing (QR)', '/tickets'),
              _navTile(context, Icons.event_seat_rounded,
                  '6. Seat Availability', '/tickets'),
              _navTile(context, Icons.notifications_active_rounded,
                  '7. Real-Time Alerts', '/alerts'),
              _navTile(context, Icons.auto_awesome_rounded, '8. AI Features',
                  '/ai-features'),
              _navTile(context, Icons.record_voice_over_rounded,
                  '9. Voice & Offline Tools', '/ai-features'),
              _navTile(context, Icons.receipt_long_rounded, '10. My Tickets',
                  '/mytickets'),
              _navTile(
                  context, Icons.history_rounded, '11. History', '/history'),
              _navTile(
                  context, Icons.person_rounded, '12. Profile', '/profile'),
              _navTile(
                  context, Icons.help_outline_rounded, '13. Help', '/help'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _triggerSos(context),
        icon: const Icon(Icons.warning),
        label: const Text('SOS'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.06),
              colorScheme.surface,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            SizedBox(
              height: 206,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _infoSlideCard(
                    context,
                    icon: Icons.dashboard_customize_rounded,
                    title: 'Passenger Command Center',
                    subtitle:
                        'Swipe cards for quick transport intelligence overview.',
                    accentColor: colorScheme.primary,
                    chips: [
                      _metricChip(
                        context,
                        icon: Icons.alt_route,
                        label: 'Active routes',
                        value: '$totalRoutes',
                        accentColor: colorScheme.primary,
                      ),
                      _metricChip(
                        context,
                        icon: Icons.access_time_filled_rounded,
                        label: 'AI ETA',
                        value: 'Live',
                        accentColor: colorScheme.secondary,
                      ),
                    ],
                  ),
                  _infoSlideCard(
                    context,
                    icon: Icons.location_searching_rounded,
                    title: 'Live Map Coverage',
                    subtitle:
                        'Track moving buses by city and open route sequence instantly.',
                    accentColor: colorScheme.secondary,
                    chips: [
                      _metricChip(
                        context,
                        icon: Icons.map_rounded,
                        label: 'Map mode',
                        value: 'Fast',
                        accentColor: colorScheme.secondary,
                      ),
                      _metricChip(
                        context,
                        icon: Icons.directions_bus_filled_rounded,
                        label: 'Demo buses',
                        value: 'Moving',
                        accentColor: colorScheme.tertiary,
                      ),
                    ],
                  ),
                  _infoSlideCard(
                    context,
                    icon: Icons.health_and_safety_rounded,
                    title: 'Safety & Alerts',
                    subtitle:
                        'Emergency support and real-time alerting remain one tap away.',
                    accentColor: colorScheme.tertiary,
                    chips: [
                      _metricChip(
                        context,
                        icon: Icons.notifications_active,
                        label: 'Alerts',
                        value: 'Real-time',
                        accentColor: colorScheme.tertiary,
                      ),
                      _metricChip(
                        context,
                        icon: Icons.warning_amber_rounded,
                        label: 'SOS',
                        value: 'Ready',
                        accentColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _profileContextCard(context),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Travel Preferences',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Keep the dashboard tailored to your language before you start tracking buses.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<String>(
                      valueListenable:
                          SmartTransportAIService.instance.selectedLanguage,
                      builder: (_, language, __) {
                        return DropdownButtonFormField<String>(
                          key: ValueKey(language),
                          initialValue: language,
                          decoration: const InputDecoration(
                            labelText: 'Multi-language Support',
                          ),
                          items: SmartTransportAIService.instance
                              .supportedLanguages()
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              SmartTransportAIService
                                  .instance.selectedLanguage.value = value;
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _quickCard(
              context,
              title: 'City-wise Live Bus Map',
              subtitle: 'Select any India state and city to track route buses.',
              icon: Icons.location_searching,
              route: '/city-map',
              accentColor: colorScheme.primary,
            ),
            _quickCard(
              context,
              title: 'AI Arrival Prediction',
              subtitle: 'Traffic + historical delay based prediction.',
              icon: Icons.analytics,
              route: '/ai-features',
              accentColor: colorScheme.secondary,
            ),
            _quickCard(
              context,
              title: 'QR Ticket & Seat Availability',
              subtitle: 'Generate secure QR ticket and check live seats.',
              icon: Icons.qr_code_2,
              route: '/tickets',
              accentColor: colorScheme.tertiary,
            ),
            _quickCard(
              context,
              title: 'Real-Time Notifications',
              subtitle: 'Arrival, delay and route-change alerts.',
              icon: Icons.notifications_active,
              route: '/alerts',
              accentColor: colorScheme.secondary,
            ),
            _quickCard(
              context,
              title: 'Nearby Stops & Route Search',
              subtitle:
                  'Use GPS to detect nearest stop and search routes/stops.',
              icon: Icons.near_me,
              route: '/routes',
              accentColor: colorScheme.primary,
            ),
            _quickCard(
              context,
              title: 'Feedback, Voice & Offline',
              subtitle:
                  'Feedback analytics, voice assistant and offline route info.',
              icon: Icons.record_voice_over,
              route: '/ai-features',
              accentColor: colorScheme.tertiary,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Safety & Quick Call',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _quickCall(context, '100'),
                            icon: const Icon(Icons.local_police),
                            label: const Text('Police'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _quickCall(context, '108'),
                            icon: const Icon(Icons.emergency),
                            label: const Text('Ambulance'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
