import 'bus_route.dart';
import 'bus_routes_repository.dart';

class IndiaStateTransit {
  final String name;
  final List<IndiaCityTransit> cities;

  const IndiaStateTransit({required this.name, required this.cities});
}

class IndiaCityTransit {
  final String name;
  final double latitude;
  final double longitude;
  final List<String> routeIds;

  const IndiaCityTransit({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.routeIds,
  });
}

class IndiaTransitCatalog {
  static const int _totalRoutes = 50;

  static final List<IndiaStateTransit> allStates = _buildStates();

  static List<String> get stateNames =>
      allStates.map((state) => state.name).toList(growable: false);

  static IndiaStateTransit? getState(String stateName) {
    for (final state in allStates) {
      if (state.name == stateName) {
        return state;
      }
    }
    return null;
  }

  static IndiaCityTransit? getCity(String stateName, String cityName) {
    final state = getState(stateName);
    if (state == null) {
      return null;
    }

    for (final city in state.cities) {
      if (city.name == cityName) {
        return city;
      }
    }
    return null;
  }

  static List<BusRoute> routesForCity(String stateName, String cityName) {
    final city = getCity(stateName, cityName);
    if (city == null) {
      return const <BusRoute>[];
    }

    final routes = <BusRoute>[];
    for (final routeId in city.routeIds) {
      final route = BusRoutesRepository.getRouteById(routeId);
      if (route != null) {
        routes.add(route);
      }
    }
    return routes;
  }

  static List<IndiaStateTransit> _buildStates() {
    final definitions = <(String, List<(String, double, double, int)>)>[
      (
        'Andhra Pradesh',
        [
          ('Visakhapatnam', 17.6868, 83.2185, 1),
          ('Vijayawada', 16.5062, 80.6480, 2)
        ]
      ),
      (
        'Arunachal Pradesh',
        [('Itanagar', 27.0844, 93.6053, 3), ('Tawang', 27.5861, 91.8639, 4)]
      ),
      (
        'Assam',
        [('Guwahati', 26.1445, 91.7362, 5), ('Dibrugarh', 27.4728, 94.9120, 6)]
      ),
      (
        'Bihar',
        [('Patna', 25.5941, 85.1376, 7), ('Gaya', 24.7914, 85.0002, 8)]
      ),
      (
        'Chhattisgarh',
        [('Raipur', 21.2514, 81.6296, 9), ('Bilaspur', 22.0797, 82.1409, 10)]
      ),
      (
        'Goa',
        [('Panaji', 15.4909, 73.8278, 11), ('Margao', 15.2993, 73.9580, 12)]
      ),
      (
        'Gujarat',
        [('Ahmedabad', 23.0225, 72.5714, 13), ('Surat', 21.1702, 72.8311, 14)]
      ),
      (
        'Haryana',
        [
          ('Gurugram', 28.4595, 77.0266, 15),
          ('Faridabad', 28.4089, 77.3178, 16)
        ]
      ),
      (
        'Himachal Pradesh',
        [
          ('Shimla', 31.1048, 77.1734, 17),
          ('Dharamshala', 32.2190, 76.3234, 18)
        ]
      ),
      (
        'Jharkhand',
        [('Ranchi', 23.3441, 85.3096, 19), ('Jamshedpur', 22.8046, 86.2029, 20)]
      ),
      (
        'Karnataka',
        [('Bengaluru', 12.9716, 77.5946, 21), ('Mysuru', 12.2958, 76.6394, 22)]
      ),
      (
        'Kerala',
        [
          ('Kochi', 9.9312, 76.2673, 23),
          ('Thiruvananthapuram', 8.5241, 76.9366, 24)
        ]
      ),
      (
        'Madhya Pradesh',
        [('Bhopal', 23.2599, 77.4126, 25), ('Indore', 22.7196, 75.8577, 26)]
      ),
      (
        'Maharashtra',
        [('Mumbai', 19.0760, 72.8777, 27), ('Pune', 18.5204, 73.8567, 28)]
      ),
      (
        'Manipur',
        [
          ('Imphal', 24.8170, 93.9368, 29),
          ('Churachandpur', 24.3333, 93.6833, 30)
        ]
      ),
      (
        'Meghalaya',
        [('Shillong', 25.5788, 91.8933, 31), ('Tura', 25.5142, 90.2021, 32)]
      ),
      (
        'Mizoram',
        [('Aizawl', 23.7271, 92.7176, 33), ('Lunglei', 22.8671, 92.7650, 34)]
      ),
      (
        'Nagaland',
        [('Kohima', 25.6751, 94.1086, 35), ('Dimapur', 25.9091, 93.7276, 36)]
      ),
      (
        'Odisha',
        [
          ('Bhubaneswar', 20.2961, 85.8245, 37),
          ('Cuttack', 20.4625, 85.8828, 38)
        ]
      ),
      (
        'Punjab',
        [('Ludhiana', 30.9010, 75.8573, 39), ('Amritsar', 31.6340, 74.8723, 40)]
      ),
      (
        'Rajasthan',
        [('Jaipur', 26.9124, 75.7873, 41), ('Jodhpur', 26.2389, 73.0243, 42)]
      ),
      (
        'Sikkim',
        [('Gangtok', 27.3389, 88.6065, 43), ('Namchi', 27.1667, 88.3667, 44)]
      ),
      (
        'Tamil Nadu',
        [
          ('Chennai', 13.0827, 80.2707, 45),
          ('Coimbatore', 11.0168, 76.9558, 46)
        ]
      ),
      (
        'Telangana',
        [
          ('Hyderabad', 17.3850, 78.4867, 47),
          ('Warangal', 17.9689, 79.5941, 48)
        ]
      ),
      (
        'Tripura',
        [('Agartala', 23.8315, 91.2868, 49), ('Udaipur', 23.5333, 91.4833, 50)]
      ),
      (
        'Uttar Pradesh',
        [('Lucknow', 26.8467, 80.9462, 51), ('Varanasi', 25.3176, 82.9739, 52)]
      ),
      (
        'Uttarakhand',
        [('Dehradun', 30.3165, 78.0322, 53), ('Haridwar', 29.9457, 78.1642, 54)]
      ),
      (
        'West Bengal',
        [('Kolkata', 22.5726, 88.3639, 55), ('Siliguri', 26.7271, 88.3953, 56)]
      ),
      ('Andaman and Nicobar Islands', [('Port Blair', 11.6234, 92.7265, 57)]),
      ('Chandigarh', [('Chandigarh', 30.7333, 76.7794, 58)]),
      (
        'Dadra and Nagar Haveli and Daman and Diu',
        [('Daman', 20.3974, 72.8328, 59)]
      ),
      ('Delhi', [('New Delhi', 28.6139, 77.2090, 60)]),
      (
        'Jammu and Kashmir',
        [('Srinagar', 34.0837, 74.7973, 61), ('Jammu', 32.7266, 74.8570, 62)]
      ),
      ('Ladakh', [('Leh', 34.1526, 77.5770, 63)]),
      ('Lakshadweep', [('Kavaratti', 10.5667, 72.6417, 64)]),
      ('Puducherry', [('Puducherry', 11.9416, 79.8083, 65)]),
    ];

    return definitions
        .map(
          (stateDefinition) => IndiaStateTransit(
            name: stateDefinition.$1,
            cities: stateDefinition.$2
                .map(
                  (cityDefinition) => IndiaCityTransit(
                    name: cityDefinition.$1,
                    latitude: cityDefinition.$2,
                    longitude: cityDefinition.$3,
                    routeIds: _routeIdsFromSeed(cityDefinition.$4),
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  static List<String> _routeIdsFromSeed(int seed) {
    final start = (seed % _totalRoutes) + 1;
    final routeIds = <String>[];
    for (var index = 0; index < 5; index++) {
      final routeNumber = ((start + (index * 7) - 1) % _totalRoutes) + 1;
      routeIds.add('r$routeNumber');
    }
    return routeIds;
  }
}
