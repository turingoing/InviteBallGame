import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_application_1/utils/data_storage.dart';

class PublishPostPage extends StatefulWidget {
  const PublishPostPage({super.key});

  @override
  State<PublishPostPage> createState() => _PublishPostPageState();
}

class _PublishPostPageState extends State<PublishPostPage> {
  final TextEditingController _contentController = TextEditingController();
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPublishing = false;

  // 选择图片
  Future<void> _selectImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  // 移除图片
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 上传单张图片
  Future<String?> _uploadImage(File imageFile, String postid) async {
    try {
      // 生成唯一的文件名
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileExtension = imageFile.path.split('.').last;
      String imageName = '${timestamp}_${DateTime.now().microsecond}.$fileExtension';
      
      print('准备上传图片: ${imageFile.path}');
      print('生成的文件名: $imageName');
      
      // 构建请求URL（修正ituid参数为50）
      final url = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx?mbid=5015&ituid=118');
      print('请求URL: $url');
      
      // 构建multipart请求
      var request = http.MultipartRequest('POST', url);
      
      // 注意：不要手动设置content-type为application/x-www-form-urlencoded，
      // multipart请求会自动设置正确的Content-Type
      
      // 添加token头（如果需要）
      // request.headers['token'] = ''; // 实际应用中应该从存储中获取
      
      // 添加文件
      var file = await http.MultipartFile.fromPath(
        'file', // 字段名必须与服务器要求一致
        imageFile.path,
        filename: imageName,
      );
      request.files.add(file);
      print('添加文件到请求: ${file.field}, 文件名: ${file.filename}');
      
      // 添加formData参数（包含所有必要字段，与微信小程序代码一致）
      // 确保postid不为空
      String safePostid = postid.isNotEmpty ? postid : '0000';
      print('安全的postid值: $safePostid');
      
      request.fields['filepath'] = 'images\\singeravatar'; // 服务器存储目录
      request.fields['filename1'] = imageName; // 图片文件名
      request.fields['url'] = imageName; // 图片文件名
      request.fields['userid'] = '180272'; // 用户ID（静态设置）
      request.fields['postid'] = safePostid; // 帖子ID
      print('添加FormData: ${request.fields}');
      print('postid字段类型: ${request.fields['postid']?.runtimeType}');
      print('postid字段值长度: ${request.fields['postid']?.length}');
      
      // 发送请求前再次检查formData
      print('发送前的FormData完整内容:');
      request.fields.forEach((key, value) {
        print('  $key: "$value" (类型: ${value.runtimeType}, 长度: ${value.length})');
      });
      
      print('正在发送上传请求...');
      var response = await request.send();
      print('请求发送完成，状态码: ${response.statusCode}');
      
      // 处理响应
      String responseBody = await response.stream.bytesToString();
      print('响应内容: $responseBody');
      
      if (response.statusCode == 200) {
        print('图片上传成功');
        return request.fields['url'];
      } else {
        print('图片上传失败 (${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('图片上传异常: $e');
      _showError('图片上传失败: $e');
      return null;
    }
  }

  // 发送帖子基本信息
  Future<bool> _sendPostInfo(String postid, String content, String imgname) async {
    try {
      // 获取本地存储的 itsid
      String? itsid = await DataStorage.loadItsid();
      
      // 构建 URL，添加 itsid 参数
      String urlStr = 'https://www.ruanzi.net/jy/go/phone.aspx?mbid=5016&ituid=118';
      if (itsid != null && itsid.isNotEmpty) {
        urlStr += '&itsid=$itsid';
      }
      final url = Uri.parse(urlStr);
      
      // 获取当前时间，保留整数秒（datetime格式）
      DateTime now = DateTime.now();
      String time = now.toIso8601String().split('.')[0]; // 去掉毫秒部分
      
      // 构建请求数据，包含5个字段
      Map<String, dynamic> postData = {
        'location': '软子体育场', // 发布地点，静态写为'软子体育场'
        'time': time, // 发布时间，datetime格式（保留整数秒）
        'imgname': imgname, // 图片文件名
        'postid': int.parse(postid), // postid 转换为 int 类型
        'content': content, // 正文
      };
      
      print('发送帖子信息到: $url');
      print('帖子信息: $postData');
      
      // 发送请求
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );
      
      print('帖子信息发送结果: 状态码=${response.statusCode}, 响应内容=${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('发送帖子信息异常: $e');
      return false;
    }
  }

  // 发布动态
  void _publishPost() async {
    if (_contentController.text.trim().isEmpty) {
      _showError('请输入动态内容');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      int postid = await DataStorage.getAndIncrementPostId();
      print('当前帖子ID: $postid');
      
      List<String> uploadedImageUrls = [];
      int uploadSuccessCount = 0;
      int uploadFailCount = 0;
      
      // 步骤1：先上传所有选中的图片（如果有）
      if (_selectedImages.isNotEmpty) {
        _showError('正在上传图片...');
        
        // 验证postid是否有效
        if (postid <= 0) {
          print('错误：postid无效，无法上传图片');
          _showError('发布失败：帖子ID无效');
          return;
        }
        
        print('使用的帖子ID: $postid');
        
        for (int i = 0; i < _selectedImages.length; i++) {
          File imageFile = _selectedImages[i];
          print('正在上传第 ${i+1}/${_selectedImages.length} 张图片，使用postid: $postid');
          
          String? imageUrl = await _uploadImage(imageFile, postid.toString());
          if (imageUrl != null) {
            uploadedImageUrls.add(imageUrl);
            uploadSuccessCount++;
          } else {
            uploadFailCount++;
          }
        }
        
        print('图片上传完成: 成功 $uploadSuccessCount 张，失败 $uploadFailCount 张');
      }
      
      // 拼接图片文件名（用逗号分隔，如果没有图片则为空字符串）
      String imgname = uploadedImageUrls.join(',');
      
      _showError('正在发布动态...');
      
      // 步骤2：发送帖子基本信息（包含图片文件名）
      bool postInfoSent = await _sendPostInfo(postid.toString(), _contentController.text, imgname);
      
      if (!postInfoSent) {
        _showError('发布失败：无法发送帖子信息');
        return;
      }
      
      print('动态内容: ${_contentController.text}');
      print('上传的图片URL: $uploadedImageUrls');
      print('图片文件名: $imgname');
      print('帖子ID: $postid');
      
      // 发布成功，返回主页
      if (mounted) {
        String message = uploadFailCount > 0 
            ? '发布成功，但有 $uploadFailCount 张图片上传失败' 
            : '发布成功';
        _showError(message);
        
        // 延迟一小段时间再跳转，让用户看到提示
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        });
      }
    } catch (e) {
      _showError('发布失败: $e');
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  // 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        toolbarHeight: 45,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '发动态',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: TextButton(
              onPressed: _isPublishing ? null : _publishPost,
              child: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '发布',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
            ),
          ),
        ],
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文字输入区
            TextField(
              controller: _contentController,
              maxLines: 10,
              minLines: 5,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: '分享你的进球瞬间...',
                hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),

            // 图片选择区
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 上传图片按钮
            GestureDetector(
              onTap: _selectImages,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF5F5F5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      color: Color(0xFF9E9E9E),
                      size: 32,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '添加图片',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
