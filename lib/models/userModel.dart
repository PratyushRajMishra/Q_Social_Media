class UserModel {
  String? uid;
  String? name; // Changed from `fullname` to `name`
  String? about;
  String? phoneNumber;
  String? dob; // Added date of birth field

  UserModel({
    this.uid,
    this.name, // Changed from `fullname` to `name`
    this.about,
    this.dob, // Added date of birth parameter
    this.phoneNumber,
  });

  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map["uid"];
    name = map["name"]; // Changed from `fullname` to `name`
    about = map["about"];
    phoneNumber = map["phoneNumber"];
    dob = map["dob"]; // Added date of birth mapping
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name, // Changed from `fullname` to `name`
      "about": about,
      "phoneNumber": phoneNumber,
      "dob": dob, // Added date of birth mapping
    };
  }
}
