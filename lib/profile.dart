import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:example/rooms.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.uid,
    this.hasAppBar = true,
    this.hasBackButton = true,
  });
  final String uid;
  final bool hasAppBar;
  final bool hasBackButton;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Stream<QuerySnapshot<Map<String, dynamic>>> users =
      FirebaseFirestore.instance.collection('users').limit(20).snapshots();
  @override
  Widget build(BuildContext context) {
    final userData =
        FirebaseFirestore.instance.collection('users').doc(widget.uid).get();

    return widget.hasAppBar
        ? SafeArea(
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Color(0xff1d1c21),
                //title: Text('プロフィール'),
              ),
              body: _BodyContent(
                userData: userData,
                widget: widget,
                users: users,
                hasBackButton: widget.hasBackButton,
              ),
            ),
          )
        : _BodyContent(
            userData: userData,
            widget: widget,
            users: users,
            hasBackButton: widget.hasBackButton,
          );
  }
}

class _BodyContent extends StatelessWidget {
  const _BodyContent({
    super.key,
    required this.userData,
    required this.widget,
    required this.users,
    required this.hasBackButton,
  });

  final Future<DocumentSnapshot<Map<String, dynamic>>> userData;
  final ProfilePage widget;
  final Stream<QuerySnapshot<Map<String, dynamic>>> users;
  final bool hasBackButton;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
        child: FutureBuilder<DocumentSnapshot>(
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
              return Center(
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          hasBackButton
                              ? InkWell(
                                  child: Icon(Icons.arrow_back),
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.remove('uid');
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RoomsPage(),
                                      ),
                                    );
                                  },
                                )
                              : SizedBox.shrink(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 60,
                              width: 60,
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(data['imageUrl']),
                              ),
                            ),
                          ),
                          Text(
                            data['firstName'],
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            data['createdAt'] =
                                data['createdAt']?.millisecondsSinceEpoch;
                            data['id'] = widget.uid;
                            data['lastSeen'] =
                                data['lastSeen']?.millisecondsSinceEpoch;
                            data['updatedAt'] =
                                data['updatedAt']?.millisecondsSinceEpoch;
                            final user = types.User.fromJson(data);
                            final navigator = Navigator.of(context);
                            final room = await FirebaseChatCore.instance
                                .createRoom(user);

                            navigator.pop();
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) => const RoomsPage(),
                              ),
                            );
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  room: room,
                                ),
                              ),
                            );
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('uid');
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            fixedSize: Size.fromWidth(double.maxFinite),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text('+ フレンド追加'),
                        ),
                      ),
                      // Container(
                      //   alignment: Alignment.centerLeft,
                      //   padding: EdgeInsets.all(8.0),
                      //   child: const Text(
                      //     'おすすめ',
                      //     style: TextStyle(fontWeight: FontWeight.bold),
                      //   ),
                      // ),
                      // StreamBuilder(
                      //   stream: users,
                      //   builder: (
                      //     BuildContext context,
                      //     AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                      //         snapShot,
                      //   ) {
                      //     if (snapShot.hasData) {
                      //       List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      //           data = snapShot.data!.docs;
                      //       return SizedBox(
                      //         height: 160,
                      //         child: ListView.builder(
                      //           scrollDirection: Axis.horizontal,
                      //           itemCount: data.length,
                      //           itemBuilder: (context, index) => Card(
                      //             child: Container(
                      //               padding: EdgeInsets.all(10),
                      //               child: SizedBox(
                      //                 width: 100,
                      //                 child: Column(children: [
                      //                   Container(
                      //                     height: 15,
                      //                     alignment: Alignment.centerRight,
                      //                     child: const FittedBox(
                      //                       child: Icon(
                      //                         Icons.close,
                      //                         color: Colors.black26,
                      //                       ),
                      //                     ),
                      //                   ),
                      //                   Padding(
                      //                     padding: const EdgeInsets.only(
                      //                       top: 0,
                      //                       left: 8,
                      //                       right: 8,
                      //                       bottom: 8,
                      //                     ),
                      //                     child: CircleAvatar(
                      //                       backgroundImage: NetworkImage(
                      //                         data[index].data()['imageUrl'],
                      //                       ),
                      //                     ),
                      //                   ),
                      //                   Text(
                      //                     data[index].data()['firstName'],
                      //                     textAlign: TextAlign.center,
                      //                     overflow: TextOverflow.ellipsis,
                      //                     style: const TextStyle(
                      //                       fontWeight: FontWeight.bold,
                      //                       fontSize: 12,
                      //                     ),
                      //                   ),
                      //                   const SizedBox(
                      //                     height: 5,
                      //                   ),
                      //                   SizedBox(
                      //                     height: 26,
                      //                     child: ElevatedButton(
                      //                       style: ElevatedButton.styleFrom(
                      //                         primary: Colors.grey[200],
                      //                         onPrimary: Colors.black,
                      //                         elevation: 0,
                      //                         fixedSize: const Size.fromWidth(
                      //                           double.maxFinite,
                      //                         ),
                      //                         shape: RoundedRectangleBorder(
                      //                           borderRadius:
                      //                               BorderRadius.circular(13),
                      //                         ),
                      //                       ),
                      //                       onPressed: () {},
                      //                       child: const Text(
                      //                         '+ 追加',
                      //                         style: TextStyle(
                      //                           fontWeight: FontWeight.bold,
                      //                         ),
                      //                       ),
                      //                     ),
                      //                   ),
                      //                 ]),
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //       );
                      //     } else {
                      //       return Container();
                      //     }
                      //   },
                      // ),
                      // TextButton(
                      //   style: ButtonStyle(
                      //     foregroundColor:
                      //         MaterialStateProperty.resolveWith<Color?>(
                      //       (Set<MaterialState> states) {
                      //         return Colors.black54;
                      //       },
                      //     ),
                      //   ),
                      //   onPressed: () => {print('push TextButton')},
                      //   child: const Text(
                      //     'このアカウントを報告する',
                      //     style: TextStyle(fontWeight: FontWeight.bold),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
            }

            return Text("loading");
          },
        ),
      );
}
