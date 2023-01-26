import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  @override
  void initState() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final usersData = FirebaseFirestore.instance.collection('users').doc(uid);

    usersData.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        _imageController.text = documentSnapshot.get('imageUrl');
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final usersData = FirebaseFirestore.instance.collection('users').doc(uid);
    return Scaffold(
      appBar: AppBar(title: const Text('マイページ')),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: usersData.get(),
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
                      Text('画像'),
                      TextField(
                        controller: _imageController,
                      ),
                      Text('姓'),
                      TextField(
                        controller: _firstNameController,
                      ),
                      Text('名'),
                      TextField(
                        controller: _lastNameController,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({
                            'imageUrl': _imageController.text,
                            'firstName': _firstNameController.text,
                            'lastName': _lastNameController.text,
                          }).then((value) => Navigator.of(context).pop());
                        },
                        child: Text(
                          '更新',
                        ),
                      ),
                    ],
                  );
                }
                return Text('loading');
              },
            ),
          ],
        ),
      ),
    );
  }
}
