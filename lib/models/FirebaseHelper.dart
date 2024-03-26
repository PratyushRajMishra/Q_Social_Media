import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:q/models/userModel.dart';

class FirebaseHelper {
  static Future<void> saveUserModel(UserModel userModel) async {
    try {
      // Reference to the users collection
      CollectionReference users = FirebaseFirestore.instance.collection('users');

      // Add the user model to Firestore
      await users.doc(userModel.uid).set(userModel.toMap());
    } catch (e) {
      print('Error saving user model to Firestore: $e');
      // Handle the error
    }
  }

  static Future<UserModel?> getUserModelById(String uid) async {
    UserModel? userModel;

    try {
      DocumentSnapshot docSnap = await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (docSnap.exists) {
        Map<String, dynamic>? userData = docSnap.data() as Map<String, dynamic>?;

        if (userData != null) {
          userModel = UserModel.fromMap(userData);
        }
      }
    } catch (e) {
      print('Error fetching user model from Firestore: $e');
      // Handle the error
    }

    return userModel;
  }

  static Future<bool> doesUserExist(String uid) async {
    try {
      // Query Firestore to check if a document with the provided UID exists
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // Check if the snapshot contains data
      return snapshot.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }
}
