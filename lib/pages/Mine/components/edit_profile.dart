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
  final TextEditingController _usernameController = TextEditingController();
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  static const String _uploadUrl = 'https://www.ruanzi.net/jy/go/phone.aspx';
  static const String _ituid = '118';

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

      print('========== 上传头像请求 ==========');
      print('📌 请求URL: $uploadUri');
      print('📌 服务端文件名: $imageName');

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

      print('📌 上传头像响应状态: ${uploadResponse.statusCode}');
      print('📌 上传头像响应内容: ${uploadResponse.body}');

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
    final username = _usernameController.text.trim();

    if (_avatarImage == null || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请同时上传头像并填写用户名')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? itsid = await DataStorage.loadItsid();
      String imageFileName = '';

      // 第一步：上传头像图片（mbid=5015）
      if (_avatarImage != null) {
        final uploadedImageName = await _uploadAvatarImage(
          _avatarImage!,
          itsid ?? '',
        );
        if (uploadedImageName == null || uploadedImageName.isEmpty) {
          throw Exception('头像上传失败');
        }
        imageFileName = uploadedImageName;
      }

      // 第二步：上传用户名和头像文件名（mbid=11805）
      final updateUri = Uri.parse(_uploadUrl).replace(queryParameters: {
        'ituid': _ituid,
        'mbid': '11805',
        if (itsid != null && itsid.isNotEmpty) 'itsid': itsid,
      });

      final updateBody = <String, dynamic>{};
      if (username.isNotEmpty) {
        updateBody['username'] = username;
      }
      if (imageFileName.isNotEmpty) {
        updateBody['headimg'] = imageFileName;
      }

      print('========== 更新资料请求 ==========');
      print('📌 请求URL: $updateUri');
      print('📌 请求Body: ${jsonEncode(updateBody)}');

      final updateResponse = await http.post(
        updateUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(updateBody),
      );

      print('📌 更新资料响应状态: ${updateResponse.statusCode}');
      print('📌 更新资料响应内容: ${updateResponse.body}');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '编辑资料',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // 上传头像组件
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
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
                                width: 120,
                                height: 120,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2962FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '点击更换头像',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 40),
              // 用户名输入框
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _usernameController,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    hintText: '请输入用户名',
                    hintStyle: TextStyle(color: Color(0xFF999999)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              const Spacer(),
              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '保存',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
