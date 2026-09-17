class ServiceCategory {
  const ServiceCategory({
    required this.name,
    required this.icon,
    required this.averagePrice,
    required this.popularity,
  });

  final String name;
  final String icon;
  final String averagePrice;
  final int popularity;
}

class TaskerProfile {
  const TaskerProfile({
    required this.name,
    required this.avatar,
    required this.skill,
    required this.rating,
    required this.distance,
    required this.matchScore,
    required this.completionRate,
    required this.reviews,
    this.verified = false,
    this.profilePictureUrl,
    this.idNumber,
  });

  final String name;
  final String avatar;
  final String skill;
  final double rating;
  final String distance;
  final int matchScore;
  final int completionRate;
  final int reviews;
  final bool verified;
  final String? profilePictureUrl;
  final String? idNumber;

  TaskerProfile copyWith({
    String? name,
    String? avatar,
    String? skill,
    double? rating,
    String? distance,
    int? matchScore,
    int? completionRate,
    int? reviews,
    bool? verified,
    String? profilePictureUrl,
    String? idNumber,
  }) {
    return TaskerProfile(
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      skill: skill ?? this.skill,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      matchScore: matchScore ?? this.matchScore,
      completionRate: completionRate ?? this.completionRate,
      reviews: reviews ?? this.reviews,
      verified: verified ?? this.verified,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      idNumber: idNumber ?? this.idNumber,
    );
  }
}

class TasklyTask {
  const TasklyTask({
    required this.title,
    required this.category,
    required this.description,
    required this.budget,
    required this.date,
    required this.status,
    this.tasker,
  });

  final String title;
  final String category;
  final String description;
  final String budget;
  final String date;
  final String status;
  final TaskerProfile? tasker;
}

class AvailableJob {
  const AvailableJob({
    required this.title,
    required this.customer,
    required this.distance,
    required this.budget,
    required this.duration,
    required this.match,
    required this.instructions,
  });

  final String title;
  final String customer;
  final String distance;
  final String budget;
  final String duration;
  final int match;
  final String instructions;
}

class EarningPoint {
  const EarningPoint(this.label, this.amount);

  final String label;
  final double amount;
}

const serviceCategories = [
  ServiceCategory(
    name: 'Cleaning',
    icon: 'sparkles',
    averagePrice: r'$45/hr',
    popularity: 94,
  ),
  ServiceCategory(
    name: 'Babysitting',
    icon: 'child_care',
    averagePrice: r'$30/hr',
    popularity: 88,
  ),
  ServiceCategory(
    name: 'Cooking',
    icon: 'restaurant',
    averagePrice: r'$38/hr',
    popularity: 81,
  ),
  ServiceCategory(
    name: 'Laundry',
    icon: 'local_laundry_service',
    averagePrice: r'$25/hr',
    popularity: 76,
  ),
  ServiceCategory(
    name: 'Handyman',
    icon: 'handyman',
    averagePrice: r'$55/hr',
    popularity: 91,
  ),
  ServiceCategory(
    name: 'Moving',
    icon: 'local_shipping',
    averagePrice: r'$70/hr',
    popularity: 86,
  ),
  ServiceCategory(
    name: 'Deliveries',
    icon: 'delivery_dining',
    averagePrice: r'$18/job',
    popularity: 79,
  ),
  ServiceCategory(
    name: 'Errands',
    icon: 'task_alt',
    averagePrice: r'$22/hr',
    popularity: 73,
  ),
];

const taskers = <TaskerProfile>[];

const demoTasks = <TasklyTask>[];

const availableJobs = <AvailableJob>[];

const earnings = <EarningPoint>[
  EarningPoint('Mon', 0),
  EarningPoint('Tue', 0),
  EarningPoint('Wed', 0),
  EarningPoint('Thu', 0),
  EarningPoint('Fri', 0),
  EarningPoint('Sat', 0),
  EarningPoint('Sun', 0),
];

class TasklyUser {
  const TasklyUser({
    required this.name,
    required this.email,
    required this.password,
    required this.initials,
    required this.location,
    required this.rating,
    required this.tasksCount,
    required this.savedCount,
    this.isVerified = false,
    this.profilePictureUrl,
    this.idNumber,
  });

  final String name;
  final String email;
  final String password;
  final String initials;
  final String location;
  final double rating;
  final int tasksCount;
  final int savedCount;
  final bool isVerified;
  final String? profilePictureUrl;
  final String? idNumber;

  TasklyUser copyWith({
    String? name,
    String? email,
    String? password,
    String? initials,
    String? location,
    double? rating,
    int? tasksCount,
    int? savedCount,
    bool? isVerified,
    String? profilePictureUrl,
    String? idNumber,
  }) {
    return TasklyUser(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      initials: initials ?? this.initials,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      tasksCount: tasksCount ?? this.tasksCount,
      savedCount: savedCount ?? this.savedCount,
      isVerified: isVerified ?? this.isVerified,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      idNumber: idNumber ?? this.idNumber,
    );
  }
}

const mockUsers = <TasklyUser>[];

const Map<String, List<String>> kenyaCountiesAndLocations = {
  'Nairobi': [
    'Westlands',
    'Kilimani',
    'Karen',
    'CBD / Central',
    'Lavington',
    'Kileleshwa',
    'Parklands',
    'Roysambu',
    'Kasarani',
    'Lang\'ata',
    'South B',
    'South C',
    'Embakasi',
    'Ngara',
    'Eastleigh',
    'Runda / Gigiri',
    'Dagoretti',
  ],
  'Kiambu': [
    'Ruiru',
    'Thika',
    'Kiambu Town',
    'Kikuyu',
    'Limuru',
    'Juja',
    'Karuri / Banana',
    'Githunguri',
    'Kabete',
    'Lari',
  ],
  'Mombasa': [
    'Nyali',
    'Bamburi',
    'Mvita (Island)',
    'Changamwe',
    'Likoni',
    'Kisauni',
    'Tudor',
    'Shanzu',
    'Jomvu',
  ],
  'Nakuru': [
    'Nakuru Town East',
    'Nakuru Town West',
    'Naivasha',
    'Gilgil',
    'Njoro',
    'Molo',
    'Rongai',
    'Subukia',
    'Bahati',
  ],
  'Machakos': [
    'Athi River',
    'Syokimau',
    'Mlolongo',
    'Machakos Town',
    'Kangundo',
    'Matungulu',
    'Mwala',
    'Kathiani',
  ],
  'Kajiado': [
    'Kitengela',
    'Ongata Rongai',
    'Ngong',
    'Kiserian',
    'Kajiado Town',
    'Loitokitok',
  ],
  'Kisumu': [
    'Kisumu Central',
    'Milimani',
    'Kisumu East',
    'Kisumu West',
    'Nyando',
    'Muhoroni',
    'Seme',
  ],
  'Uasin Gishu': [
    'Eldoret CBD',
    'Kapsoya',
    'Pioneer',
    'Huruma',
    'Kimumu',
    'Langas',
    'Moiben',
    'Ainabkoi',
  ],
  'Kilifi': [
    'Mtwapa',
    'Kilifi Town',
    'Malindi',
    'Watamu',
    'Mariakani',
    'Kaloleni',
    'Ganze',
  ],
  'Nyeri': [
    'Nyeri Town',
    'Karatina',
    'Othaya',
    'Mukurwe-ini',
    'Tetu',
    'Kieni',
  ],
  'Meru': [
    'Meru Town',
    'Imenti North',
    'Imenti South',
    'Nkubu',
    'Maua',
    'Tigania',
  ],
  'Kakamega': [
    'Kakamega Town',
    'Lurambi',
    'Mumias',
    'Shinyalu',
    'Malava',
    'Navakholo',
  ],
  'Kisii': [
    'Kisii Town',
    'Kitutu Chache',
    'Nyaribari Chache',
    'Bonchari',
    'South Mugirango',
  ],
  'Kericho': [
    'Kericho Town',
    'Bureti',
    'Belgut',
    'Ainamoi',
    'Kipkelion',
  ],
  'Laikipia': [
    'Nanyuki',
    'Nyahururu',
    'Rumuruti',
    'Laikipia East',
    'Laikipia West',
  ],
  'Bungoma': [
    'Bungoma Town',
    'Kanduyi',
    'Webuye',
    'Kimilili',
    'Sirisia',
  ],
  'Embu': [
    'Embu Town',
    'Runyenjes',
    'Manyatta',
    'Mbeere North',
    'Mbeere South',
  ],
  'Garissa': [
    'Garissa Town',
    'Dadaab',
    'Fafi',
    'Ijara',
  ],
  'Homa Bay': [
    'Homa Bay Town',
    'Mbita',
    'Ndhiwa',
    'Rachuonyo',
  ],
  'Isiolo': [
    'Isiolo Town',
    'Garbatulla',
    'Merti',
  ],
  'Kitui': [
    'Kitui Town',
    'Mwingi',
    'Kitui Central',
    'Kitui Rural',
  ],
  'Kwale': [
    'Diani',
    'Ukunda',
    'Msambweni',
    'Matuga',
    'Kinango',
  ],
  'Lamu': [
    'Lamu Island',
    'Shela',
    'Mpeketoni',
    'Witu',
  ],
  'Mandera': [
    'Mandera Town',
    'Elwak',
    'Rhamu',
  ],
  'Marsabit': [
    'Marsabit Town',
    'Moyale',
    'North Horr',
  ],
  'Migori': [
    'Migori Town',
    'Rongo',
    'Awendo',
    'Kuria East',
    'Kuria West',
  ],
  'Murang\'a': [
    'Murang\'a Town',
    'Kenol',
    'Thika Greens',
    'Kangema',
    'Kigumo',
    'Gatanga',
  ],
  'Nandi': [
    'Kapsabet',
    'Nandi Hills',
    'Aldai',
    'Mosop',
  ],
  'Narok': [
    'Narok Town',
    'Kilgoris',
    'Maasai Mara',
    'Suswa',
  ],
  'Nyandarua': [
    'Ol Kalou',
    'Engineer',
    'Kinangop',
    'Ndaragwa',
  ],
  'Siaya': [
    'Siaya Town',
    'Bondo',
    'Ugunja',
    'Yala',
    'Alego Usonga',
  ],
  'Taita Taveta': [
    'Voi',
    'Taveta',
    'Wundanyi',
    'Mwatate',
  ],
  'Tharaka Nithi': [
    'Chuka',
    'Marimanti',
    'Tharaka',
    'Maara',
  ],
  'Trans Nzoia': [
    'Kitale',
    'Kiminini',
    'Cherangany',
    'Endebess',
  ],
  'Turkana': [
    'Lodwar',
    'Kakuma',
    'Lokichogio',
  ],
  'Vihiga': [
    'Mbale',
    'Luanda',
    'Hamisi',
    'Emuhaya',
  ],
  'Wajir': [
    'Wajir Town',
    'Habaswein',
    'Bute',
  ],
  'West Pokot': [
    'Kapenguria',
    'Chepareria',
    'Makutano',
  ],
  'Baringo': [
    'Kabarnet',
    'Eldama Ravine',
    'Marigat',
  ],
  'Bomet': [
    'Bomet Town',
    'Sotik',
    'Konoin',
  ],
  'Busia': [
    'Busia Town',
    'Malaba',
    'Nambale',
  ],
  'Elgeyo Marakwet': [
    'Iten',
    'Kapsowar',
    'Tambach',
  ],
  'Kirinyaga': [
    'Kerugoya',
    'Kutus',
    'Sagana',
    'Mwea',
  ],
  'Makueni': [
    'Wote',
    'Emali',
    'Kibwezi',
    'Makindu',
  ],
  'Samburu': [
    'Maralal',
    'Baragoi',
    'Wamba',
  ],
  'Tana River': [
    'Hola',
    'Garsen',
    'Bura',
  ],
};

