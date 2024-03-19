import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/FirebaseHelper.dart';
import '../../models/userModel.dart';
import '../bottom_NavBar.dart';


class OTPValidationPage extends StatefulWidget {
  final String countryCode;
  final String phoneNumber;
  final String name;
  final String dob;

  const OTPValidationPage({
    Key? key,
    required this.countryCode,
    required this.phoneNumber,
    required this.name,
    required this.dob,
  }) : super(key: key);

  @override
  State<OTPValidationPage> createState() => _OTPValidationPageState();
}

class _OTPValidationPageState extends State<OTPValidationPage> {
  late PinTheme defaultPinTheme;
  late String verificationId;
  late String? otpCode; // Define otpCode variable
  final _pinEditingController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromRGBO(198, 198, 198, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    // Send OTP when the page loads
    _sendOTP();
  }

  void _sendOTP() async {
    try {
      // Send OTP
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.countryCode + widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          print('Failed to verify phone number: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print('Error sending OTP: $e');
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      // Verify OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: _pinEditingController.text,
      );

      // Sign in with the credential
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      // Check if user exists
      if (user != null) {
        // Check if the phone number is already associated with another account
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: widget.countryCode + widget.phoneNumber)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          // Show error message if the phone number is already registered
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('The phone number is already associated with another account.'),
            ),
          );
          return;
        }

        // Create a UserModel object with the retrieved data
        UserModel userModel = UserModel(
          uid: user.uid,
          name: widget.name,
          phoneNumber: widget.countryCode + widget.phoneNumber,
          dob: widget.dob,
        );

        // Save user data in Firebase Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavbarPage(
              userModel: userModel,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect OTP. Please try again.'),
          ),
        );
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying OTP: $e'),
        ),
      );
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(onPressed: () {
          Navigator.pop(context);
        }, icon: Icon(Icons.close, size: 30,)),
        title: Builder(
          builder: (BuildContext context) {
            return Image.asset(
              Theme.of(context).brightness == Brightness.light
                  ? 'assets/logo_dark.png'
                  : 'assets/logo_light.png',
              height: 40,
              width: 40,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We sent you a code',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Enter it below to verify  ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${widget.countryCode.toString()} '
                      '${widget.phoneNumber.toString()}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Pinput(
                    length: 6,
                    showCursor: true,
                    defaultPinTheme: defaultPinTheme,
                    controller: _pinEditingController,
                    onChanged: (value) {
                      setState(() {
                        otpCode = value;
                      });
                      if (value.length == 6) {
                        _verifyOTP();
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Didn't receive SMS?",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blue,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_isVerifying)
                    CircularProgressIndicator()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
