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
    required this.verified,
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

const _mayaJohnson = TaskerProfile(
  name: 'Maya Johnson',
  avatar: 'MJ',
  skill: 'Deep cleaning specialist',
  rating: 4.98,
  distance: '1.2 mi',
  matchScore: 98,
  completionRate: 99,
  reviews: 324,
  verified: true,
);

const _danielKim = TaskerProfile(
  name: 'Daniel Kim',
  avatar: 'DK',
  skill: 'Handyman and assembly',
  rating: 4.94,
  distance: '2.0 mi',
  matchScore: 94,
  completionRate: 97,
  reviews: 211,
  verified: true,
);

const _aishaPatel = TaskerProfile(
  name: 'Aisha Patel',
  avatar: 'AP',
  skill: 'Childcare and errands',
  rating: 4.91,
  distance: '0.8 mi',
  matchScore: 92,
  completionRate: 96,
  reviews: 178,
  verified: true,
);

const _johnDoe = TaskerProfile(
  name: 'John Doe',
  avatar: 'JD',
  skill: 'Professional moving & logistics',
  rating: 4.87,
  distance: '1.5 mi',
  matchScore: 95,
  completionRate: 98,
  reviews: 142,
  verified: true,
);

const _chefGrace = TaskerProfile(
  name: 'Chef Grace',
  avatar: 'CG',
  skill: 'Private chef and meal prep',
  rating: 4.95,
  distance: '2.3 mi',
  matchScore: 96,
  completionRate: 99,
  reviews: 89,
  verified: true,
);

const _maryAtieno = TaskerProfile(
  name: 'Mary Atieno',
  avatar: 'MA',
  skill: 'Laundry and home organization',
  rating: 4.89,
  distance: '0.6 mi',
  matchScore: 93,
  completionRate: 95,
  reviews: 120,
  verified: true,
);

const taskers = [
  _mayaJohnson,
  _danielKim,
  _aishaPatel,
  _johnDoe,
  _chefGrace,
  _maryAtieno,
];

const demoTasks = [
  TasklyTask(
    title: 'Deep clean 3-bedroom apartment',
    category: 'Cleaning',
    description: 'Kitchen, bathrooms, floors, windows, and laundry folding.',
    budget: r'$145',
    date: 'Tomorrow, 9:00 AM',
    status: 'Tasker on the way',
    tasker: _mayaJohnson,
  ),
  TasklyTask(
    title: 'Assemble standing desk',
    category: 'Handyman',
    description: 'New desk still boxed. Bring basic tools.',
    budget: r'$65',
    date: 'Friday, 3:30 PM',
    status: 'Scheduled',
    tasker: _danielKim,
  ),
];

const availableJobs = [
  AvailableJob(
    title: 'Apartment deep clean',
    customer: 'Olivia R.',
    distance: '1.4 mi',
    budget: r'$150',
    duration: '3.5 hrs',
    match: 97,
    instructions:
        'Pet-friendly home. Focus on kitchen, bathrooms, and windows.',
  ),
  AvailableJob(
    title: 'Move sofa and boxes',
    customer: 'Marcus T.',
    distance: '2.7 mi',
    budget: r'$120',
    duration: '2 hrs',
    match: 91,
    instructions: 'Elevator available. Two medium boxes and one sofa.',
  ),
  AvailableJob(
    title: 'Evening babysitting',
    customer: 'Priya S.',
    distance: '0.9 mi',
    budget: r'$96',
    duration: '4 hrs',
    match: 89,
    instructions: 'Two children, dinner already prepared.',
  ),
];

const earnings = [
  EarningPoint('Mon', 120),
  EarningPoint('Tue', 190),
  EarningPoint('Wed', 90),
  EarningPoint('Thu', 240),
  EarningPoint('Fri', 180),
  EarningPoint('Sat', 310),
  EarningPoint('Sun', 160),
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
  });

  final String name;
  final String email;
  final String password;
  final String initials;
  final String location;
  final double rating;
  final int tasksCount;
  final int savedCount;
}

const mockUsers = [
  TasklyUser(
    name: 'Zipporah Wambui',
    email: 'zipporah@taskly.com',
    password: 'password123',
    initials: 'ZW',
    location: 'Nairobi, Kenya',
    rating: 4.96,
    tasksCount: 32,
    savedCount: 8,
  ),
  TasklyUser(
    name: 'Olivia Rodriguez',
    email: 'olivia@taskly.com',
    password: 'password123',
    initials: 'OR',
    location: 'Mombasa, Kenya',
    rating: 4.85,
    tasksCount: 12,
    savedCount: 3,
  ),
];

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

