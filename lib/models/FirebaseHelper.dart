import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:q/models/userModel.dart';

class FirebaseHelper {
  static Future<UserModel?> getUserModelById(String uid) async {
    UserModel? userModel;

    DocumentSnapshot docSnap = await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (docSnap.exists) {
      // Explicitly cast to Map<String, dynamic>
      Map<String, dynamic>? userData = docSnap.data() as Map<String, dynamic>?;

      if (userData != null) {
        userModel = UserModel.fromMap(userData);
      }
    }

    return userModel;
  }
}
