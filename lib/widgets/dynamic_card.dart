import 'package:flutter/material.dart';
import '../model/main/dynamic_model.dart'; // 导入模型类
import '../pages/photo_viewer_page.dart'; // 导入图片查看器页面

// 动态卡片组件
// 通用动态卡片组件（支持自定义内容）
class DynamicCard extends StatefulWidget {
  final DynamicModel dynamicData; // 传入的动态数据模型

  const DynamicCard({
    super.key,
    required this.dynamicData, // 必须传入的动态数据
  });

  @override
  State<DynamicCard> createState() => _DynamicCardState();
}

class _DynamicCardState extends State<DynamicCard> {
  bool isLiked = false;
  int likeCount = 0;
  bool isCollected = false;
  int collectCount = 0;

  @override
  void initState() {
    super.initState();
    likeCount = widget.dynamicData.likeCount;
    collectCount = widget.dynamicData.collectCount;
  }

  void toggleLike() {
    setState(() {
      if (isLiked) {
        isLiked = false;
        likeCount--;
      } else {
        isLiked = true;
        likeCount++;
      }
    });
  }

  void toggleCollect() {
    setState(() {
      if (isCollected) {
        isCollected = false;
        collectCount--;
      } else {
        isCollected = true;
        collectCount++;
      }
    });
  }

  bool _isNetworkPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
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

  Widget _buildErrorPlaceholder({
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
      child: Icon(
        isAvatar ? Icons.person : Icons.image_not_supported_outlined,
        color: Colors.grey[500],
        size: isAvatar ? 28 : 32,
      ),
    );

    if (isAvatar) {
      return SizedBox(width: 48, height: 48, child: placeholder);
    }
    return placeholder;
  }

  Widget _buildNetworkOrAssetImage(
    String imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool isAvatar = false,
    Alignment alignment = Alignment.center,
  }) {
    if (imagePath.isEmpty) {
      return _buildErrorPlaceholder(
        width: width,
        height: height,
        isAvatar: isAvatar,
      );
    }

    if (_isNetworkPath(imagePath)) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: child,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _buildLoadingPlaceholder(
            width: width,
            height: height,
            isAvatar: isAvatar,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder(
            width: width,
            height: height,
            isAvatar: isAvatar,
          );
        },
      );
    }

    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder(
          width: width,
          height: height,
          isAvatar: isAvatar,
        );
      },
    );
  }

  Widget _buildAvatar() {
    return ClipOval(
      child: _buildNetworkOrAssetImage(
        widget.dynamicData.avatarUrl,
        width: 48,
        height: 48,
        isAvatar: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 0, left: 0, bottom: 1, top: 0),
      padding: const EdgeInsets.only(right: 16, left: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 头部：头像 + 用户名 + 位置
          Row(
            children: [
              // 头像（自定义URL + 在线状态）
              Stack(children: [_buildAvatar()]),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名（自定义）
                  Text(
                    widget.dynamicData.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // 地理位置（自定义）
                  Row(
                    children: [
                      if (widget.dynamicData.iconUrl != null)
                        Image.asset(
                          widget.dynamicData.iconUrl!,
                          height: 15,
                          width: 45,
                        ),

                      const SizedBox(width: 12),

                      Text(
                        widget.dynamicData.location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          // 2. 动态文本内容（自定义）
          Text(
            widget.dynamicData.content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),

          // 3. 图片内容
          Container(
            alignment: Alignment.centerLeft,
            child: widget.dynamicData.imageUrls.length == 1
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoViewerPage(
                            imageUrls: widget.dynamicData.imageUrls,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final imgPath =
                              widget.dynamicData.imageUrls.first; //获得图片地址
                          final imageWidth = constraints.maxWidth < 250
                              ? constraints.maxWidth
                              : 250.0;
                          final imageHeight = imageWidth * 0.6;

                          return _buildNetworkOrAssetImage(
                            imgPath,
                            width: imageWidth,
                            height: imageHeight,
                            alignment: Alignment.center,
                          );
                        },
                      ),
                    ),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    children: widget.dynamicData.imageUrls.asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final url = entry.value;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoViewerPage(
                                imageUrls: widget.dynamicData.imageUrls,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final imageSize = constraints.maxWidth;
                              return _buildNetworkOrAssetImage(
                                url,
                                width: imageSize,
                                height: imageSize,
                                alignment: Alignment.center,
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 10),
          // 4. 互动栏（自定义数字）
          Row(
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: toggleLike,
                  child: Row(
                    children: [
                      Image.asset(
                        isLiked
                            ? 'assets/images/zb/点赞 (1).png'
                            : 'assets/images/zb/点赞 (1).png',
                        width: 22,
                        height: 22,
                        color: isLiked ? Colors.red : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        likeCount > 0 ? '$likeCount' : '点赞',
                        style: TextStyle(
                          color: isLiked ? Colors.red : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/zb/消息圆.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.dynamicData.commentCount > 0
                          ? '${widget.dynamicData.commentCount}'
                          : '评论',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: toggleCollect,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/zb/收藏3.png',
                        width: 22,
                        height: 22,
                        color: isCollected ? Colors.red : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        collectCount > 0 ? '$collectCount' : '收藏',
                        style: TextStyle(
                          color: isCollected ? Colors.red : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Image.asset(
                    'assets/images/zb/转发1.png',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '转发',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
