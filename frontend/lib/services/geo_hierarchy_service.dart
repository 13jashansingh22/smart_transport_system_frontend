class GeoHierarchyService {
  static const String prefState = 'pref_state';
  static const String prefCity = 'pref_city';
  static const String prefTown = 'pref_town';

  static const String defaultState = 'Punjab';
  static const String defaultCity = 'Chandigarh';
  static const String defaultTown = 'Sector 17';

  static const Map<String, List<String>> _citiesByState = {
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Tirupati'],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Tawang'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh'],
    'Bihar': ['Patna', 'Gaya', 'Muzaffarpur'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur'],
    'Goa': ['Panaji', 'Margao', 'Mapusa'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara'],
    'Haryana': ['Gurugram', 'Faridabad', 'Panipat'],
    'Himachal Pradesh': ['Shimla', 'Dharamshala', 'Mandi'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru'],
    'Kerala': ['Kochi', 'Thiruvananthapuram', 'Kozhikode'],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur'],
    'Manipur': ['Imphal', 'Thoubal', 'Churachandpur'],
    'Meghalaya': ['Shillong', 'Tura', 'Jowai'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Champhai'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela'],
    'Punjab': ['Chandigarh', 'Ludhiana', 'Amritsar'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur'],
    'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad'],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Varanasi'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Haldwani'],
    'West Bengal': ['Kolkata', 'Howrah', 'Siliguri'],
    'Andaman and Nicobar Islands': ['Port Blair', 'Diglipur', 'Car Nicobar'],
    'Chandigarh': ['Chandigarh', 'Manimajra', 'Sector 17'],
    'Dadra and Nagar Haveli and Daman and Diu': ['Daman', 'Diu', 'Silvassa'],
    'Delhi': ['New Delhi', 'Dwarka', 'Rohini'],
    'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag'],
    'Ladakh': ['Leh', 'Kargil', 'Nubra'],
    'Lakshadweep': ['Kavaratti', 'Agatti', 'Amini'],
    'Puducherry': ['Puducherry', 'Karaikal', 'Mahe'],
  };

  static const Map<String, List<String>> _townsByStateCity = {
    'Punjab|Chandigarh': ['Sector 17', 'Sector 22', 'Manimajra'],
    'Punjab|Ludhiana': ['Model Town', 'Dugri', 'Sarabha Nagar'],
    'Punjab|Amritsar': ['Ranjit Avenue', 'Putlighar', 'Chheharta'],
    'Haryana|Gurugram': ['DLF Phase 1', 'Sohna', 'Manesar'],
    'Haryana|Faridabad': ['NIT', 'Ballabhgarh', 'Old Faridabad'],
    'Haryana|Panipat': ['Model Town', 'Samalkha', 'Israna'],
    'Delhi|New Delhi': ['Connaught Place', 'Karol Bagh', 'Lajpat Nagar'],
    'Delhi|Dwarka': ['Sector 6', 'Sector 10', 'Sector 21'],
    'Delhi|Rohini': ['Sector 3', 'Sector 8', 'Sector 24'],
    'Uttar Pradesh|Lucknow': ['Hazratganj', 'Aliganj', 'Gomti Nagar'],
    'Uttar Pradesh|Kanpur': ['Civil Lines', 'Kidwai Nagar', 'Kalyanpur'],
    'Uttar Pradesh|Varanasi': ['Lanka', 'Sigra', 'Bhelupur'],
    'Rajasthan|Jaipur': ['Malviya Nagar', 'Vaishali Nagar', 'Mansarovar'],
    'Rajasthan|Jodhpur': ['Shastri Nagar', 'Ratanada', 'Paota'],
    'Rajasthan|Udaipur': ['Hiran Magri', 'Fatehpura', 'Sukher'],
    'Maharashtra|Mumbai': ['Andheri', 'Bandra', 'Borivali'],
    'Maharashtra|Pune': ['Hinjewadi', 'Kothrud', 'Hadapsar'],
    'Maharashtra|Nagpur': ['Dharampeth', 'Sitabuldi', 'Sadar'],
    'Gujarat|Ahmedabad': ['Navrangpura', 'Bopal', 'Maninagar'],
    'Gujarat|Surat': ['Adajan', 'Vesu', 'Katargam'],
    'Gujarat|Vadodara': ['Alkapuri', 'Manjalpur', 'Gotri'],
    'Madhya Pradesh|Bhopal': ['Arera Colony', 'Kolar', 'MP Nagar'],
    'Madhya Pradesh|Indore': ['Vijay Nagar', 'Rau', 'Palasia'],
    'Madhya Pradesh|Jabalpur': ['Napier Town', 'Adhartal', 'Gorakhpur'],
    'Bihar|Patna': ['Kankarbagh', 'Boring Road', 'Danapur'],
    'Bihar|Gaya': ['Delha', 'Bodh Gaya', 'AP Colony'],
    'Bihar|Muzaffarpur': ['Mithanpura', 'Brahmpura', 'Aghoria Bazar'],
    'Jharkhand|Ranchi': ['Harmu', 'Doranda', 'Lalpur'],
    'Jharkhand|Jamshedpur': ['Sakchi', 'Bistupur', 'Telco'],
    'Jharkhand|Dhanbad': ['Bank More', 'Saraidhela', 'Hirapur'],
    'West Bengal|Kolkata': ['Salt Lake', 'Howrah Maidan', 'Tollygunge'],
    'West Bengal|Howrah': ['Shibpur', 'Liluah', 'Salkia'],
    'West Bengal|Siliguri': ['Pradhan Nagar', 'Matigara', 'Hakim Para'],
    'Karnataka|Bengaluru': ['Whitefield', 'Yelahanka', 'Jayanagar'],
    'Karnataka|Mysuru': ['Kuvempunagar', 'Vijayanagar', 'Hebbal'],
    'Karnataka|Mangaluru': ['Kadri', 'Surathkal', 'Kankanady'],
    'Tamil Nadu|Chennai': ['Tambaram', 'T Nagar', 'Velachery'],
    'Tamil Nadu|Coimbatore': ['RS Puram', 'Gandhipuram', 'Peelamedu'],
    'Tamil Nadu|Madurai': ['Anna Nagar', 'KK Nagar', 'Thiruparankundram'],
    'Kerala|Kochi': ['Edappally', 'Fort Kochi', 'Kakkanad'],
    'Kerala|Thiruvananthapuram': ['Pattom', 'Kazhakoottam', 'Kowdiar'],
    'Kerala|Kozhikode': ['Mavoor Road', 'Kallai', 'Beypore'],
    'Telangana|Hyderabad': ['Gachibowli', 'Madhapur', 'Kukatpally'],
    'Telangana|Warangal': ['Hanamkonda', 'Kazipet', 'Subedari'],
    'Telangana|Nizamabad': ['Bodhan', 'Armoor', 'Dichpally'],
    'Andhra Pradesh|Visakhapatnam': ['MVP Colony', 'Gajuwaka', 'Madhurawada'],
    'Andhra Pradesh|Vijayawada': ['Benz Circle', 'Patamata', 'Gollapudi'],
    'Andhra Pradesh|Tirupati': ['Renigunta', 'Alipiri', 'Tiruchanoor'],
    'Odisha|Bhubaneswar': ['Patia', 'Khandagiri', 'Saheed Nagar'],
    'Odisha|Cuttack': ['Badambadi', 'Jobra', 'Choudwar'],
    'Odisha|Rourkela': ['Civil Township', 'Udit Nagar', 'Chhend'],
    'Chhattisgarh|Raipur': ['Shankar Nagar', 'Pandri', 'Tatibandh'],
    'Chhattisgarh|Bhilai': ['Nehru Nagar', 'Supela', 'Risali'],
    'Chhattisgarh|Bilaspur': ['Sarkanda', 'Torwa', 'Tifra'],
    'Assam|Guwahati': ['Dispur', 'Beltola', 'Maligaon'],
    'Assam|Silchar': ['Tarapur', 'Rangirkhari', 'Ambikapatty'],
    'Assam|Dibrugarh': ['Bamunbari', 'Chowkidinghee', 'Lahoal'],
    'Himachal Pradesh|Shimla': ['Sanjauli', 'Mall Road', 'Dhalli'],
    'Himachal Pradesh|Dharamshala': [
      'McLeod Ganj',
      'Sidhpur',
      'Kotwali Bazaar'
    ],
    'Himachal Pradesh|Mandi': ['Paddal', 'Sunder Nagar', 'Ner Chowk'],
    'Uttarakhand|Dehradun': ['Rajpur Road', 'Prem Nagar', 'Vasant Vihar'],
    'Uttarakhand|Haridwar': ['Jwalapur', 'BHEL', 'Kankhal'],
    'Uttarakhand|Haldwani': ['Kathgodam', 'Mukhani', 'Rampur Road'],
    'Goa|Panaji': ['Miramar', 'Dona Paula', 'Caranzalem'],
    'Goa|Margao': ['Fatorda', 'Navelim', 'Borda'],
    'Goa|Mapusa': ['Siolim', 'Anjuna', 'Calangute'],
    'Jammu and Kashmir|Srinagar': ['Lal Chowk', 'Bemina', 'Hazratbal'],
    'Jammu and Kashmir|Jammu': ['Gandhi Nagar', 'Trikuta Nagar', 'Janipur'],
    'Jammu and Kashmir|Anantnag': ['Lal Chowk', 'Khanabal', 'Bijbehara'],
    'Ladakh|Leh': ['Choglamsar', 'Skara', 'Shey'],
    'Ladakh|Kargil': ['Baroo', 'Shilikchey', 'Minji'],
    'Ladakh|Nubra': ['Diskit', 'Hunder', 'Sumur'],
    'Sikkim|Gangtok': ['Tadong', 'Deorali', 'Lal Bazaar'],
    'Sikkim|Namchi': ['Jorethang', 'Rangpo', 'Sadam'],
    'Sikkim|Gyalshing': ['Pelling', 'Dentam', 'Yuksom'],
    'Arunachal Pradesh|Itanagar': ['Naharlagun', 'Doimukh', 'Nirjuli'],
    'Arunachal Pradesh|Naharlagun': ['Nirjuli', 'Doimukh', 'Banderdewa'],
    'Arunachal Pradesh|Tawang': ['Lumla', 'Jang', 'Kitpi'],
    'Meghalaya|Shillong': ['Laitumkhrah', 'Police Bazar', 'Mawlai'],
    'Meghalaya|Tura': ['Dalu', 'Araimile', 'Dakopgre'],
    'Meghalaya|Jowai': ['Ialong', 'Ladthadlaboh', 'Panaliar'],
    'Manipur|Imphal': ['Thangmeiband', 'Singjamei', 'Kakching'],
    'Manipur|Thoubal': ['Lilong', 'Wangjing', 'Heirok'],
    'Manipur|Churachandpur': ['Lamka', 'Tuibong', 'Zenhang'],
    'Mizoram|Aizawl': ['Dawrpui', 'Chaltlang', 'Bawngkawn'],
    'Mizoram|Lunglei': ['Bazar Veng', 'Ramthar', 'Serkawn'],
    'Mizoram|Champhai': ['Kanan Veng', 'Vengthlang', 'Zote'],
    'Nagaland|Kohima': ['Seikhazou', 'Lerie', 'PR Hill'],
    'Nagaland|Dimapur': ['Chumukedima', 'Purana Bazar', 'Dhansiripar'],
    'Nagaland|Mokokchung': ['Alempang', 'Sungkomen', 'Yimyu'],
    'Tripura|Agartala': ['Kunjaban', 'Jogendranagar', 'Pratapgarh'],
    'Tripura|Udaipur': ['Matabari', 'Rajarbag', 'Kakrabon'],
    'Tripura|Dharmanagar': ['Jubarajnagar', 'Padmabil', 'Nayapara'],
    'Andaman and Nicobar Islands|Port Blair': [
      'Aberdeen',
      'Haddo',
      'Dollygunj'
    ],
    'Andaman and Nicobar Islands|Diglipur': [
      'Subashgram',
      'Kalipur',
      'Ramnagar'
    ],
    'Andaman and Nicobar Islands|Car Nicobar': ['Malacca', 'Perka', 'Mus'],
    'Chandigarh|Chandigarh': ['Sector 17', 'Sector 22', 'Sector 43'],
    'Chandigarh|Manimajra': ['Pocket 1', 'Pocket 2', 'Modern Housing Complex'],
    'Chandigarh|Sector 17': ['Sector 16', 'Sector 18', 'Sector 19'],
    'Dadra and Nagar Haveli and Daman and Diu|Daman': [
      'Nani Daman',
      'Moti Daman',
      'Kadaiya'
    ],
    'Dadra and Nagar Haveli and Daman and Diu|Diu': [
      'Ghoghla',
      'Vanakbara',
      'Fudam'
    ],
    'Dadra and Nagar Haveli and Daman and Diu|Silvassa': [
      'Amli',
      'Samarvarni',
      'Dadra'
    ],
    'Lakshadweep|Kavaratti': ['Ujra', 'Amini', 'Kalpeni'],
    'Lakshadweep|Agatti': ['Kavaratti Link', 'Kochi Jetty', 'Airport Zone'],
    'Lakshadweep|Amini': ['Kiltan Link', 'Kadmat', 'Bitra'],
    'Puducherry|Puducherry': ['White Town', 'Lawspet', 'Muthialpet'],
    'Puducherry|Karaikal': ['Nedungadu', 'Kottucherry', 'Tirunallar'],
    'Puducherry|Mahe': ['Chalakkara', 'Palloor', 'Pandakkal'],
  };

  static List<String> states() {
    final list = _citiesByState.keys.toList(growable: false)..sort();
    return list;
  }

  static List<String> citiesByState(String state) {
    final cities = _citiesByState[state];
    if (cities == null || cities.isEmpty) {
      return const [defaultCity];
    }
    return cities;
  }

  static List<String> townsByStateAndCity(String state, String city) {
    final key = '$state|$city';
    final towns = _townsByStateCity[key];
    if (towns == null || towns.isEmpty) {
      return const [
        'Main Town',
        'New Town',
        'Old Town',
      ];
    }
    return towns;
  }
}
