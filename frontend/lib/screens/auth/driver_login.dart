import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../driver_screen.dart';
import '../../services/geo_hierarchy_service.dart';
import '../../services/security_service.dart';
import '../../services/user_profile_context_service.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  late final List<String> _states;
  late List<String> _cities;
  late List<String> _towns;
  String? _selectedState;
  String? _selectedCity;
  String? _selectedTown;

  static const String _attemptKey = 'driver_login';

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _states = GeoHierarchyService.states();
    _selectedState = _states.contains(GeoHierarchyService.defaultState)
        ? GeoHierarchyService.defaultState
        : _states.first;
    _cities = GeoHierarchyService.citiesByState(_selectedState!);
    _selectedCity = _cities.contains(GeoHierarchyService.defaultCity)
        ? GeoHierarchyService.defaultCity
        : _cities.first;
    _towns = GeoHierarchyService.townsByStateAndCity(
      _selectedState!,
      _selectedCity!,
    );
    _selectedTown = _towns.contains(GeoHierarchyService.defaultTown)
        ? GeoHierarchyService.defaultTown
        : _towns.first;
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  String _formatRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  void _onStateChanged(String? state) {
    if (state == null) return;
    final cities = GeoHierarchyService.citiesByState(state);
    final city = cities.first;
    final towns = GeoHierarchyService.townsByStateAndCity(state, city);

    setState(() {
      _selectedState = state;
      _cities = cities;
      _selectedCity = city;
      _towns = towns;
      _selectedTown = towns.first;
    });
  }

  void _onCityChanged(String? city) {
    if (city == null || _selectedState == null) return;
    final towns =
        GeoHierarchyService.townsByStateAndCity(_selectedState!, city);

    setState(() {
      _selectedCity = city;
      _towns = towns;
      _selectedTown = towns.first;
    });
  }

  Future loginDriver() async {
    final remaining = SecurityService.getRemainingLock(_attemptKey);
    if (remaining != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Too many attempts. Try again in ${_formatRemaining(remaining)}.',
          ),
        ),
      );
      return;
    }

    final normalizedEmail = SecurityService.normalizeEmail(email.text);
    final normalizedPassword = SecurityService.normalizePassword(password.text);

    if (!SecurityService.isValidEmail(normalizedEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    if (_selectedState == null ||
        _selectedCity == null ||
        _selectedTown == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select state, city and town.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: normalizedEmail, password: normalizedPassword);

      SecurityService.registerSuccess(_attemptKey);

      await UserProfileContextService.save(
        role: 'driver',
        state: _selectedState!,
        city: _selectedCity!,
        town: _selectedTown!,
        email: normalizedEmail,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DriverScreen()));
    } on FirebaseAuthException {
      SecurityService.registerFailure(_attemptKey);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Driver Login Failed. Check credentials.")));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong. Try again.")));
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Login')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.drive_eta_rounded,
                                  color: colorScheme.primary,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Driver Sign In',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Secure access to navigation and command tools.',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                                labelText: 'Driver Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('state_${_selectedState ?? ''}'),
                            initialValue: _selectedState,
                            decoration: const InputDecoration(
                              labelText: 'State',
                            ),
                            items: _states
                                .map(
                                  (state) => DropdownMenuItem(
                                    value: state,
                                    child: Text(state),
                                  ),
                                )
                                .toList(),
                            onChanged: loading ? null : _onStateChanged,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('city_${_selectedCity ?? ''}'),
                            initialValue: _selectedCity,
                            decoration: const InputDecoration(
                              labelText: 'City',
                            ),
                            items: _cities
                                .map(
                                  (city) => DropdownMenuItem(
                                    value: city,
                                    child: Text(city),
                                  ),
                                )
                                .toList(),
                            onChanged: loading ? null : _onCityChanged,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('town_${_selectedTown ?? ''}'),
                            initialValue: _selectedTown,
                            decoration: const InputDecoration(
                              labelText: 'Town / Area',
                            ),
                            items: _towns
                                .map(
                                  (town) => DropdownMenuItem(
                                    value: town,
                                    child: Text(town),
                                  ),
                                )
                                .toList(),
                            onChanged: loading
                                ? null
                                : (value) =>
                                    setState(() => _selectedTown = value),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading ? null : loginDriver,
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Login'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
