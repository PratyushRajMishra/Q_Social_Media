import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  File? _imageFile;
  String? _userProfilePictureUrl;
  bool _isLoadingUserData = true;
  bool _isSaving = false;
  bool _changesMade = false; // Track if any changes are made

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _dobController = TextEditingController();
    _locationController = TextEditingController();
    _websiteController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // Function to handle changes in text fields
  void _handleTextChanges() {
    setState(() {
      _changesMade = true; // Set changesMade to true
    });
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userData.exists) {
          String name = userData['name'] ?? '';
          String bio = userData['bio'] ?? '';
          String dob = userData['dob'] ?? '';
          String location = userData['location'] ?? '';
          String website = userData['website'] ?? '';
          _nameController.text = name;
          _bioController.text = bio;
          _dobController.text = dob;
          _locationController.text = location;
          _websiteController.text = website;

          // Set the user's profile picture URL
          _userProfilePictureUrl = userData['profile'];
        } else {
          // User document doesn't exist, initialize controllers with default values
          _nameController.text = '';
          _bioController.text = '';
          _dobController.text = '';
          _locationController.text = '';
          _websiteController.text = '';
        }
        setState(() {
          _isLoadingUserData = false; // Set loading indicator to false
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoadingUserData =
            false; // Set loading indicator to false in case of error
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _userProfilePictureUrl =
              pickedFile.path; // Update with local file path
        });
        // Call function to update the profile picture URL
        _updateProfilePicture(_userProfilePictureUrl!);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveChanges() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _isSaving = true; // Set _isSaving to true to show progress indicator
        });

        String? imageUrl =
            _userProfilePictureUrl; // Keep the existing URL if no new image is selected
        if (_imageFile != null) {
          String imageName = '${user.uid}_profile.jpg';
          Reference storageReference =
              FirebaseStorage.instance.ref().child('profile').child(imageName);
          UploadTask uploadTask = storageReference.putFile(_imageFile!);
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
          imageUrl = await taskSnapshot.ref.getDownloadURL();
        }

        // Update user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'dob': _dobController.text,
          'location': _locationController.text,
          'website': _websiteController.text,
          'profile': imageUrl,
          // Add other fields if needed
        });

        // After changes are saved, reset _isSaving and update button text
        setState(() {
          _isSaving = false;
        });

        print('Changes saved successfully');
      }
    } catch (e) {
      print('Error saving changes: $e');
      // In case of error, reset _isSaving
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Function to update the user's profile picture URL
  void _updateProfilePicture(String newProfilePictureUrl) {
    setState(() {
      _userProfilePictureUrl = newProfilePictureUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Edit profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: _isLoadingUserData
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.photo_library),
                                  title: Text('Choose from gallery'),
                                  onTap: () {
                                    _pickImage(ImageSource.gallery);
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.camera_alt),
                                  title: Text('Take a picture'),
                                  onTap: () {
                                    _pickImage(ImageSource.camera);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.transparent,
                      child: _userProfilePictureUrl != null
                          ? _userProfilePictureUrl!.startsWith('http')
                          ? CachedNetworkImage(
                        imageUrl: _userProfilePictureUrl!,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          backgroundImage: imageProvider,
                          radius: 70,
                        ),
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.error,
                          size: 100,
                        ),
                      )
                          : CircleAvatar(
                        backgroundImage: FileImage(File(_userProfilePictureUrl!)),
                        radius: 70,
                      )
                          : Icon(
                        Icons.account_circle, // Icon to display when no profile picture is available
                        size: 150,
                      ),
                    ),

                  ),
                  SizedBox(height: 40),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    maxLines: null,
                    onChanged: (value) => _handleTextChanges(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bioController,
                    maxLines: null,
                    decoration: InputDecoration(labelText: 'Bio'),
                    maxLength: 100,
                    onChanged: (value) => _handleTextChanges(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _dobController,
                    decoration: InputDecoration(labelText: 'Date of Birth'),
                    keyboardType: TextInputType.datetime,
                    onChanged: (value) => _handleTextChanges(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    maxLength: 20,
                    controller: _locationController,
                    decoration: InputDecoration(labelText: 'Location'),
                    onChanged: (value) => _handleTextChanges(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _websiteController,
                    decoration: InputDecoration(labelText: 'Website'),
                    keyboardType: TextInputType.url,
                    onChanged: (value) => _handleTextChanges(),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isSaving || !_changesMade
                          ? null
                          : _saveChanges, // Disable button while saving
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Theme.of(context)
                                .colorScheme
                                .secondary; // Change to secondary color when disabled
                          }
                          return Theme.of(context)
                              .colorScheme
                              .tertiary; // Use tertiary color when enabled
                        }),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Updating...',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary,
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ) // Show progress indicator when saving
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontSize: 16,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
