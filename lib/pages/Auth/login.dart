import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'register.dart';
import 'forgot_password.dart';
import '../../utils/data_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isChecked = false;
  bool _isLoading = false;

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty) {
      _showError('请输入手机号码');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showError('请输入正确的手机号码');
      return;
    }
    if (password.isEmpty) {
      _showError('请输入密码');
      return;
    }
    if (!_isChecked) {
      _showError('请阅读并同意协议');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Starting login process');
      // 创建登录请求数据
      final loginData = {
        'name': phone,
        'pwd': password
      };
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Login data: $loginData');
      
      // 发送登录请求
      final loginUrl = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=10300');
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Request URL: $loginUrl');
      final response = await http.post(
        loginUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(loginData),
      );
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Response status code: ${response.statusCode}');
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Response body: ${response.body}');
      
      // 解析响应体
      Map<String, dynamic> responseData = {};
      try {
        responseData = json.decode(response.body);
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Parsed response data: $responseData');
      } catch (e) {
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Failed to parse response: $e');
        _showError('登录失败: 服务器响应格式错误');
        return;
      }
      
      // 检查业务错误码 - 处理可能的字符串类型
      dynamic codeValue = responseData['code'] ?? responseData['status'];
      int? businessCode;
      
      if (codeValue is int) {
        businessCode = codeValue;
      } else if (codeValue is String) {
        businessCode = int.tryParse(codeValue);
      }
      
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Code value: $codeValue, Business code: $businessCode');
      
      // 如果无法解析业务码，使用HTTP状态码作为备选
      if (businessCode == null) {
        businessCode = response.statusCode;
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Using HTTP status code as business code: $businessCode');
      }
      
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Checking business code for navigation');
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Current business code: $businessCode');
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Response data: $responseData');
      
      if (businessCode == 0) {
        // 业务上登录成功，跳转到首页
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Login successful condition met (business code 0)');
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Is mounted: $mounted');
        
        // 提取并保存 itsid
        bool saveSuccess = false;
        if (responseData.containsKey('itsid')) {
          String itsid = responseData['itsid'].toString();
          print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Extracted itsid: $itsid');
          saveSuccess = await DataStorage.saveItsid(itsid);
          print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Save itsid success: $saveSuccess');
        } else {
          print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@No itsid found in response');
        }
        
        if (mounted) {
          print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Attempting navigation to main page');
          try {
            // 尝试使用命名路由跳转，并传递保存状态
            await Navigator.pushReplacementNamed(
              context, 
              '/main',
              arguments: {'saveSuccess': saveSuccess}
            );
            print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Navigation completed successfully');
          } catch (navError) {
            print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Navigation error: $navError');
            // 如果命名路由失败，尝试打印可用路由
            print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Navigation failed, trying alternative approaches');
          }
        } else {
          print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Cannot navigate: widget is not mounted');
        }
      } else if (businessCode == 100) {
        // 业务上用户名或密码错误
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Login failed (business code 100): Invalid username or password');
        _showError('用户名或密码错误');
      } else {
        // 其他业务错误或未知情况
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Unknown business code: $businessCode');
        String errorMessage = responseData['desc'] ?? responseData['message'] ?? responseData['msg'] ?? '登录失败';
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Login failed with business code: $businessCode, message: $errorMessage');
        _showError(errorMessage);
      }
    } catch (e) {
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Login exception: $e');
      _showError('登录失败: $e');
    } finally {
      setState(() => _isLoading = false);
      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Login process completed');
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

              // 登录卡片
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
                      // 登录标题
                      const Text(
                        '登录',
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

                      // 密码输入框
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '请输入密码',
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

                      // 忘记密码和注册
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              '忘记密码',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              '注册',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 登录按钮
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
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
                                  '登 录',
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
