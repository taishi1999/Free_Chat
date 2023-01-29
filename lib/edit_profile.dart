import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _lastNameController = TextEditingController();
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
        _lastNameController.text = documentSnapshot.get('lastName');
      } else {
        print('Document does not exist on the database');
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _selectImage() async {
      final PickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (PickedFile != null) {
        imageFile = File(PickedFile.path);
        isSelected = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.center,
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
                    children: [
                      Text('アイコン画像'),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 70,
                        width: 70,
                        child: InkWell(
                          onTap: () async {
                            await _selectImage();
                            setState(() {});
                          },
                          child: CircleAvatar(
                            backgroundImage: imageFile != null
                                ? Image.file(imageFile!).image
                                : NetworkImage(data['imageUrl']),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text('姓'),
                      TextField(
                        controller: _firstNameController,
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text('名'),
                      TextField(
                        controller: _lastNameController,
                      ),
                    ],
                  );
                }
                return Text('loading');
              },
            ),
            SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        isLoading = true;
                      });
                      Map<String, dynamic> data = {
                        'firstName': _firstNameController.text,
                        'lastName': _lastNameController.text,
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
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
              child: const Text(
                '更新',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
