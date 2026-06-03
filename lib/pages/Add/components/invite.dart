import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/api/competition_api.dart';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/pages/VenueList/components/payment_page.dart';

class InviteForm extends StatefulWidget {
  const InviteForm({super.key});

  @override
  State<InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<InviteForm> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  double _participantCount = 4;
  int _selectedSkillLevel = 3;
  String _selectedGameType = '中式八球';
  String _selectedFeeMode = 'AA制';
  String _startTime = '选择时间';
  bool _depositChecked = false;
  bool _isSubmitting = false;
  String _submitMessage = '';

  // 约球类型转数字编码
  String _getGameTypeCode(String gameType) {
    switch (gameType) {
      case '中式八球':
        return '0';
      case '斯诺克':
        return '1';
      case '九球':
        return '2';
      case '六球':
        return '3';
      case '四球':
        return '4';
      case '其他':
      default:
        return '5';
    }
  }

  // 费用模式转数字编码
  String _getFeeModeCode(String feeMode) {
    switch (feeMode) {
      case 'AA制':
        return '0';
      case '败方付':
        return '1';
      case '胜方付':
        return '2';
      case '对方付':
        return '3';
      default:
        return '0';
    }
  }

  // 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 提交约球表单
  void _submitInvite() async {
    // 验证表单
    if (_locationController.text.isEmpty) {
      _showError('请输入活动地点');
      return;
    }
    if (_startTime == '选择时间') {
      _showError('请选择开始时间');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitMessage = '准备支付...';
    });

    try {
      int inviteid = await DataStorage.getAndIncrementPostId();
      
      // 先弹出支付界面
      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(inviteid: inviteid.toString()),
        ),
      );

      // 如果支付未成功或被取消，停止发布
      if (paymentResult != true) {
        setState(() {
          _isSubmitting = false;
          _submitMessage = '已取消支付，发布未完成';
        });
        return;
      }

      setState(() {
        _submitMessage = '支付成功，正在发布...';
      });

      final formData = {
        'location': _locationController.text, // 地点 varchar
        'note': _noteController.text, // 备注
        'participantCount': _participantCount.toInt(), // 参与人数 int
        'skillLevel': _selectedSkillLevel, // 等级要求 int
        'gameType': int.parse(_getGameTypeCode(_selectedGameType)), // 约球类型 int
        'feeMode': int.parse(_getFeeModeCode(_selectedFeeMode)), // 费用模式 int
        'inviteid': inviteid, // 帖子id int
        'invitetime': _startTime, // 时间 datetime（格式：YYYY-MM-DD 00:00:00）
      };

      // 调用接口代码直接写在该页 dart 文件里
      String? itsid = await DataStorage.loadItsid();
      final uri = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx').replace(queryParameters: {
        'mbid': '11801',
        'ituid': '118',
        if (itsid != null && itsid.isNotEmpty) 'itsid': itsid,
        'action': 'invite',
      });

      var request = http.Request('POST', uri);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
      request.body = jsonEncode(formData);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300 || [301, 302, 303, 307, 308].contains(response.statusCode)) {
        setState(() {
          _submitMessage = '发布成功！';
        });

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _submitMessage = '发布失败: 状态码 ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _submitMessage = '发布失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('发布约球'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. 活动地点
            _buildLocationInput(colorScheme),
            const SizedBox(height: 16),

            // 2. 日期选择
            _buildDatePicker(colorScheme),
            const SizedBox(height: 16),

            // 3. 参与人数
            _buildParticipantSlider(colorScheme),
            const SizedBox(height: 16),

            // 4. 球技要求
            _buildSkillLevelSelector(colorScheme),
            const SizedBox(height: 16),

            // 5. 约球类型
            _buildGameTypeSelector(colorScheme),
            const SizedBox(height: 16),

            // 6. 费用模式
            _buildFeeModeSelector(colorScheme),
            const SizedBox(height: 16),

            // 7. 活动备注
            _buildNoteInput(colorScheme),
            const SizedBox(height: 16),

            // 8. 保证金协议
            _buildDepositCheckbox(colorScheme),
            const SizedBox(height: 24),

            // 提交按钮
            _buildSubmitButton(colorScheme),
            
            // 提示消息
            if (_submitMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _submitMessage,
                  style: TextStyle(
                    color: _submitMessage.contains('成功') ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 活动地点输入
  Widget _buildLocationInput(ColorScheme colorScheme) {
    return TextField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: '活动地点',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
  }

  // 日期选择器
  Widget _buildDatePicker(ColorScheme colorScheme) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _startTime = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} 00:00:00');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _startTime,
                style: TextStyle(
                  fontSize: 18,
                  color: _startTime == '选择时间' ? Colors.grey[400] : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  // 参与人数滑块
  Widget _buildParticipantSlider(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('参与人数'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _participantCount,
                min: 2,
                max: 10,
                divisions: 8,
                onChanged: (value) {
                  setState(() => _participantCount = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_participantCount.toInt()}人',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 球技要求选择
  Widget _buildSkillLevelSelector(ColorScheme colorScheme) {
    final levels = ['不限', '新手', '业余', '业余进阶', '业余高手', '职业'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('球技要求'),
        const SizedBox(height: 8),
        Row(
          children: List.generate(levels.length, (index) {
            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() => _selectedSkillLevel = index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _selectedSkillLevel == index
                        ? colorScheme.primary
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    levels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedSkillLevel == index
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 约球类型选择
  Widget _buildGameTypeSelector(ColorScheme colorScheme) {
    final gameTypes = ['中式八球', '斯诺克', '九球', '六球', '四球', '其他'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('约球类型'),
        const SizedBox(height: 8),
        Row(
          children: List.generate(gameTypes.length, (index) {
            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() => _selectedGameType = gameTypes[index]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _selectedGameType == gameTypes[index]
                        ? colorScheme.primary
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    gameTypes[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedGameType == gameTypes[index]
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 费用模式选择
  Widget _buildFeeModeSelector(ColorScheme colorScheme) {
    final feeModes = ['AA制', '败方付', '胜方付', '对方付'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('费用模式'),
        const SizedBox(height: 8),
        Row(
          children: List.generate(feeModes.length, (index) {
            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() => _selectedFeeMode = feeModes[index]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _selectedFeeMode == feeModes[index]
                        ? colorScheme.primary
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    feeModes[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedFeeMode == feeModes[index]
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 活动备注输入
  Widget _buildNoteInput(ColorScheme colorScheme) {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: '活动备注（选填）',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
  }

  // 保证金协议勾选
  Widget _buildDepositCheckbox(ColorScheme colorScheme) {
    return Row(
      children: [
        Checkbox(
          value: _depositChecked,
          onChanged: (value) {
            setState(() => _depositChecked = value ?? false);
          },
        ),
        const SizedBox(width: 8),
        Text(
          '我已阅读并同意《约球服务协议》',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // 提交按钮
  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting || !_depositChecked ? null : _submitInvite,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('发布约球'),
      ),
    );
  }
}
