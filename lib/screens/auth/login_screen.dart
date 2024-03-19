import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';
import 'package:q/models/userModel.dart';
import '../bottom_NavBar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneNumberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _phoneNumberError;
  bool _isSendingOTP = false; // Add this variable

  bool _isVerificationPageOpened = false;

  void _submitPhoneNumber(BuildContext context) async {
    String phoneNumber = _phoneNumberController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _phoneNumberError = '* Please enter a valid phone number';
      });
      return;
    } else {
      setState(() {
        _phoneNumberError = null;
        _isSendingOTP = true; // Set sending state when OTP sending starts
      });
    }

    String formattedPhoneNumber = '+91$phoneNumber'; // Adjust country code if needed
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          print('User logged in successfully.');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Failed to verify phone number: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Set _isSendingOTP to false when OTP is sent
          setState(() {
            _isSendingOTP = false;
          });

          // Navigate to OTPVerificationPage after OTP sent
          _isVerificationPageOpened = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Set _isSendingOTP to false when OTP retrieval times out
          setState(() {
            _isSendingOTP = false;
          });

          // Navigate to OTPVerificationPage after code retrieval timeout
          _isVerificationPageOpened = true;
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => OTPVerificationPage(
          //       verificationId: verificationId,
          //     ),
          //   ),
          // );
        },
      );
    } catch (e) {
      print('Error submitting phone number: $e');
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To get started, first enter your phone number.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              onChanged: (_) {
                // Clear the error message when the user starts typing
                setState(() {
                  _phoneNumberError = null;
                });
              },
              decoration: InputDecoration(
                labelText: 'Enter phone number',
                hintText: 'Enter phone number',
                //errorText: _phoneNumberError,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              _phoneNumberError ?? '',
              style: TextStyle(color: Colors.red),
            ), // <-- Modified line
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {},
                child: Text('Forgot Password?'),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      // Adjust the radius as needed
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _phoneNumberController.text.isEmpty || _isSendingOTP ? null : () => _submitPhoneNumber(context),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      // Adjust the radius as needed
                    ),
                  ),
                ),
                child: _isSendingOTP ? const Text('OTP Sending...') : const Text('Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OTPVerificationPage extends StatefulWidget {
  final String verificationId;

  const OTPVerificationPage({Key? key, required this.verificationId})
      : super(key: key);

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _otpController = TextEditingController();
  late String _verificationId;
  late bool _isVerifying;

  // Initialize defaultPinTheme
  late PinTheme defaultPinTheme = PinTheme(
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

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _isVerifying = false; // Initially, set _isVerifying to false
    _otpController.addListener(_verifyOTP);
  }

  void _verifyOTP() async {
    if (_otpController.text.length == 6) {
      setState(() {
        _isVerifying = true; // Start the verification process
      });

      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _otpController.text,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        print('User logged in successfully.');

        // Fetch user data based on the provided phone number
        String phoneNumber =
        FirebaseAuth.instance.currentUser!.phoneNumber!;
        UserModel? userModel = await fetchUserData(phoneNumber);

        if (userModel != null) {
          // Navigate to BottomNavbarPage after OTP verification
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavbarPage(userModel: userModel),
            ),
          );
        } else {
          // Show error message if user data not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User data not found'),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            _isVerifying = false; // Stop the verification process
          });
        }
      } catch (e) {
        setState(() {
          _isVerifying = false; // Stop the verification process on error
        });
        print('Error submitting OTP: $e');
      }
    }
  }


  Future<UserModel?> fetchUserData(String phoneNumber) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromMap(
            querySnapshot.docs.first.data() as Map<String, dynamic>);
      } else {
        print('User data not found');
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We sent you a code.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Enter six-digit code for verification...',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            SizedBox(height: 20),
            Pinput(
              length: 6,
              showCursor: true,
              defaultPinTheme: defaultPinTheme,
              pinAnimationType: PinAnimationType.fade,
              controller: _otpController,
            ),
            SizedBox(height: 20),
            _isVerifying
                ? Center(
              child: CircularProgressIndicator(),
            )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}