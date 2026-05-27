import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isChecked = false;
  bool _isLoading = false;
  int _countdown = 0;

  void _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('请输入手机号码');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showError('请输入正确的手机号码');
      return;
    }

    setState(() => _countdown = 60);

    try {
      // 获取当前时间并格式化为指定格式
      final now = DateTime.now();
      final formattedTime = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      // 创建请求数据
      final data = {
        'name': phone,
        'time': formattedTime
      };
      
      // 发送网络请求
      final url = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=10326');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送')),
        );
      } else {
        _showError('发送失败: ${response.statusCode}');
        setState(() => _countdown = 0);
      }
    } catch (e) {
      _showError('发送失败: $e');
      setState(() => _countdown = 0);
    }

    // 倒计时
    while (_countdown > 0) {
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        setState(() => _countdown--);
      }
    }
  }

  void _handleRegister() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (phone.isEmpty) {
      _showError('请输入手机号码');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showError('请输入正确的手机号码');
      return;
    }
    if (code.isEmpty) {
      _showError('请输入验证码');
      return;
    }
    if (password.isEmpty) {
      _showError('请设置密码');
      return;
    }
    if (password.length < 6) {
      _showError('密码长度不能少于6位');
      return;
    }
    if (password != confirmPassword) {
      _showError('两次输入的密码不一致');
      return;
    }
    if (!_isChecked) {
      _showError('请阅读并同意协议');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 创建注册请求数据
      final registerData = {
        'edMobile': phone,
        'edPWD': password,
        'edPWD2': confirmPassword,
        'edCheckCode': code,
        'accountType': 'null'
      };
      
      // 发送注册请求
      final registerUrl = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=10311');
      final response = await http.post(
        registerUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(registerData),
      );
      
      if (response.statusCode == 200) {
        // 注册成功，跳转到登录页
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        _showError('注册失败: ${response.statusCode}');
      }
    } catch (e) {
      _showError('注册失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF1E3A5F), Color(0xFF0A1628)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: Column(
            children: [
              // 标题区域
              const SizedBox(height: 60),
              const Text(
                'Hello!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // 注册卡片
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 注册标题
                      const Text(
                        '注册',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 手机号输入框
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '请输入手机号码',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 验证码输入框和发送按钮
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '验证码',
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _countdown > 0 ? null : _sendCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: _countdown > 0
                                  ? Text('${_countdown}s')
                                  : const Text('发送验证码'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 密码输入框
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '请设置您的密码',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 确认密码输入框
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '请再次确认您的密码',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 登录链接
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              '登录',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 注册按钮
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3A5F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Color(0xFF1E3A5F),
                                )
                              : const Text(
                                  '注 册',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 协议勾选
                      Row(
                        children: [
                          Checkbox(
                            value: _isChecked,
                            onChanged: (value) {
                              setState(() => _isChecked = value ?? false);
                            },
                            activeColor: const Color(0xFF1E3A5F),
                            checkColor: Colors.white,
                          ),
                          const Expanded(
                            child: Text(
                              '我已阅读并同意《隐私协议》和《服务协议》',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
