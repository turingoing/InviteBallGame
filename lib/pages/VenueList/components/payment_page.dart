import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';

class PaymentPage extends StatefulWidget {
  final String inviteid;

  const PaymentPage({super.key, required this.inviteid});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedPaymentMethod = 0; // 0: 微信, 1: 支付宝
  bool _isPaying = false;

  Future<void> _processPayment() async {
    setState(() {
      _isPaying = true;
    });

    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid != null && itsid.isNotEmpty) {
        final url = Uri.parse(
            'https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11807&itsid=$itsid');
        print('支付请求URL: $url');
        
        var request = http.Request('POST', url);
        request.headers['Content-Type'] = 'application/json';
        request.body = json.encode({
          'inviteid': widget.inviteid,
        });
        
        print('支付接口发送参数: ${request.body}');
        
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        print('支付接口响应状态码: ${response.statusCode}');
        print('支付接口响应内容: ${response.body}');

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('支付成功')),
            );
            // 支付成功后跳转回，带上成功标识
            Navigator.of(context).pop(true);
          }
        } else {
          // HTTP 状态码不是 200
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('支付失败：网络错误 ${response.statusCode}')),
            );
          }
        }
      }
    } catch (e) {
      print('支付接口调用异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('支付接口调用异常: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '支付确认',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // 支付内容与金额
            Center(
              child: Column(
                children: [
                  const Text(
                    '支付金额',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '￥10.00',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '支付内容：缴纳保证金',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '选择支付方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // 微信支付
            InkWell(
              onTap: () => setState(() => _selectedPaymentMethod = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wechat, color: Color(0xFF09B83E), size: 30),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('微信支付', style: TextStyle(fontSize: 16)),
                    ),
                    Icon(
                      _selectedPaymentMethod == 0
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _selectedPaymentMethod == 0
                          ? const Color(0xFF09B83E)
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            // 支付宝支付
            InkWell(
              onTap: () => setState(() => _selectedPaymentMethod = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Color(0xFF1677FF), size: 30),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('支付宝支付', style: TextStyle(fontSize: 16)),
                    ),
                    Icon(
                      _selectedPaymentMethod == 1
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _selectedPaymentMethod == 1
                          ? const Color(0xFF09B83E)
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // 支付按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _isPaying ? null : _processPayment,
                child: _isPaying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '支付',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
