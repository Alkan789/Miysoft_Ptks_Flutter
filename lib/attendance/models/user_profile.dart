class UserProfile {
  final int id;
  final String name;
  final String? checkInLocation;
  final String? checkOutLocation;

  UserProfile({
    required this.id,
    required this.name,
    this.checkInLocation,
    this.checkOutLocation,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      checkInLocation: json['check_in_location'],
      checkOutLocation: json['check_out_location'],
    );
  }
}