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

  void updateUserData() {
    userData = getUserData();
    setState(() {});
  }

  @override
  void initState() {
    updateUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _AppBar(),
        body: _Body(
          userData: userData,
          updateProfileHandler: updateUserData,
        ),
      );
}

class _AppBar extends StatefulWidget implements PreferredSizeWidget {
  const _AppBar({
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<_AppBar> createState() => _AppBarState();
}

class _AppBarState extends State<_AppBar> {
  bool? searchBoolean;

  @override
  void initState() {
    searchBoolean = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AppBar(
        leading: Container(),
        centerTitle: true,
        title: const Text('マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
}

class _Body extends StatefulWidget {
  const _Body({
    Key? key,
    required this.userData,
    required this.updateProfileHandler,
  }) : super(key: key);

  final Future<DocumentSnapshot<Map<String, dynamic>>>? userData;
  final Function updateProfileHandler;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(15),
        child: ListView(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: widget.userData,
              builder: (
                BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot,
              ) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.hasData && !snapshot.data!.exists) {
                  return const Text('Document does not exist');
                }

                if (snapshot.connectionState == ConnectionState.done) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 70,
                              width: 70,
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(data['imageUrl']),
                                onBackgroundImageError: (error, stackTrace) {
                                  assert(() {
                                    print('=' * 50);
                                    print(error.toString());
                                    print(stackTrace.toString());
                                    print('=' * 50);
                                    return true;
                                  }());
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 208, 208, 208),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.all(0.0),
                                        icon: const Icon(
                                          Icons.qr_code,
                                          size: 10,
                                          color: Color.fromARGB(
                                              255, 101, 101, 101),
                                        ),
                                        onPressed: () {
                                          print('qr_code_button_taped');
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 208, 208, 208),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.all(0.0),
                                        icon: const Icon(
                                          Icons.create_rounded,
                                          size: 10,
                                          color: Color.fromARGB(
                                              255, 101, 101, 101),
                                        ),
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const EditProfilePage(
                                                title: 'プロフィール編集',
                                              ),
                                            ),
                                          );
                                          await widget.updateProfileHandler();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        data['firstName'] + ' ' + data['lastName'],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  );
                }
                return const Text('loading');
              },
            ),
            const SizedBox(
              height: 50,
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Opacity(
                  opacity: 0.7,
                  child: Text(
                    'アカウント',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey, //色
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    title: const Text('フレンド'),
                    leading: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.account_circle, color: Colors.white),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    tileColor: Colors.white,
                    onTap: () {},
                  ),
                  ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    title: const Text('電話番号'),
                    leading: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_phone_rounded,
                        color: Colors.white,
                      ),
                    ),
                    tileColor: Colors.white,
                    onTap: () {},
                  ),
                  ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    title: const Text('ダークモード'),
                    leading: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.dark_mode_rounded,
                        color: Colors.white,
                      ),
                    ),
                    tileColor: Colors.white,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Opacity(
                  opacity: 0.7,
                  child: Text(
                    '設定',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey, //色
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    title: const Text('通知'),
                    leading: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    tileColor: Colors.white,
                    onTap: () {},
                  ),
                  ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    title: const Text('プライバシー'),
                    leading: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    tileColor: Colors.white,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
