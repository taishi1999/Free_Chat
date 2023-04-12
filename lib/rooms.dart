import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

import 'chat.dart';
import 'login.dart';
import 'my_page.dart';
import 'users.dart';
import 'util.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  bool _error = false;
  bool _initialized = false;
  User? _user;
  bool _searchBoolean = false;
  Future<DocumentSnapshot<Map<String, dynamic>>>? userData;

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    userData = FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container();
    }

    if (!_initialized) {
      return Container();
    }

    return Scaffold(
      appBar: _AppBar(
        title: 'メッセージ',
        userData: userData,
      ),
      body: _user != null ? _displayRoomList() : _navigatLogin(context),
      floatingActionButton: _FloatingActionButton(
        user: _user,
      ),
    );
  }

  void initializeFlutterFire() async {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        setState(() {
          _user = user;
        });
      });
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // 未ログイン時のログインページへの遷移.
  Widget _navigatLogin(BuildContext context) => Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(
          bottom: 200,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Not authenticated'),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );

  // アイコンの表示.
  Widget _buildAvatar(types.Room room) {
    var color = Colors.transparent;

    if (room.type == types.RoomType.direct) {
      try {
        final otherUser = room.users.firstWhere(
          (u) => u.id != _user!.uid,
        );

        color = getUserAvatarNameColor(otherUser);
      } catch (e) {
        // Do nothing if other user is not found.
      }
    }

    final hasImage = room.imageUrl != null;
    final name = room.name ?? '';

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        backgroundColor: hasImage ? Colors.transparent : color,
        backgroundImage: hasImage ? NetworkImage(room.imageUrl!) : null,
        onBackgroundImageError: (error, stackTrace) {
          assert(() {
            print('=' * 50);
            print(error.toString());
            print(stackTrace.toString());
            print('=' * 50);
            return true;
          }());
        },
        radius: 20,
        child: !hasImage
            ? Text(
                name.isEmpty ? '' : name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
    );
  }

  // Room一覧の表示.
  Widget _displayRoomList() => StreamBuilder<List<types.Room>>(
        stream: FirebaseChatCore.instance.rooms(),
        initialData: const [],
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(
                bottom: 200,
              ),
              child: const Text('No rooms'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final room = snapshot.data![index];

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        room: room,
                      ),
                    ),
                  );
                },
                child: _displayRoom(room),
              );
            },
          );
        },
      );

  // 各Roomの表示.
  Widget _displayRoom(types.Room room) => StreamBuilder(
        stream: FirebaseChatCore.instance.messages(room, limit: 1),
        initialData: const [],
        builder: (context, snapshot) {
          final loaded = (snapshot.hasData && snapshot.data!.isNotEmpty);
          final types.Message? message = loaded ? snapshot.data![0] : null;
          return ListTile(
            leading: _buildAvatar(room),
            title: Text(
              room.name ?? '',
              maxLines: 1,
            ),
            trailing: Text(
              loaded ? getDateTimeRepresentation(message!.createdAt) : '',
            ),
            subtitle: Text(
              loaded
                  ? '${getUserName(message!.author)}:${_getDisplayMessage(message)}'
                  : '',
              maxLines: 1,
            ),
          );
        },
      );

  // メッセージの表示.
  String _getDisplayMessage(types.Message message) {
    if (message is types.TextMessage) {
      return message.text;
    } else {
      final currentUserIsAuthor = _user!.uid == message.author.id;
      final typeString = (message is types.ImageMessage) ? '画像' : 'ファイル';
      final actionString = (currentUserIsAuthor) ? '送信' : '受信';
      return '$typeStringを$actionStringしました。';
    }
  }
}

class _SearchTextField extends StatelessWidget {
  const _SearchTextField({
    Key? key,
    required this.title,
    this.searchBoolean = false,
  }) : super(key: key);

  final String title;
  final bool searchBoolean;

  @override
  Widget build(BuildContext context) => !searchBoolean
      ? Text(title)
      : const TextField(
          autofocus: true, //TextFieldが表示されるときにフォーカスする（キーボードを表示する）
          cursorColor: Colors.white, //カーソルの色
          style: TextStyle(
            //テキストのスタイル
            color: Colors.white,
            fontSize: 20,
          ),
          textInputAction: TextInputAction.search, //キーボードのアクションボタンを指定
          decoration: InputDecoration(
            //TextFiledのスタイル
            enabledBorder: UnderlineInputBorder(
              //デフォルトのTextFieldの枠線
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: UnderlineInputBorder(
              //TextFieldにフォーカス時の枠線
              borderSide: BorderSide(color: Colors.white),
            ),
            hintText: '友達、グループを検索', //何も入力してないときに表示されるテキスト
            hintStyle: TextStyle(
              //hintTextのスタイル
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
        );
}

class _AppBar extends StatefulWidget implements PreferredSizeWidget {
  const _AppBar({
    Key? key,
    required this.title,
    required this.userData,
  }) : super(key: key);

  final String title;
  final Future<DocumentSnapshot<Map<String, dynamic>>>? userData;

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
        actions: !searchBoolean!
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      searchBoolean = true;
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchBoolean = false;
                    });
                  },
                ),
              ],
        leading: InkWell(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MyPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  //final Offset begin = Offset(1.0, 0.0); // 右から左
                  final Offset begin = Offset(-1.0, 0.0); // 左から右
                  final Offset end = Offset.zero;
                  final Animatable<Offset> tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: Curves.easeInOut));
                  final Animation<Offset> offsetAnimation =
                      animation.drive(tween);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              ),
            );
          },
          child: FutureBuilder<DocumentSnapshot>(
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
                return Padding(
                  padding: const EdgeInsets.all(10.0),
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
                );
              }
              return const Text('loading');
            },
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        title: _SearchTextField(
          title: widget.title,
          searchBoolean: searchBoolean!,
        ),
      );
}

class _FloatingActionButton extends StatelessWidget {
  const _FloatingActionButton({
    Key? key,
    required this.user,
  }) : super(key: key);

  final User? user;

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        onPressed: user == null
            ? null
            : () async {
                var result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, //trueにしないと、Containerのheightが反映されない
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  builder: (BuildContext context) =>
                      Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(
                      title: const Text(
                        '追加',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(1),
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_reaction_outlined,
                          color: Colors.white,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      title: const Text(
                        '新しいフレンド',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => const UsersPage(),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups,
                          color: Colors.white,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      title: const Text(
                        'グループを作成',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(2),
                    ),
                  ]),
                );
                print('bottom sheet result: $result');
              },
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      );
}
