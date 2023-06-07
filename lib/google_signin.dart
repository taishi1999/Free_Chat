import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

class GoogleSignin extends StatelessWidget {
  const GoogleSignin({Key? key}) : super(key: key);

  // ↓ここから公式の処理を丸パクリ
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    await FirebaseChatCore.instance.createUserInFirestore(
      types.User(
        firstName: userCredential.user!.displayName,
        id: userCredential.user!.uid,
        imageUrl: googleUser?.photoUrl ?? '',
        //lastName: _lastName,
      ),
    );

    // Once signed in, return the UserCredential
    return userCredential;
  }
  // ↑ここまで公式の処理を丸パクリ

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // ボタンの背景色を変更
        backgroundColor: Colors.white,
      ),
      onPressed: () async {
        // サインイン画面を表示する
        final credential = await signInWithGoogle();

        // サインイン後に表示する画面を指定する
        // Navigator.push(context,
        //     MaterialPageRoute(builder: (context) => const CatList()));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: NetworkImage(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/588px-Google_%22G%22_Logo.svg.png?20230305195327'),
              width: 16,
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Login with Google',
                style: TextStyle(
                    color: Colors.black,
                    //fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
