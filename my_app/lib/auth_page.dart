import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'notification_channels_page.dart';



class AuthController {
  final BuildContext context;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
    'email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ]);
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String _verificationId = '';

  AuthController(this.context);

  Future<void> signInWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      analytics.logEvent(name: 'login_email', parameters: {'email': emailController.text});
      _navigateToChannels();
    } catch (e) {
      _showErrorDialog('Email Sign In Failed', e.toString());
    }
  }

  Future<void> signUpWithEmail() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      analytics.logEvent(name: 'signup_email', parameters: {'email': emailController.text});
      _navigateToChannels();
    } catch (e) {
      _showErrorDialog('Email Sign Up Failed', e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      analytics.logEvent(name: 'login_google', parameters: {'email': googleUser.email});
      _navigateToChannels();
    } catch (e) {
      _showErrorDialog('Google Sign In Failed', e.toString());
    }
  }

  Future<void> verifyPhone() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _navigateToChannels();
      },
      verificationFailed: (FirebaseAuthException e) {
        _showErrorDialog('Phone Verification Failed', e.toString());
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _showSMSCodeDialog();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _showSMSCodeDialog() {
    final TextEditingController smsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter SMS Code'),
        content: TextField(
          controller: smsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'SMS Code'),
        ),
        actions: [
          TextButton(
            child: const Text('Verify'),
            onPressed: () async {
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: _verificationId,
                  smsCode: smsController.text,
                );
                await _auth.signInWithCredential(credential);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                _navigateToChannels();
              } 
              catch (e) {
                _showErrorDialog('SMS Verification Failed', e.toString());
              }
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _navigateToChannels() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NotificationChannelsPage()),
    );
  }
}