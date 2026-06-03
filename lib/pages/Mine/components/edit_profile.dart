import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  String _gender = '未知';
  String _birthday = '未知';
  String _location = '未知';
  String _avatarUrl = 'https://picsum.photos/200/200?random=user';
  List<String> _selectedStrengthTags = ['实力担当', '耐力持久'];
  List<String> _selectedSkillTags = ['技术流', '防守型'];

  static const String _uploadUrl = 'https://www.ruanzi.net/jy/go/phone.aspx';
  static const String _ituid = '118';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid == null || itsid.isEmpty) return;

      final url = Uri.parse('https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=07&itcid=11807&itsid=$itsid');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        Map<String, dynamic> userInfo = data;
        if (data is Map && data.containsKey('data')) {
          userInfo = data['data'];
        }

        setState(() {
          if (userInfo['username'] != null && userInfo['username'].toString().isNotEmpty) {
            _nicknameController.text = userInfo['username'].toString();
          }
          if (userInfo['headimg'] != null && userInfo['headimg'].toString().isNotEmpty) {
            _avatarUrl = 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/${userInfo['headimg']}';
          }
          if (userInfo['sex'] != null) {
            String sexStr = userInfo['sex'].toString();
            if (sexStr == '1') _gender = '男';
            else if (sexStr == '2') _gender = '女';
            else if (sexStr.isNotEmpty) _gender = sexStr;
          }
          if (userInfo['birthday'] != null && userInfo['birthday'].toString().isNotEmpty) {
            _birthday = userInfo['birthday'].toString();
          }
          if (userInfo['province'] != null || userInfo['city'] != null) {
            String prov = userInfo['province']?.toString() ?? '';
            String city = userInfo['city']?.toString() ?? '';
            String dist = userInfo['district']?.toString() ?? '';
            String loc = '$prov $city $dist'.trim();
            if (loc.isNotEmpty) {
              _location = loc;
            }
          }
          if (userInfo['introduction'] != null && userInfo['introduction'].toString().isNotEmpty) {
            _bioController.text = userInfo['introduction'].toString();
          }
        });
      }
    } catch (e) {
      print('获取用户信息失败: $e');
    }
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadAvatarImage(File imageFile, String itsid) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileExtension = imageFile.path.split('.').last;
      final imageName = '${timestamp}_${DateTime.now().microsecond}.$fileExtension';

      final uploadUri = Uri.parse(_uploadUrl).replace(queryParameters: {
        'mbid': '5015',
        'ituid': _ituid,
        if (itsid.isNotEmpty) 'itsid': itsid,
      });

      final uploadRequest = http.MultipartRequest('POST', uploadUri);
      uploadRequest.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageName,
        ),
      );
      uploadRequest.fields['filepath'] = 'images\\singeravatar';
      uploadRequest.fields['filename1'] = imageName;
      uploadRequest.fields['url'] = imageName;
      uploadRequest.fields['postid'] = '0';

      final uploadStreamedResponse = await uploadRequest.send();
      final uploadResponse = await http.Response.fromStream(uploadStreamedResponse);

      if (uploadResponse.statusCode == 200) {
        return imageName;
      }
      return null;
    } catch (e) {
      print('❌ 上传头像异常: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      String? itsid = await DataStorage.loadItsid();
      String imageFileName = '';

      if (_avatarImage != null) {
        final uploadedImageName = await _uploadAvatarImage(
          _avatarImage!,
          itsid ?? '',
        );
        if (uploadedImageName != null) {
          imageFileName = uploadedImageName;
        }
      }

      final updateUri = Uri.parse(_uploadUrl).replace(queryParameters: {
        'ituid': _ituid,
        'mbid': '11805',
        if (itsid != null && itsid.isNotEmpty) 'itsid': itsid,
      });

      final updateBody = <String, dynamic>{};
      if (_nicknameController.text.isNotEmpty) {
        updateBody['username'] = _nicknameController.text;
      }
      if (imageFileName.isNotEmpty) {
        updateBody['headimg'] = imageFileName;
      }

      final updateResponse = await http.post(
        updateUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(updateBody),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('资料保存成功')),
        );
      }
    } catch (e) {
      print('❌ 保存资料异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCCCCCC)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection(String title, List<String> tags, List<String> selectedTags) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedTags.remove(tag);
                    } else {
                      selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0033FF) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0033FF) : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '编辑个人资料',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              '保存',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isSaving ? Colors.grey : const Color(0xFF0033FF),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // 头像区域
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: _avatarImage != null
                          ? ClipOval(
                              child: Image.file(
                                _avatarImage!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            )
                          : ClipOval(
                              child: Image.network(
                                _avatarUrl,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person, size: 50, color: Colors.grey[400]);
                                },
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0033FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                '点击编辑更换头像',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 信息行
            _buildInfoRow('昵称', _nicknameController.text.isNotEmpty ? _nicknameController.text : '未知'),
            _buildInfoRow('性别', _gender),
            _buildInfoRow('生日', _birthday),
            _buildInfoRow('常住地', _location),
            // 我的水平
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFF0033FF), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '钻石段位',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '当前段位：钻石 III',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0033FF)),
                    ),
                    child: const Text(
                      '认证中',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0033FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 大师段位卡片
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '大师段位',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '解锁更多专属权益',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '立即解锁',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 个人简介
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '个人简介',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '介绍一下你的台球风格...',
                      hintStyle: TextStyle(color: Color(0xFF999999)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
            // 个性标签
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '个性标签',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  _buildTagSection('实力标签', ['实力担当', '稳健型', '进攻型', '技术流', '防守型'], _selectedStrengthTags),
                  _buildTagSection('能力标签', ['精准打击', '耐力持久', '心态稳定', '学习快', '善于配合'], _selectedSkillTags),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 注销账户
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  '注销账户',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF4444),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
