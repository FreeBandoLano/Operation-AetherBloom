import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthTest extends StatefulWidget {
  const FirebaseAuthTest({Key? key}) : super(key: key);

  @override
  _FirebaseAuthTestState createState() => _FirebaseAuthTestState();
}

class _FirebaseAuthTestState extends State<FirebaseAuthTest> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _status = 'Testing Firebase connection...';
    });

    try {
      // Test if Firebase is initialized
      FirebaseApp app = Firebase.app();
      setState(() {
        _status = 'Firebase initialized: ${app.name}';
      });

      // Test auth instance
      FirebaseAuth auth = FirebaseAuth.instance;
      User? currentUser = auth.currentUser;
      setState(() {
        _status += '\nAuth instance created. Current user: ${currentUser?.email ?? 'None'}';
      });

    } catch (e) {
      setState(() {
        _status = 'Firebase connection error: $e';
      });
    }
  }

  Future<void> _testSignUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _status = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing sign up...';
    });

    try {
      UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        _status = 'Sign up successful! User: ${result.user?.email}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Sign up error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _status = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing sign in...';
    });

    try {
      UserCredential result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        _status = 'Sign in successful! User: ${result.user?.email}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Sign in error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignOut() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing sign out...';
    });

    try {
      await FirebaseAuth.instance.signOut();
      setState(() {
        _status = 'Sign out successful!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Sign out error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSignUp,
              child: const Text('Test Sign Up'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSignIn,
              child: const Text('Test Sign In'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSignOut,
              child: const Text('Test Sign Out'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testFirebaseConnection,
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 