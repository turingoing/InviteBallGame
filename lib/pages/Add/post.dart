import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_application_1/pages/video_player_page.dart';
import 'dart:typed_data';

class SelectedMedia {
  final File file;
  final bool isVideo;
  final String? thumbnailPath;
  final Uint8List? thumbnailData; // 增加内存数据支持

  SelectedMedia({
    required this.file, 
    this.isVideo = false, 
    this.thumbnailPath,
    this.thumbnailData,
  });
}

class PublishPostPage extends StatefulWidget {
  const PublishPostPage({super.key});

  @override
  State<PublishPostPage> createState() => _PublishPostPageState();
}

class _PublishPostPageState extends State<PublishPostPage> {
  final TextEditingController _contentController = TextEditingController();
  List<SelectedMedia> _selectedMedia = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPublishing = false;

  // 生成视频缩略图 (尝试多种方式)
  Future<Map<String, dynamic>?> _generateThumbnail(String videoPath) async {
    try {
      print('正在为视频生成缩略图: $videoPath');
      
      // 方式1：尝试生成文件
      final String? path = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );

      if (path != null) {
        print('缩略图文件生成成功: $path');
        return {'path': path};
      }

      // 方式2：如果文件生成失败，尝试直接生成内存数据
      final Uint8List? data = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );

      if (data != null) {
        print('缩略图数据生成成功');
        return {'data': data};
      }
      
      return null;
    } catch (e) {
      print('生成缩略图异常: $e');
      return null;
    }
  }

  // 选择媒体文件（图片或视频）
  Future<void> _selectMedia() async {
    // 检查当前已选状态
    bool hasVideo = _selectedMedia.any((m) => m.isVideo);
    int imageCount = _selectedMedia.where((m) => !m.isVideo).length;

    // 弹出选择框
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF0500FA)),
                title: const Text('从相册选择图片'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF0500FA)),
                title: const Text('从相册选择视频'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    if (source == 'image') {
      if (hasVideo) {
        _showError('视频和图片不能同时发布');
        return;
      }
      if (imageCount >= 9) {
        _showError('最多只能选择9张图片');
        return;
      }

      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images != null && images.isNotEmpty) {
        // 限制总数不超过9张
        int remaining = 9 - imageCount;
        List<XFile> toAdd = images;
        if (images.length > remaining) {
          _showError('选择过多，仅保留前${remaining}张图片');
          toAdd = images.sublist(0, remaining);
        }

        setState(() {
          _selectedMedia.addAll(toAdd.map((image) => SelectedMedia(file: File(image.path))));
        });
      }
    } else if (source == 'video') {
      if (imageCount > 0) {
        _showError('视频和图片不能同时发布');
        return;
      }
      if (hasVideo) {
        _showError('最多只能选择1个视频');
        return;
      }

      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        _showError('正在处理视频...');
        
        final result = await _generateThumbnail(video.path);
        
        setState(() {
          _selectedMedia.add(SelectedMedia(
            file: File(video.path),
            isVideo: true,
            thumbnailPath: result?['path'],
            thumbnailData: result?['data'],
          ));
        });
      }
    }
  }

  // 移除媒体
  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  // 上传单个文件
  Future<String?> _uploadFile(File file, String postid, {bool isThumbnail = false}) async {
    try {
      // 生成唯一的文件名
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileExtension = file.path.split('.').last;
      String fileName = '${timestamp}_${DateTime.now().microsecond}_${isThumbnail ? "thumb" : "main"}.$fileExtension';
      
      print('准备上传文件: ${file.path}');
      print('生成的文件名: $fileName');
      
      // 构建请求URL
      final url = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx?mbid=5015&ituid=118');
      
      // 构建multipart请求
      var request = http.MultipartRequest('POST', url);
      
      // 添加文件
      var multipartFile = await http.MultipartFile.fromPath(
        'file', 
        file.path,
        filename: fileName,
      );
      request.files.add(multipartFile);
      
      // 添加formData参数
      String safePostid = postid.isNotEmpty ? postid : '0000';
      
      request.fields['filepath'] = 'images\\singeravatar'; 
      request.fields['filename1'] = fileName; 
      request.fields['url'] = fileName; 
      request.fields['userid'] = '180272'; 
      request.fields['postid'] = safePostid; 
      
      print('正在发送上传请求...');
      var response = await request.send();
      
      // 处理响应
      String responseBody = await response.stream.bytesToString();
      print('响应内容: $responseBody');
      
      if (response.statusCode == 200) {
        return request.fields['url'];
      } else {
        return null;
      }
    } catch (e) {
      print('文件上传异常: $e');
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
      
      List<String> uploadedFileUrls = [];
      int uploadSuccessCount = 0;
      int uploadFailCount = 0;
      
      // 步骤1：先上传所有选中的媒体（图片/视频/缩略图）
      if (_selectedMedia.isNotEmpty) {
        _showError('正在上传媒体文件...');
        
        // 验证postid是否有效
        if (postid <= 0) {
          print('错误：postid无效，无法上传媒体');
          _showError('发布失败：帖子ID无效');
          return;
        }
        
        print('使用的帖子ID: $postid');
        
        for (int i = 0; i < _selectedMedia.length; i++) {
          SelectedMedia media = _selectedMedia[i];
          print('正在上传第 ${i+1}/${_selectedMedia.length} 个媒体，类型: ${media.isVideo ? "视频" : "图片"}');
          
          // 如果是视频，先尝试上传缩略图（可选，这里我们把缩略图和视频都传上去）
          if (media.isVideo && media.thumbnailPath != null) {
             String? thumbUrl = await _uploadFile(File(media.thumbnailPath!), postid.toString(), isThumbnail: true);
             if (thumbUrl != null) {
               uploadedFileUrls.add(thumbUrl);
             }
          }

          String? fileUrl = await _uploadFile(media.file, postid.toString());
          if (fileUrl != null) {
            uploadedFileUrls.add(fileUrl);
            uploadSuccessCount++;
          } else {
            uploadFailCount++;
          }
        }
        
        print('媒体上传完成: 成功 $uploadSuccessCount 个，失败 $uploadFailCount 个');
      }
      
      // 拼接文件名（用逗号分隔）
      String imgname = uploadedFileUrls.join(',');
      
      _showError('正在发布动态...');
      
      // 步骤2：发送帖子基本信息
      bool postInfoSent = await _sendPostInfo(postid.toString(), _contentController.text, imgname);
      
      if (!postInfoSent) {
        _showError('发布失败：无法发送帖子信息');
        return;
      }
      
      // 发布成功，返回主页
      if (mounted) {
        String message = uploadFailCount > 0 
            ? '发布成功，但有 $uploadFailCount 个媒体上传失败' 
            : '发布成功';
        _showError(message);
        
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
                        color: const Color(0xFF0500FA),
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

            // 媒体选择区
            if (_selectedMedia.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    final media = _selectedMedia[index];
                    return GestureDetector(
                      onTap: media.isVideo ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerPage(
                              videoUrl: media.file.path,
                              content: _contentController.text,
                            ),
                          ),
                        );
                      } : null,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 优先显示缩略图，如果是图片则显示原图
                              media.isVideo
                                  ? (media.thumbnailPath != null
                                      ? Image.file(
                                          File(media.thumbnailPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Center(child: Icon(Icons.videocam, size: 40, color: Colors.grey)),
                                        )
                                      : (media.thumbnailData != null
                                          ? Image.memory(
                                              media.thumbnailData!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Center(child: Icon(Icons.videocam, size: 40, color: Colors.grey)),
                                            )
                                          : const Center(child: Icon(Icons.videocam, size: 40, color: Colors.grey))))
                                  : Image.file(
                                      media.file,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                                    ),
                              
                              if (media.isVideo)
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.white70,
                                    size: 40,
                                  ),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeMedia(index),
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
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 上传媒体按钮
            GestureDetector(
              onTap: _selectMedia,
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
                      '添加媒体',
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
