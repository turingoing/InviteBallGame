import 'package:flutter/material.dart';
import '../../../model/main/surroundings_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Add/components/invite.dart';

class VenueDetailPage extends StatefulWidget {
  final VenueModel venue;

  const VenueDetailPage({super.key, required this.venue});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  int _currentImageIndex = 0;
  bool _isFavorited = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 顶部图片展示区域
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: widget.venue.imageList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final imgUrl = widget.venue.imageList[index];
                      return Image(
                        image: imgUrl.startsWith(RegExp(r'http://|https://'))
                            ? NetworkImage(imgUrl)
                            : AssetImage(imgUrl) as ImageProvider,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  // 图片页码指示器
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${widget.venue.imageList.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 商家基本信息
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.venue.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 20),
                          Text(
                            ' ${widget.venue.score}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.venue.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: Color(0xFF000099), fontSize: 12),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // 营业时间
                  if (widget.venue.businessHours != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('营业时间: ${widget.venue.businessHours}', style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                  // 营业状态
                  Row(
                    children: [
                      Icon(
                        widget.venue.status == '营业中' ? Icons.check_circle_outline : Icons.pause_circle_outline,
                        size: 18,
                        color: widget.venue.status == '营业中' ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(widget.venue.status, style: TextStyle(color: widget.venue.status == '营业中' ? Colors.green : Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 地址
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.venue.address,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      Text(
                        widget.venue.distance,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 功能按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(Icons.comment_outlined, '评论', () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评论功能开发中...')));
                      }),
                      _buildActionButton(Icons.share_outlined, '分享', () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分享功能开发中...')));
                      }),
                      _buildActionButton(
                        _isFavorited ? Icons.favorite : Icons.favorite_border,
                        '收藏',
                        () {
                          setState(() {
                            _isFavorited = !_isFavorited;
                          });
                        },
                        color: _isFavorited ? Colors.red : null,
                      ),
                      _buildActionButton(Icons.navigation_outlined, '一键导航', () async {
                        final url = 'https://uri.amap.com/marker?position=${widget.venue.address}&name=${widget.venue.name}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法打开地图')));
                          }
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // 促销信息
                  if (widget.venue.promotion.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard, color: Colors.pink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('商家优惠', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                                const SizedBox(height: 4),
                                Text(widget.venue.promotion, style: TextStyle(color: Colors.pink[700])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: widget.venue.buttonEnabled ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InviteForm(initialLocation: widget.venue.name),
                ),
              );
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0500FA),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(widget.venue.buttonText, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.black87),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}
