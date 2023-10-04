import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat.dart';
import 'firebase_options.dart';
import 'rooms.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final PendingDynamicLinkData? initialLink =
      await FirebaseDynamicLinks.instance.getInitialLink();
  if (initialLink != null) {
    final String? uidParam = initialLink!.link.queryParameters['uid'];

    if (uidParam != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uidParam);
    }
  }
  runApp(const MyApp());

  // FCM の通知権限リクエスト
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // トークンの取得
  final token = await messaging.getToken();
  print('🐯 FCM TOKEN: $token');

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // フォアグラウンドでメッセージが届いたときの処理を記述
    if (notification != null && android != null) {
      print('Message title: ${notification.title}');
      print('Message body: ${notification.body}');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Firebase Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // routes: {
        //   '/': (context) => MyHomePage(),
        //   // '/message': (context) => ExamplePage(
        //   //       roomId: 'roomId',
        //   //     ),
        // },
        home: const MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      String? roomId;
      if (message.data.containsKey('roomId')) {
        roomId = message.data['roomId'];
        // print('tapppp!!');
        // print('roomId: $roomId');
        navigateToChatPage(roomId!);

        // final room = getRoom(roomId!);

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ChatPage(
        //       room: room,
        //     ),
        //     //builder: (context) => ExamplePage(roomId: roomId!),
        //   ),
        // );
        //snavigatorKey.currentState!.pushNamed('/room/$roomId');
      } else {
        print('else');
      }
    });
  }

  Future<Map<String, dynamic>> fetchUser(
      FirebaseFirestore instance, String userId) async {
    final userDocument = await instance.collection('users').doc(userId).get();
    return userDocument.data()!;
  }

  Future<String> getOtherUserName(Map<String, dynamic>? roomData) async {
    final instance = FirebaseFirestore.instance;
    final userIds = List<String>.from(roomData?['userIds'] as List);
    final myUserId = FirebaseAuth.instance.currentUser!.uid;

    // Find the user that is not the current user
    final otherUserId = userIds.firstWhere((userId) => userId != myUserId);
    final otherUser = await fetchUser(instance, otherUserId);

    // Get the name of the other user
    final otherUserName = otherUser['firstName'];

    print('Other user name: $otherUserName');
    return otherUserName;
  }

  Future<types.Room> getRoom(String roomId) async {
    // Get a reference to the Firestore collection that contains the rooms
    final roomsCollection = FirebaseFirestore.instance.collection('rooms');

    // Get the document from the collection that has the specific room ID
    final roomDocument = await roomsCollection.doc(roomId).get();

    // Get the data from the document
    final roomData = roomDocument.data();

    var roomName = roomData?['name'];

    final roomTypeString = roomData?['type'];

    if (roomTypeString == "direct") {
      roomName = await getOtherUserName(roomData);
      print('otherUser: $roomName');
    }

    // if (roomTypeString == "direct") {
    //   try {
    //     final roomName = await getOtherUserName(roomData);

    //     // final otherUser = roomData!['users'].firstWhere(
    //     //   (u) => u['id'] != FirebaseAuth.instance.currentUser!.uid,
    //     // );
    //     print('otherUser: $roomName');

    //     //imageUrl = otherUser['imageUrl'] as String?;
    //     //roomName = '${otherUser['firstName'] ?? ''}';
    //   } catch (e) {
    //     // Do nothing if other user is not found, because he should be found.
    //     // Consider falling back to some default values.
    //   }
    // }

    print('id: $roomId, name: $roomName, type: $roomTypeString');

    types.RoomType roomType;

    switch (roomTypeString) {
      case 'group':
        roomType = types.RoomType.group;
        break;
      case 'direct':
        roomType = types.RoomType.direct;
        break;
      default: // Handle other cases if needed
        throw Exception('Unknown room type');
    }

    if (roomData != null) {
      // Create the Room object
      final room = types.Room(
        //createdAt: roomData['createdAt'],
        id: roomId,
        imageUrl: roomData['imageUrl'] as String?,
        //lastMessages: roomData['lastMessages'] as List<types.Message>? ?? [],
        //metadata: roomData['metadata'] as Map<String, dynamic>? ?? {'exampleKey': 'exampleValue'},
        name: roomName,
        type: roomType,
        //updatedAt: roomData['updatedAt'],
        users: roomData['users'] as List<types.User>? ?? [],
      );

      return room;
    } else {
      throw Exception('Room with ID $roomId does not exist');
    }
  }

  Future<void> navigateToChatPage(String roomId) async {
    final room = await getRoom(roomId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          room: room,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    _initDynamicLinks();
    super.didChangeDependencies();
  }

  void _initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      if (dynamicLinkData != null) {
        final String? uidParam = dynamicLinkData!.link.queryParameters['uid'];

        if (uidParam != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('uid', uidParam);
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RoomsPage(),
            ),
          );
        }
      }
    }).onError((error) {
      print(error);
    });
  }

  @override
  Widget build(BuildContext context) => RoomsPage();
}

class ExamplePage extends StatelessWidget {
  final String roomId;

  ExamplePage({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example Page for Room $roomId'),
      ),
      body: Center(
        child: Text('This is the example page for room $roomId!'),
      ),
    );
  }
}
