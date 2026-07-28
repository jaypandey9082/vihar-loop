class Neighborhood {
  const Neighborhood({
    required this.id,
    required this.name,
    required this.city,
  });

  final String id;
  final String name;
  final String city;

  static const vidyavihar = Neighborhood(
    id: 'vidyavihar',
    name: 'Vidyavihar',
    city: 'Mumbai',
  );
}
