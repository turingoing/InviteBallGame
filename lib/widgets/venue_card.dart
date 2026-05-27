// lib/widgets/venue_card.dart
import 'package:flutter/material.dart';
import '../model/main/surroundings_model.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venueData; // 传入场馆模型数据

  const VenueCard({
    super.key,
    required this.venueData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左侧图片区域
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: venueData.imageUrl.startsWith(RegExp(r'http://|https://'))
                      ? NetworkImage(venueData.imageUrl)
                      : AssetImage(venueData.imageUrl) as ImageProvider,
                  width: 95,
                  height: 95,
                  fit: BoxFit.cover,
                  color: venueData.status == '休息中' ? Colors.grey : null,
                  colorBlendMode: venueData.status == '休息中' ? BlendMode.saturation : null,
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: venueData.status == '营业中' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(venueData.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // 右侧内容区域
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 场馆名称 + 认证图标
                Row(
                  children: [
                    Text(venueData.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    if (venueData.tags.isNotEmpty) const Icon(Icons.verified, color: Colors.blue, size: 18),
                  ],
                ),
                const SizedBox(height: 3),
                // 评分 + 标签 + 营业时间
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 12),
                    Text(' ${venueData.score}', style: const TextStyle(color: Colors.orange)),
                    if (venueData.businessHours != null) Text('  ${venueData.businessHours}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    ...venueData.tags.map((tag) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                      child: Text(tag, style: TextStyle(color: Colors.blue[700], fontSize: 8)),
                    )),
                  ],
                ),
                const SizedBox(height: 3),
                // 地址 + 距离
                Row(
                  children: [
                    Expanded(child: Text(venueData.address, style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(venueData.distance, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                // 促销信息 + 按钮区域
                Row(
                  children: [
                    if (venueData.promotion.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(color: Colors.pink[50], borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard, color: Colors.pink, size: 12),
                            const SizedBox(width: 3),
                            Text(venueData.promotion, style: TextStyle(color: Colors.pink[700], fontSize: 10)),
                          ],
                        ),
                      ),
                    const SizedBox(width: 1),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: venueData.buttonEnabled ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: venueData.buttonEnabled ? Colors.blue : Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(65, 26),
                      ),
                      child: Text(venueData.buttonText, style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}