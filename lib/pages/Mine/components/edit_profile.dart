import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:city_pickers/city_pickers.dart';
import 'package:flutter_application_1/utils/location_service.dart';

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
  String _province = '';
  String _city = '';
  String _district = '';
  String _avatarUrl = 'https://picsum.photos/200/200?random=user';
  String _avatarFileName = '';
  
  // 标签相关
  final List<String> _strengthTags = ['实力担当', '稳健型', '进攻型', '技术流', '防守型'];
  final List<String> _skillTags = ['精准打击', '耐力持久', '心态稳定', '学习快', '善于配合'];
  List<String> _selectedTags = [];
  Set<String> _invalidFields = {};

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
            _avatarFileName = userInfo['headimg'].toString();
            _avatarUrl = 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$_avatarFileName';
          }
          if (userInfo['sex'] != null) {
            String sexStr = userInfo['sex'].toString().trim();
            if (sexStr == '1' || sexStr == '男') _gender = '男';
            else if (sexStr == '2' || sexStr == '女') _gender = '女';
            else if (sexStr == '3' || sexStr == '其他') _gender = '其他';
            else if (sexStr.isNotEmpty) _gender = sexStr;
          }
          if (userInfo['birthday'] != null && userInfo['birthday'].toString().isNotEmpty) {
            _birthday = userInfo['birthday'].toString();
          }
          if (userInfo['province'] != null || userInfo['city'] != null) {
            _province = userInfo['province']?.toString() ?? '';
            _city = userInfo['city']?.toString() ?? '';
            _district = userInfo['district']?.toString() ?? '';
            String loc = '$_province $_city $_district'.trim();
            if (loc.isNotEmpty) {
              _location = loc;
            }
          }
          if (userInfo['tags'] != null && userInfo['tags'].toString().isNotEmpty) {
            _selectedTags = userInfo['tags'].toString().split(',').where((t) => t.isNotEmpty).toList();
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
        _invalidFields.remove('avatar');
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
    // 验证逻辑
    setState(() {
      _invalidFields.clear();
      if (_nicknameController.text.trim().isEmpty) _invalidFields.add('nickname');
      if (_gender == '未知') _invalidFields.add('gender');
      if (_birthday == '未知') _invalidFields.add('birthday');
      if (_province.isEmpty || _city.isEmpty || _district.isEmpty) _invalidFields.add('location');
      if (_bioController.text.trim().isEmpty) _invalidFields.add('introduction');
      if (_selectedTags.isEmpty) _invalidFields.add('tags');
      if (_avatarImage == null && _avatarFileName.isEmpty) _invalidFields.add('avatar');
    });

    if (_invalidFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完善所有必填信息')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? itsid = await DataStorage.loadItsid();
      String imageFileName = _avatarFileName; // 默认使用旧头像文件名

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
        'mbid': '11809', // 修改为 11809
        if (itsid != null && itsid.isNotEmpty) 'itsid': itsid,
      });

      final updateBody = <String, dynamic>{
        "usernamecn": _nicknameController.text,
        "headimg": imageFileName,
        "sex": _gender,
        "birthday": _birthday == '未知' ? '' : _birthday,
        "province": _province,
        "city": _city,
        "district": _district,
        "introduction": _bioController.text,
        "tags": _selectedTags.join(','),
      };

      final updateResponse = await http.post(
        updateUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(updateBody),
      );

      if (mounted) {
        if (updateResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('资料保存成功')),
          );
          Navigator.pop(context, true); // 返回上一页并标记已更新
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: ${updateResponse.statusCode}')),
          );
        }
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

  void _showNicknameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: _nicknameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请输入新昵称'),
          maxLength: 20,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (_nicknameController.text.trim().isNotEmpty) {
                _invalidFields.remove('nickname');
              }
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['男', '女', '其他'].map((g) => ListTile(
          title: Text(g, textAlign: TextAlign.center),
          onTap: () {
            setState(() {
              _gender = g;
              _invalidFields.remove('gender');
            });
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday == '未知' ? DateTime(2000) : (DateTime.tryParse(_birthday) ?? DateTime(2000)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthday = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _invalidFields.remove('birthday');
      });
    }
  }

  Future<void> _showLocationPicker() async {
    Result? result = await CityPickers.showCityPicker(
      context: context,
      theme: Theme.of(context).copyWith(primaryColor: const Color(0xFF0033FF)),
      locationCode: '110000', // 默认北京，或者可以根据当前已选 code 设置
    );

    if (result != null) {
      setState(() {
        _province = result.provinceName ?? '';
        _city = result.cityName ?? '';
        _district = result.areaName ?? '';
        _location = '$_province $_city $_district'.trim();
        if (_location.isEmpty) {
          _location = '未知';
        } else {
          // 只要选了，就认为有效（CityPickers 保证了层级完整性）
          _invalidFields.remove('location');
        }
      });
    }
  }

  Future<void> _autoLocation() async {
    // 显示加载提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在获取当前位置...'), duration: Duration(seconds: 1)),
    );

    LocationResult? address = await LocationService.getCurrentAddress();
    if (address != null) {
      setState(() {
        _province = address.province;
        _city = address.city;
        _district = address.district;
        
        // 拼接完整地址显示，如果是直辖市，省和市的名字相同，可以去重显示
        if (_province == _city) {
          _location = '$_city $_district'.trim();
        } else {
          _location = '$_province $_city $_district'.trim();
        }
        
        if (_location.isEmpty) {
          _location = '未知';
        } else {
          _invalidFields.remove('location');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('定位成功：$_location')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定位失败，请检查定位服务和权限')),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap, String? fieldKey, Widget? suffix}) {
    final bool hasError = fieldKey != null && _invalidFields.contains(fieldKey);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: hasError ? Colors.red.withOpacity(0.05) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: hasError ? Colors.red : Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: hasError ? Colors.red : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                if (suffix != null) ...[
                  suffix,
                  const SizedBox(width: 8),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: hasError ? Colors.red : const Color(0xFF666666),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: hasError ? Colors.red : const Color(0xFFCCCCCC),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection(String title, List<String> tags, {String? fieldKey}) {
    final bool hasError = fieldKey != null && _invalidFields.contains(fieldKey);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: hasError ? Border.all(color: Colors.red, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: hasError ? Colors.red : const Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      if (_selectedTags.length >= 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('最多只能选择4个标签')),
                        );
                        return;
                      }
                      _selectedTags.add(tag);
                    }
                    if (_selectedTags.isNotEmpty) {
                      _invalidFields.remove('tags');
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0033FF) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0033FF) : (hasError ? Colors.red[200]! : Colors.grey[300]!),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : (hasError ? Colors.red : const Color(0xFF666666)),
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
                        border: Border.all(
                          color: _invalidFields.contains('avatar') ? Colors.red : Colors.grey[300]!,
                          width: 2,
                        ),
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
                          color: _invalidFields.contains('avatar') ? Colors.red : const Color(0xFF0033FF),
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
            Center(
              child: Text(
                _invalidFields.contains('avatar') ? '请上传头像' : '点击编辑更换头像',
                style: TextStyle(
                  fontSize: 14,
                  color: _invalidFields.contains('avatar') ? Colors.red : const Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 信息行
            _buildInfoRow('昵称', _nicknameController.text.isNotEmpty ? _nicknameController.text : '未知', onTap: _showNicknameDialog, fieldKey: 'nickname'),
            _buildInfoRow('性别', _gender, onTap: _showGenderPicker, fieldKey: 'gender'),
            _buildInfoRow('生日', _birthday, onTap: _showDatePicker, fieldKey: 'birthday'),
            _buildInfoRow(
              '常住地', 
              _location, 
              onTap: _showLocationPicker, 
              fieldKey: 'location',
              suffix: InkWell(
                 onTap: () {
                   _autoLocation();
                 },
                 child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0033FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.my_location, size: 18, color: Color(0xFF0033FF)),
                ),
              ),
            ),
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
                color: _invalidFields.contains('introduction') ? Colors.red.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: _invalidFields.contains('introduction') ? Border.all(color: Colors.red, width: 1) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '个人简介',
                    style: TextStyle(
                      fontSize: 14,
                      color: _invalidFields.contains('introduction') ? Colors.red : const Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 20,
                    onChanged: (val) {
                      if (val.trim().isNotEmpty) {
                        setState(() => _invalidFields.remove('introduction'));
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: '介绍一下你的台球风格...',
                      hintStyle: TextStyle(color: Color(0xFF999999)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      counterText: "", // 隐藏默认的计数器，如果需要显示可以去掉这行
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
                  _buildTagSection('实力标签', _strengthTags, fieldKey: 'tags'),
                  _buildTagSection('能力标签', _skillTags, fieldKey: 'tags'),
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
