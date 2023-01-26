import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? userData;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    final uid = await FirebaseAuth.instance.currentUser?.uid;
    final userData =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userData;
  }

  @override
  void initState() {
    userData = getUserData();
    super.initState();
  }

  @override
  // ignore: prefer_expression_function_bodies
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(
                    title: 'マイページ',
                  ),
                ),
              );
              userData = getUserData();
              setState(() {});
            },
            child: Icon(
              Icons.create_outlined,
            ),
          ),
        ],
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: userData,
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
                      CircleAvatar(
                        backgroundImage: NetworkImage(data['imageUrl']),
                      ),
                      Text(
                        data['firstName'] + ' ' + data['lastName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  );
                }
                return Text("loading");
              },
            ),
          ],
        ),
      ),
    );
  }
}
