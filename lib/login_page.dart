import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:foodorder/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LinearGradient loginGradient = const LinearGradient(
    colors: [Color(0xFF1E1E2E), Color(0xFF2C2F48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final Color cardColor = const Color(0xFF25273D);
  final Color buttonColor = const Color(0xFFC59B76);
  final Color textColor = const Color(0xFFEAEAEA);

  bool _staySignedIn = false;

  @override
  void initState() {
    super.initState();
    _loadStaySignedInPreference();
  }

  Future<void> _loadStaySignedInPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _staySignedIn = prefs.getBool('staySignedIn') ?? false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: loginGradient,
      ),
      child: FlutterLogin(
        logo: const AssetImage(
          'assets/logo.png',
        ),
        onLogin: _handleLogin,
        onSignup: _handleSignup,
        termsOfService: [
          TermOfService(
            id: "what",
            mandatory: true,
            text: "Eza el akel me2ref ne7na ma5asna",
          ),
        ],
        onRecoverPassword: _handleRecoverPassword,
        onSubmitAnimationCompleted: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const HomePage(),
          ));
        },
        theme: LoginTheme(
          primaryColor: Colors.transparent,
          accentColor: cardColor,
          cardTheme: CardTheme(
            color: cardColor,
          ),
          titleStyle: TextStyle(
            color: textColor,
            fontSize: 55,
            fontWeight: FontWeight.bold,
          ),
          bodyStyle: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
          textFieldStyle: TextStyle(
            color: textColor,
          ),
          buttonTheme: LoginButtonTheme(
            backgroundColor: buttonColor,
            splashColor: Colors.white24,
            highlightColor: Colors.white,
            elevation: 8,
          ),
          inputTheme: InputDecorationTheme(
            labelStyle: TextStyle(
              color: textColor,
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        loginAfterSignUp: !_staySignedIn,
      ),
    );
  }

  Future<String?> _handleLogin(LoginData data) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );

      if (_staySignedIn) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('staySignedIn', true);
      }

      return null;
    } catch (e) {
      return 'Nese el password ya 3abeet?';
    }
  }

  Future<String?> _handleSignup(SignupData data) async {
    if (!_isPasswordValid(data.password!)) {
      return 'Password must contain numbers and symbols.';
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: data.name!,
        password: data.password!,
      );
      return null;
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            return 'Email is already in use. Please use a different email address.';
          case 'weak-password':
            return 'Password is too weak. Please use a stronger password.';
          default:
            return 'Registration failed. Please try again later.';
        }
      } else {
        return 'Registration failed. Please try again later.';
      }
    }
  }

  bool _isPasswordValid(String password) {
    final numberRegex = RegExp(r'[0-9]');
    final symbolRegex = RegExp(r'[!@#$%^&*()]');

    return numberRegex.hasMatch(password) || symbolRegex.hasMatch(password);
  }

  Future<String?> _handleRecoverPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      return null;
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            return 'No user found with this email address.';
          default:
            return 'Password reset failed. Please try again later.';
        }
      } else {
        return 'Password reset failed. Please try again later.';
      }
    }
  }
}
