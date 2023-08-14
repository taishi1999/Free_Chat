import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_svg/flutter_svg.dart';
//import 'package:getwidget/getwidget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'chat.dart';
import 'rooms.dart';
import 'util.dart';
import 'dart:math';
import 'dart:io';

class GroupsPage extends StatefulWidget {
  GroupsPage({
    super.key,
    required this.user,
    required this.listSelectedUsers,
  });

  final User user;
  final List<types.User> listSelectedUsers;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final List<String> emojis = [
    '🐤',
    '🐔',
    '🐟',
    '🦐',
    '🌵',
    '🌴',
    '🧀',
    '🥑',
    '🍉',
    '🍍',
    '🥖',
    '🍡',
    '☁️',
    '🗻',
    '🌊',
    '🍟',
    '🗿',
    '🍻',
    '👺',
    '👊',
  ];

  final List<Color> backgroundColors = [
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.lightBlueAccent.shade100,
    Colors.yellow.shade600,
    //Colors.deepPurple.shade200,
    //Colors.brown.shade300,
    //Colors.grey.shade800,

    //Colors.teal.shade200,
    //Colors.blueGrey.shade300,
    //Colors.cyan.shade100,
    //Colors.indigo.shade100,
    //Colors.black12,
  ];

  final picker = ImagePicker();
  File? imageFile;
  bool isIconSelected = false;

  final Random random = Random();
  String randomEmoji = '';
  String colorString = '';
  String emojiUrl = '';
  late Color randomBackgroundColor;
  Color defaultBackgroundColor = Colors.black12;

  late TextEditingController _controller;
  String _inputText = '';

  bool isLoading = false;

  late int lastRemovedItemindex = -1;

  void setLoadingStatus(bool b) {
    setState(() {
      isLoading = b;
    });
  }

  void removeItemFromList(int index) {
    if (index >= 0) {
      widget.listSelectedUsers.removeAt(index);
      lastRemovedItemindex = index;
    }
    setState(() {});
  }

  @override
  void initState() {
    randomEmoji = emojis[Random().nextInt(emojis.length)];
    randomBackgroundColor =
        backgroundColors[Random().nextInt(backgroundColors.length)];
    // Colorを16進数形式の文字列に変換
    colorString = '#${randomBackgroundColor.value.toRadixString(16)}';
    emojiUrl = 'emoji/$randomEmoji/$colorString';

    _controller = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          isIconSelected = true;
        }
      } catch (e) {
        print("エラーです: $e");
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff1d1c21),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RoomsPage(),
              ),
            );
          },
        ),
        actions: [
          LoadingTextButton(
            widget.listSelectedUsers,
            emojiUrl,
            _inputText,
            isIconSelected,
            imageFile,
            isLoading,
            setLoadingStatus,
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'グループの設定',
          //'友達を選択',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // 友達一覧を表示.
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Stack(
                        children: [
                          SizedBox(
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
                                backgroundColor: imageFile == null
                                    ? randomBackgroundColor
                                    : defaultBackgroundColor,
                                backgroundImage: imageFile != null
                                    ? Image.file(imageFile!).image
                                    : null,
                                child: imageFile == null
                                    ? Text(
                                        randomEmoji,
                                        style: const TextStyle(
                                          fontSize: 40,
                                        ),
                                      )
                                    : null,
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
                                decoration: const BoxDecoration(
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
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (value) {
                          setState(() {
                            _inputText = value;
                          });
                        },
                        //textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24.0, // 文字の大きさを変更
                          fontWeight: FontWeight.bold, // 文字を太くする
                        ),
                        //cursorColor: Colors.black26,
                        decoration: const InputDecoration(
                          border: InputBorder.none, // 下線を消す
                          hintText: 'グループ名', // プレースホルダー
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.listSelectedUsers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: widget.listSelectedUsers
                        .map((selectedItem) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  widget.listSelectedUsers.remove(selectedItem);
                                });
                              },
                              child: Stack(
                                children: [
                                  Padding(
                                    key: ValueKey(selectedItem.id),
                                    padding: const EdgeInsets.all(8.0),
                                    child: UserAvatar(
                                      user: selectedItem,
                                      size: 24,
                                    ),
                                    // child: CircleAvatar(
                                    //   //listviewの再利用を防ぐ(追加、除去時の画像が再利用され不自然)

                                    //   // ここで各ユーザーの情報を使用してCircleAvatarをカスタマイズ
                                    //   backgroundImage: NetworkImage(
                                    //       selectedItem.imageUrl!),
                                    //   radius: 24,
                                    // ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        setState(() {
                                          widget.listSelectedUsers
                                              .remove(selectedItem);
                                        });
                                      },
                                      child: Container(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              // border: Border.all(
                                              //   width: 4,
                                              //   color: Colors.grey.shade50,
                                              // ),
                                              color: Colors.grey.shade800,

                                              shape: BoxShape.circle,
                                            ),
                                            child: const Align(
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<types.Room>>(
                  stream: getFriendListRoomStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(
                          bottom: 200,
                        ),
                        child: Center(child: const CircularProgressIndicator()),
                      );
                    }

                    // Roomタイプがdirectになっている部屋から自分を除外.
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '友達 ${snapshot.data!.length}',
                              style: TextStyle(
                                fontSize: 16,
                                //color: Colors.grey.shade800,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final roomRow = snapshot.data![index];
                              final userRow = (uid == roomRow.users[0].id)
                                  ? roomRow.users[1]
                                  : roomRow.users[0];
                              return UserRows(
                                isSelected:
                                    widget.listSelectedUsers.contains(userRow),
                                user: userRow,
                                onTap: () {
                                  setState(() {
                                    if (widget.listSelectedUsers
                                        .contains(userRow)) {
                                      widget.listSelectedUsers.remove(userRow);
                                    } else {
                                      widget.listSelectedUsers.add(userRow);
                                    }
                                  });
                                },
                                key: ValueKey(index),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          Center(
            child: isLoading ? const CircularProgressIndicator() : null,
          ),
        ],
      ),
      //floatingActionButton: _floatingActionButton(listSelectedUsers, context),
    );
  }
}

// Roomタイプがdirectになっているroomを取得.
Stream<List<types.Room>> getFriendListRoomStream({
  bool orderByUpdatedAt = false,
}) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return const Stream.empty();

  final collection = orderByUpdatedAt
      ? FirebaseFirestore.instance
          .collection('rooms')
          .where('type', isEqualTo: types.RoomType.direct.toShortString())
          .where('userIds', arrayContains: currentUser.uid)
          .orderBy('updatedAt', descending: true)
      : FirebaseFirestore.instance
          .collection('rooms')
          .where('type', isEqualTo: types.RoomType.direct.toShortString())
          .where('userIds', arrayContains: currentUser.uid);

  return collection.snapshots().asyncMap(
        (query) => processRoomsQuery(
          currentUser,
          FirebaseFirestore.instance,
          query,
          getFirebaseChatCoreConfig().usersCollectionName,
        ),
      );
}

class LoadingTextButton extends StatefulWidget {
  const LoadingTextButton(
    //required this.onPressed,
    this.listSelectedUsers,
    this.emojiUrl,
    this.inputText,
    this.isIconSelected,
    this.imageFile,
    this.isLoading,
    this.setLoadingStatus, {
    super.key,
  });

  //final VoidCallback onPressed;
  final List<types.User> listSelectedUsers;
  final String emojiUrl;
  final String inputText;
  final bool isIconSelected;
  final File? imageFile;
  final bool isLoading;
  final Function(bool) setLoadingStatus;

  @override
  _LoadingTextButtonState createState() => _LoadingTextButtonState();
}

class _LoadingTextButtonState extends State<LoadingTextButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String groupName = '';
    return TextButton(
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
      onPressed: widget.isLoading
          ? null
          : () async {
              // setState(() {
              //   widget.isLoading = true;
              // });
              widget.setLoadingStatus(true);
              Map<String, dynamic> data = {};

              try {
                if (widget.inputText != '') {
                  groupName = widget.inputText;
                } else {
                  final currentUser = await fetchUser(
                    FirebaseFirestore.instance,
                    FirebaseAuth.instance.currentUser!.uid,
                    getFirebaseChatCoreConfig().usersCollectionName,
                    role: types.Role.admin.toShortString(),
                  );
                  groupName = getUserName(types.User.fromJson(currentUser));

                  // グループメンバーの名前をグループのチャットルームの初期値にセット.
                  for (final user in widget.listSelectedUsers) {
                    groupName += ', ${getUserName(user)}';
                  }
                }

                // グループのチャットルームの作成.
                final room = await FirebaseChatCore.instance.createGroupRoom(
                  name: groupName,
                  users: widget.listSelectedUsers,
                  imageUrl: widget.isIconSelected ? null : widget.emojiUrl,
                );

                if (widget.isIconSelected) {
                  final storageRef = FirebaseStorage.instance
                      .ref()
                      .child('group/${room.id}/imageUrl');
                  await storageRef.putFile(widget.imageFile!);

                  final uri = await storageRef.getDownloadURL();
                  data['imageUrl'] = uri;
                  await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(room.id)
                      .update(data);
                }

                final navigator = Navigator.of(context);

                // グループのチャットルームへの遷移.
                navigator.pop();
                await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      room: room,
                    ),
                  ),
                );
              } catch (e) {
                print('Error occurred: $e');
              } finally {
                if (mounted) {
                  widget.setLoadingStatus(false);
                  // setState(() {
                  //   isLoading = false;
                  // });
                }
              }
            },
      child: const Text(
        '作成',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class UserRows extends StatefulWidget {
  const UserRows({
    required this.isSelected,
    required this.user,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  final bool isSelected;

  final types.User user;

  final VoidCallback onTap;

  @override
  UserRowsState createState() => UserRowsState();
}

class UserRowsState extends State<UserRows> {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          widget.onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          color: Colors.transparent,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: UserAvatar(
                  user: widget.user,
                  size: 24,
                ),
              ),
              Expanded(
                child: Text(
                  getUserName(widget.user),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ), // Expanded widget is added here to make sure the row uses the maximum width available.
              widget.isSelected
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: SvgPicture.asset(
                        'images/check.svg',
                        //color: Colors.black,
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade400, width: 2),
                      ),
                    ),
            ],
          ),
        ),
      );
}

class UserAvatar extends StatelessWidget {
  final types.User user;
  final double size;

  const UserAvatar({super.key, required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = getUserAvatarNameColor(user);
    final hasImage = user.imageUrl != null;
    final name = getUserName(user);

    return CircleAvatar(
      backgroundColor: hasImage ? Colors.transparent : color,
      backgroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
      radius: size,
      child: !hasImage
          ? Text(
              name.isEmpty ? '' : name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            )
          : null,
    );
  }
}
