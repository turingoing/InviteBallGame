import 'package:flutter/material.dart';
import '../model/main/dynamic_model.dart'; // 导入模型类
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 0,left: 0,bottom: 1,top: 0),
      padding: const EdgeInsets.only(right:16,left:16,top: 8,bottom: 8),
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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.dynamicData.avatarUrl.startsWith('http://') || widget.dynamicData.avatarUrl.startsWith('https://')
                        ? NetworkImage(widget.dynamicData.avatarUrl)
                        : AssetImage(widget.dynamicData.avatarUrl) as ImageProvider,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名（自定义）
                  Text(
                    widget.dynamicData.userName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  // 地理位置（自定义）
                  Row(
                    children: [
                      if (widget.dynamicData.iconUrl != null) 
                        Image.asset(widget.dynamicData.iconUrl!,height: 15,width: 45,),
                        
                      const SizedBox(width:12),

                      Text(
                        widget.dynamicData.location,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  )
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
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final imgPath = widget.dynamicData.imageUrls.first;    //获得图片地址
                        // final maxWidth = constraints.maxWidth * 3 / 5;  //获得宽度
                        // debugPrint("屏幕宽度：$maxWidth");

                        return FutureBuilder<Size>(
                          future: getImageSize(imgPath), // 获取图片真实宽高
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(); // 加载中
                            }

                            // 拿到图片真实宽高
                            final imgW = snapshot.data!.width;
                            final imgH = snapshot.data!.height;
                            debugPrint("宽：$imgW,高：$imgH");

                            // 计算高度：保持比例，宽度固定 2/3 屏幕
                            // final autoHeight = maxWidth * (imgH / imgW);
                            if(imgH>4000){
                              return imgPath.startsWith('http://') || imgPath.startsWith('https://')
                                  ? Image.network(
                                      imgPath,
                                      width: 160,
                                      height: 250,
                                      fit: BoxFit.fill,
                                    )
                                  : Image.asset(
                                      imgPath,
                                      width: 160,
                                      height: 250,
                                      fit: BoxFit.fill,
                                    );
                            }else{
                              return imgPath.startsWith('http://') || imgPath.startsWith('https://')
                                  ? Image.network(
                                      imgPath,
                                      width: 250,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      imgPath,
                                      width: 250,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    );
                            }
                            
                          },
                        );
                      },
                    ),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    // childAspectRatio: 1.0,
                    children: widget.dynamicData.imageUrls.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: url.startsWith('http://') || url.startsWith('https://')
                            ? Image.network(
                                url,
                                width: 10,
                                height: 10,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                url,
                                width: 10,
                                height: 10,
                                fit: BoxFit.cover,
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
                        isLiked ? 'assets/images/zb/点赞 (1).png' : 'assets/images/zb/点赞 (1).png',
                        width: 22,
                        height: 22,
                        color: isLiked ? Colors.red : null,
                      ),
                      const SizedBox(width: 4),
                      Text('$likeCount', style: TextStyle(color: isLiked ? Colors.red : Colors.grey)),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Column(
                      children: [
                        // Container(height: 4),
                        Row(
                          children: [
                            Image.asset('assets/images/zb/消息圆.png',width: 20,height: 20,),
                            const SizedBox(width: 4),
                            Text('${widget.dynamicData.collectCount}', style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: toggleCollect,
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(height: 1),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/zb/收藏3.png',
                                width: 22,
                                height: 22,
                                color: isCollected ? Colors.red : null,
                              ),
                              const SizedBox(width: 4),
                              Text('$collectCount', style: TextStyle(color: isCollected ? Colors.red : Colors.grey)),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Image.asset('assets/images/zb/转发1.png',width: 22,height: 22,),
                  // const Icon(Icons.redo_outlined, color: Colors.grey),
                  const SizedBox(width: 4),
                  // Text('${widget.dynamicData.commentCount}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}



// 获取图片宽高，支持本地资源和网络图片
Future<Size> getImageSize(String path) async {
  Uint8List imageData;
  
  // 判断是网络图片还是本地资源
  if (path.startsWith('http://') || path.startsWith('https://')) {
    // 网络图片
    final response = await http.get(Uri.parse(path));
    imageData = response.bodyBytes;
  } else {
    // 本地资源
    final data = await rootBundle.load(path);
    imageData = data.buffer.asUint8List();
  }
  
  final image = await decodeImageFromList(imageData);   //解码数据
  final width = image.width.toDouble();   //获得宽度
  final height = image.height.toDouble();   //获得高度
  return Size(width, height);   //返回宽高
}