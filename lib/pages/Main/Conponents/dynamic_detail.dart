import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/model/main/dynamic_model.dart';
import 'package:flutter_application_1/widgets/dynamic_card.dart';

// 评论模型
class DynamicComment {
  final String avatarUrl;
  final String userName;
  final String content;
  final String time;

  DynamicComment({
    required this.avatarUrl,
    required this.userName,
    required this.content,
    required this.time,
  });
}

class DynamicDetailPage extends StatefulWidget {
  final DynamicModel dynamicData;

  const DynamicDetailPage({super.key, required this.dynamicData});

  @override
  State<DynamicDetailPage> createState() => _DynamicDetailPageState();
}

class _DynamicDetailPageState extends State<DynamicDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isCollected = false;
  
  // 真实的评论数据
  List<DynamicComment> _comments = [];
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final url = Uri.parse(
        'https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11814&postid=${widget.dynamicData.postid}',
      );
      print('请求评论列表URL: $url');

      final response = await http.get(url);
      print('请求评论列表状态码: ${response.statusCode}');
      print('请求评论列表返回内容: ${response.body}'); // 输出返回内容

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['code'] == '0' && responseData['data'] is List) {
          final List<dynamic> rawComments = responseData['data'];
          final List<DynamicComment> loadedComments = rawComments.map((item) {
            String headimg = item['headimg']?.toString().replaceAll('`', '') ?? '';
            String avatarUrl = headimg.isNotEmpty
                ? 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$headimg'
                : 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/default.png';
                
            print('获取到的原始headimg: $headimg');
            print('拼接后的完整头像URL: $avatarUrl');
            print('头像是否获取成功(非空): ${headimg.isNotEmpty}');

            return DynamicComment(
              avatarUrl: avatarUrl,
              userName: item['usernamecn']?.toString().replaceAll('`', '') ?? '未知用户',
              content: item['commenttext']?.toString() ?? '',
              time: item['publishtime']?.toString() ?? '',
            );
          }).toList();

          if (mounted) {
            setState(() {
              _comments = loadedComments;
              _isLoadingComments = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingComments = false;
            });
          }
        }
      } else {
        throw Exception('请求评论失败');
      }
    } catch (e) {
      print('获取评论失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid == null || itsid.isEmpty) {
        return;
      }

      final url = Uri.parse(
        'https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11810&itsid=$itsid',
      );

      String postText = widget.dynamicData.content;
      if (postText.length > 15) {
        postText = postText.substring(0, 15);
      }

      String imgName = '';
      // 如果是视频，优先使用缩略图
      if (widget.dynamicData.videoUrl != null && widget.dynamicData.videoUrl!.isNotEmpty) {
        if (widget.dynamicData.thumbnailUrl != null && widget.dynamicData.thumbnailUrl!.isNotEmpty) {
          final uri = Uri.tryParse(widget.dynamicData.thumbnailUrl!);
          imgName = (uri != null && uri.pathSegments.isNotEmpty)
              ? uri.pathSegments.last
              : widget.dynamicData.thumbnailUrl!;
        }
      } else if (widget.dynamicData.imageUrls.isNotEmpty) {
        // 提取文件名
        final uri = Uri.tryParse(widget.dynamicData.imageUrls.first);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          imgName = uri.pathSegments.last;
        } else {
          imgName = widget.dynamicData.imageUrls.first;
        }
      }

      final requestBody = {
        'postid': widget.dynamicData.postid,
        'imgname': imgName,
        'posttext': postText,
        'publisherid': widget.dynamicData.userid,
      };
      print('点赞上传URL: $url');
      print('点赞上传itsid: $itsid');
      print('点赞上传参数: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('点赞接口返回状态码: ${response.statusCode}');
      print('点赞接口返回内容: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isLiked = true;
          });
        }
      } else {
        throw Exception('点赞失败');
      }
    } catch (e) {
      print('点赞操作失败: $e');
    }
  }

  Future<void> _handleCollect() async {
    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid == null || itsid.isEmpty) {
        return;
      }

      final url = Uri.parse(
        'https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11812&itsid=$itsid',
      );

      String imgName = '';
      // 如果是视频，优先使用缩略图
      if (widget.dynamicData.videoUrl != null && widget.dynamicData.videoUrl!.isNotEmpty) {
        if (widget.dynamicData.thumbnailUrl != null && widget.dynamicData.thumbnailUrl!.isNotEmpty) {
          final uri = Uri.tryParse(widget.dynamicData.thumbnailUrl!);
          imgName = (uri != null && uri.pathSegments.isNotEmpty)
              ? uri.pathSegments.last
              : widget.dynamicData.thumbnailUrl!;
        }
      } else if (widget.dynamicData.imageUrls.isNotEmpty) {
        // 提取文件名
        final uri = Uri.tryParse(widget.dynamicData.imageUrls.first);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          imgName = uri.pathSegments.last;
        } else {
          imgName = widget.dynamicData.imageUrls.first;
        }
      }

      final body = {
        'postid': widget.dynamicData.postid,
        'imgname': imgName,
        'publisherid': widget.dynamicData.userid,
        'posttext': widget.dynamicData.content,
      };

      print('收藏接口URL: $url');
      print('收藏接口参数: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('收藏接口返回状态码: ${response.statusCode}');
      print('收藏接口返回内容: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isCollected = true;
          });
        }
      } else {
        throw Exception('收藏失败');
      }
    } catch (e) {
      print('收藏操作失败: $e');
    }
  }

  Future<void> _handleSendComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid == null || itsid.isEmpty) {
        return;
      }

      final url = Uri.parse(
        'https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11811&itsid=$itsid',
      );

      String imgName = '';
      // 如果是视频，优先使用缩略图
      if (widget.dynamicData.videoUrl != null && widget.dynamicData.videoUrl!.isNotEmpty) {
        if (widget.dynamicData.thumbnailUrl != null && widget.dynamicData.thumbnailUrl!.isNotEmpty) {
          final uri = Uri.tryParse(widget.dynamicData.thumbnailUrl!);
          imgName = (uri != null && uri.pathSegments.isNotEmpty)
              ? uri.pathSegments.last
              : widget.dynamicData.thumbnailUrl!;
        }
      } else if (widget.dynamicData.imageUrls.isNotEmpty) {
        // 提取文件名
        final uri = Uri.tryParse(widget.dynamicData.imageUrls.first);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          imgName = uri.pathSegments.last;
        } else {
          imgName = widget.dynamicData.imageUrls.first;
        }
      }

      final body = {
        'postid': widget.dynamicData.postid,
        'comment': commentText,
        'imgname': imgName,
        'publisherid': widget.dynamicData.userid,
      };

      print('发送评论接口URL: $url');
      print('发送评论接口参数: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('发送评论接口返回状态码: ${response.statusCode}');
      print('发送评论接口返回内容: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          _commentController.clear();
          FocusScope.of(context).unfocus();
          // 发送成功后重新获取评论列表
          _fetchComments();
        }
      } else {
        throw Exception('发送失败');
      }
    } catch (e) {
      print('发送评论操作失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动态详情'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 帖子内容（复用 DynamicCard，但可能需要禁用点击跳转）
                  DynamicCard(
                    dynamicData: widget.dynamicData,
                    onLikeTap: _handleLike,
                    isLiked: _isLiked,
                    onCollectTap: _handleCollect,
                    isCollected: _isCollected,
                  ),
                  
                  const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),
                  
                  // 2. 评论区标题
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Text(
                          '全部评论',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.dynamicData.commentCount}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 3. 评论列表
                  if (_isLoadingComments)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('暂无评论，快来抢沙发吧~', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) => const Divider(
                        indent: 72,
                        endIndent: 16,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return _buildCommentItem(comment);
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // 4. 底部输入框
          _buildBottomInput(),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder({
    double? width,
    double? height,
    bool isAvatar = false,
  }) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: isAvatar ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );

    if (isAvatar) {
      return SizedBox(width: 48, height: 48, child: placeholder);
    }
    return placeholder;
  }

  Widget _buildCommentItem(DynamicComment comment) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          ClipOval(
            child: Image.network(
              comment.avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return _buildLoadingPlaceholder(
                  width: 40,
                  height: 40,
                  isAvatar: true,
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: 40,
                height: 40,
                color: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      comment.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: '说点什么吧...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _handleSendComment,
            child: const Text(
              '发送',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
