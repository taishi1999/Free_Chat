import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

import 'chat.dart';
import 'rooms.dart';
import 'util.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({
    super.key,
    required this.user,
    required this.listSelectedUsers,
  });

  final User user;
  final List<types.User> listSelectedUsers;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
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
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text('Add Group'),
        ),
        // 友達一覧を表示.
        body: StreamBuilder<List<types.Room>>(
          stream: getFriendListRoomStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(
                  bottom: 200,
                ),
                child: const Text('No friends'),
              );
            }

            // Roomタイプがdirectになっている部屋から自分を除外.
            final uid = FirebaseAuth.instance.currentUser!.uid;
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final roomRow = snapshot.data![index];
                final userRow = (uid == roomRow.users[0].id)
                    ? roomRow.users[1]
                    : roomRow.users[0];
                return UserRows(
                  userRow,
                  listSelectedUsers,
                );
              },
            );
          },
        ),
        floatingActionButton: _floatingActionButton(listSelectedUsers, context),
      );

  FloatingActionButton _floatingActionButton(
    List<types.User> listSelectedUsers,
    BuildContext context,
  ) {
    final navigator = Navigator.of(context);
    return FloatingActionButton(
      onPressed: () async {
        // 自身のユーザー名取得.
        final currentUser = await fetchUser(
          FirebaseFirestore.instance,
          FirebaseAuth.instance.currentUser!.uid,
          getFirebaseChatCoreConfig().usersCollectionName,
          role: types.Role.admin.toShortString(),
        );
        var groupName = getUserName(types.User.fromJson(currentUser));

        // グループメンバーの名前をグループのチャットルームの初期値にセット.
        for (final user in listSelectedUsers) {
          groupName += ', ${getUserName(user)}';
        }

        // グループのチャットルームの作成.
        final room = await FirebaseChatCore.instance.createGroupRoom(
          name: groupName,
          users: listSelectedUsers,
          imageUrl: 'https://i.pravatar.cc/300?u=${faker.internet.random}',
        );

        // グループのチャットルームへの遷移.
        navigator.pop();
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              room: room,
            ),
          ),
        );
      },
      tooltip: 'Add Group',
      child: const Icon(Icons.group_add),
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

class UserRows extends StatefulWidget {
  const UserRows(this.user, this.listSelectedUsers, {super.key});
  final types.User user;
  final List<types.User> listSelectedUsers;

  @override
  UserRowsState createState() => UserRowsState();
}

class UserRowsState extends State<UserRows> {
  bool isSelected = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          isSelected = !isSelected;
          final intIndex = widget.listSelectedUsers
              .lastIndexWhere((types.User user) => user.id == widget.user.id);
          if (intIndex < 0) {
            if (isSelected) {
              widget.listSelectedUsers.add(widget.user);
            } else {
              widget.listSelectedUsers.removeAt(intIndex);
            }
          }
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          color: (isSelected)
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.transparent,
          child: Row(
            children: [
              _buildAvatar(widget.user),
              Text(getUserName(widget.user)),
            ],
          ),
        ),
      );

  Widget _buildAvatar(types.User user) {
    final color = getUserAvatarNameColor(user);
    final hasImage = user.imageUrl != null;
    final name = getUserName(user);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        backgroundColor: hasImage ? Colors.transparent : color,
        backgroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
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
}
