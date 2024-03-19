import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:q/screens/auth/otp_validation.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  CountryCode? countryCode;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  DateTime selectedDate = DateTime.now(); // New variable to hold selected date

  bool areTextFieldsNotEmpty() {
    return nameController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        dobController.text.isNotEmpty;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Set primary color
              onPrimary: Colors.white, // Set text color on primary color
              surface: Colors.white, // Set background color
              onSurface: Colors.black, // Set text color on background color
            ),
            dialogBackgroundColor: Colors.white, // Set dialog background color
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
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
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create your account',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 190),
            TextField(
              controller: nameController,
              onChanged: (value) {
                setState(() {});
              },
              maxLength: 20,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Name',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              onChanged: (value) {
                setState(() {});
              },
              maxLength: 10, // Limit input to 15 characters (including country code)
              keyboardType: TextInputType.phone, // Set keyboard type to phone
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ], // Allow only digits
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: 'Phone number',
                prefixIcon: CountryCodePicker(
                  initialSelection: 'IN', // Initial selected country code
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                  favorite: const ['+91', 'IN'],
                  onChanged: (CountryCode? code) {
                    setState(() {
                      countryCode = code;
                    });
                    print('${code!.name}: ${code.dialCode}');
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                _selectDate(context);
              },
              child: IgnorePointer(
                child: TextField(
                  controller: dobController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Date of birth',
                    hintText: 'Date of birth',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 40,
        width: 80,
        child: FloatingActionButton.extended(
          onPressed: areTextFieldsNotEmpty()
              ? () {
            if (countryCode == null) {
              // Set default country code to India if not selected
              countryCode = CountryCode.fromCode('IN');
            }
            // Navigate to OTP validation page with user data
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (context) => OTPValidationPage(
                  countryCode: countryCode!.dialCode.toString(),
                  phoneNumber: phoneController.text.toString(), // Pass the phone number here
                  name: nameController.text.toString(),
                  dob: dobController.text.toString(),
                ),
              ),
            );
          }
              : null,
          elevation: 0,
          backgroundColor: areTextFieldsNotEmpty()
              ? Theme.of(context).colorScheme.tertiary
              : Colors.grey,
          label: Text(
            'Next',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
