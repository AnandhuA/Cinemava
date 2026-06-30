class PersonProfile {
  const PersonProfile({
    required this.id,
    required this.name,
    required this.biography,
    required this.profileUrl,
    required this.knownForDepartment,
    required this.birthday,
    required this.placeOfBirth,
  });

  final int id;
  final String name;
  final String biography;
  final String profileUrl;
  final String knownForDepartment;
  final String birthday;
  final String placeOfBirth;
}
