class UserModel {
  String? uid;
  String? name; // Changed from `fullname` to `name`
  String? bio;
  String? phoneNumber;
  String? dob; // Added date of birth field
  String? profile; // Added profile field
  String? location; // Added location field
  String? website; // Added website field
  String? email; // Added email field

  UserModel({
    this.uid,
    this.name, // Changed from `fullname` to `name`
    this.bio,
    this.dob, // Added date of birth parameter
    this.profile, // Added profile parameter
    this.location, // Added location parameter
    this.website, // Added website parameter
    this.phoneNumber,
    this.email, // Added email parameter
  });

  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map["uid"];
    name = map["name"]; // Changed from `fullname` to `name`
    bio = map["bio"];
    phoneNumber = map["phoneNumber"];
    dob = map["dob"]; // Added date of birth mapping
    profile = map["profile"]; // Added profile mapping
    location = map["location"]; // Added location mapping
    website = map["website"]; // Added website mapping
    email = map["email"]; // Added email mapping
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name, // Changed from `fullname` to `name`
      "bio": bio,
      "phoneNumber": phoneNumber,
      "dob": dob, // Added date of birth mapping
      "profile": profile, // Added profile mapping
      "location": location, // Added location mapping
      "website": website, // Added website mapping
      "email": email, // Added email mapping
    };
  }
}
