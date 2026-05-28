import 'package:flutter/material.dart';
import './Auth/login.dart';
import './Main/index.dart';
import '../utils/data_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      // 读取本地存储的 itsid
      String? itsid = await DataStorage.loadItsid();
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Loaded itsid: $itsid');

      if (itsid != null && itsid.isNotEmpty) {
        // 本地已存有 itsid，直接跳过登录，跳转到首页
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Local itsid exists, skipping login');
        _navigateToMain(autoLogin: true);
        return;
      }

      // 没有 itsid，跳转到登录页
      _navigateToLogin();
    } catch (e) {
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Auto login error: $e');
      // 发生错误，跳转到登录页
      _navigateToLogin();
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _navigateToMain({bool autoLogin = false}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainTabPage(autoLogin: autoLogin),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '约球',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _isChecking
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}