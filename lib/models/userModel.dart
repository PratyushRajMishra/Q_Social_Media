class UserModel {
  String? uid;
  String? name;
  String? bio;
  String? phoneNumber;
  String? dob;
  String? profile;
  String? location;
  String? website;
  String? email;
  List<String>? followers; // Added followers field
  List<String>? following; // Added following field

  UserModel({
    this.uid,
    this.name,
    this.bio,
    this.phoneNumber,
    this.dob,
    this.profile,
    this.location,
    this.website,
    this.email,
    this.followers, // Added followers parameter
    this.following, // Added following parameter
  });

  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map["uid"];
    name = map["name"];
    bio = map["bio"];
    phoneNumber = map["phoneNumber"];
    dob = map["dob"];
    profile = map["profile"];
    location = map["location"];
    website = map["website"];
    email = map["email"];
    followers = List<String>.from(map["followers"] ?? []); // Added followers mapping
    following = List<String>.from(map["following"] ?? []); // Added following mapping
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "bio": bio,
      "phoneNumber": phoneNumber,
      "dob": dob,
      "profile": profile,
      "location": location,
      "website": website,
      "email": email,
      "followers": followers, // Added followers mapping
      "following": following, // Added following mapping
    };
  }
}
