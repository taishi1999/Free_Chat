import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'util.dart';

class EditProfilePage extends StatefulWidget {
  final String title;

  const EditProfilePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  //final TextEditingController _lastNameController = TextEditingController();
  final picker = ImagePicker();
  File? imageFile;
  bool isSelected = false;
  bool isLoading = false;
  String? uid;
  DocumentReference<Map<String, dynamic>>? userData;

  @override
  void initState() {
    uid = FirebaseAuth.instance.currentUser?.uid;
    userData = FirebaseFirestore.instance.collection('users').doc(uid);

    userData?.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        _firstNameController.text = documentSnapshot.get('firstName');
        //_lastNameController.text = documentSnapshot.get('lastName');
      } else {
        print('Document does not exist on the database');
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _selectImage() async {
      //final picker = ImagePicker();
      //PickedFile? pickedFile;
      try {
        //pickedFile = await picker.pickImage(source: ImageSource.gallery);
        final PickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (PickedFile != null) {
          imageFile = File(PickedFile.path);
          isSelected = true;
        }
      } catch (e) {
        print("エラーです: $e");
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff1d1c21),
        leading: IconButton(
          padding: EdgeInsets.all(0),
          icon: SvgPicture.asset(
            //'images/image.svg',
            'images/arrow_left.svg',
            width: 56,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        actions: [
          TextButton(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors
                      .transparent; // Use the color of your choice when pressed
                }
                return null; // Use the default value when not pressed
              }),
              splashFactory: NoSplash.splashFactory, // Disable splash
            ),
            onPressed: isLoading
                ? null
                : () async {
                    setState(() {
                      isLoading = true;
                    });
                    Map<String, dynamic> data = {
                      'firstName': _firstNameController.text,
                      //'lastName': _lastNameController.text,
                    };
                    try {
                      //アイコン画像を変更していたらcloud Storageへアップロードする
                      if (isSelected) {
                        final reference = FirebaseStorage.instance
                            .ref('users/${uid!}/imageUrl');
                        await reference.putFile(imageFile!);
                        final uri = await reference.getDownloadURL();
                        data['imageUrl'] = uri;
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update(data)
                          .then((value) {
                        Navigator.of(context).pop();
                      });
                    } catch (e) {
                      print(e);
                    } finally {
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  },
            child: Text(
              '完了',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        //alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: userData?.get(),
              builder: (
                BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot,
              ) {
                if (snapshot.hasError) {
                  return Text("Something went wrong");
                }

                if (snapshot.hasData && !snapshot.data!.exists) {
                  return Text("Document does not exist");
                }

                if (snapshot.connectionState == ConnectionState.done) {
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            child: SizedBox(
                              height: 70,
                              width: 70,
                              child: IconButton(
                                //iconSize: 70,
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  await _selectImage();
                                  setState(() {});
                                },
                                icon: CircleAvatar(
                                  radius: 35,
                                  backgroundImage: imageFile != null
                                      ? Image.file(imageFile!).image
                                      : NetworkImage(data['imageUrl']),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  // border: Border.all(
                                  //   width: 4,
                                  //   color: Colors.grey.shade50,
                                  // ),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      //offset: Offset(10, 10),
                                      blurRadius: 10.0,
                                      //spreadRadius: 1.0,
                                    ),
                                  ],
                                  shape: BoxShape.circle,
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    child: SvgPicture.asset(
                                      'images/edit_pen.svg',
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 32,
                      ),
                      Text(
                        '名前',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextField(
                        controller: _firstNameController,
                      ),
                      // SizedBox(
                      //   height: 30,
                      // ),
                      // Text('名'),
                      // TextField(
                      //   controller: _lastNameController,
                      // ),
                    ],
                  );
                }
                return Text('loading');
              },
            ),
            // SizedBox(
            //   height: 32,
            // ),
            // ElevatedButton(
            //   onPressed: isLoading
            //       ? null
            //       : () async {
            //           setState(() {
            //             isLoading = true;
            //           });
            //           Map<String, dynamic> data = {
            //             'firstName': _firstNameController.text,
            //             'lastName': _lastNameController.text,
            //           };
            //           try {
            //             //アイコン画像を変更していたらcloud Storageへアップロードする
            //             if (isSelected) {
            //               final reference = FirebaseStorage.instance
            //                   .ref('users/${uid!}/imageUrl');
            //               await reference.putFile(imageFile!);
            //               final uri = await reference.getDownloadURL();
            //               data['imageUrl'] = uri;
            //             }

            //             await FirebaseFirestore.instance
            //                 .collection('users')
            //                 .doc(uid)
            //                 .update(data)
            //                 .then((value) {
            //               Navigator.of(context).pop();
            //             });
            //           } catch (e) {
            //             print(e);
            //           } finally {
            //             setState(() {
            //               isLoading = false;
            //             });
            //           }
            //         },
            //   child: const Text(
            //     '更新',
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
