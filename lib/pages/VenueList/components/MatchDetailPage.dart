import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/utils/http_client.dart';
import 'package:flutter_application_1/pages/VenueList/components/payment_page.dart';

// 评价项数据模型
class CommentItem {
  final String avatarUrl;
  final String userName;
  final int rating;
  final String time;
  final String content;

  CommentItem({
    required this.avatarUrl,
    required this.userName,
    required this.rating,
    required this.time,
    required this.content,
  });
}

// 约球详情数据模型
class MatchDetailData {
  final String userid;
  final String username;
  final String headimg;
  final String location;
  final String area;
  final String note;
  final String time;
  final String participantcount;
  final String skilllevel;
  final String gametype;
  final String feemode;
  final String inviteid;
  final String selllevel;
  final String creditscore;
  final int joinednum;

  MatchDetailData({
    required this.userid,
    required this.username,
    required this.headimg,
    required this.location,
    required this.area,
    required this.note,
    required this.time,
    required this.participantcount,
    required this.skilllevel,
    required this.gametype,
    required this.feemode,
    required this.inviteid,
    required this.selllevel,
    required this.creditscore,
    required this.joinednum,
  });

  factory MatchDetailData.fromJson(Map<String, dynamic> json) {
    final dynamic joinedRaw = json['joinednum'] ?? json['invitednum'];
    final int joinedNum = joinedRaw is int ? joinedRaw : int.tryParse(joinedRaw?.toString() ?? '0') ?? 0;
    return MatchDetailData(
      userid: (json['userid'] ?? '').toString(),
      username: (json['username'] ?? '').toString().trim().replaceAll('`', ''),
      headimg: (json['headimg'] ?? '').toString().trim().replaceAll('`', ''),
      location: (json['location'] ?? '').toString(),
      area: (json['area'] ?? '').toString().trim().replaceAll('`', ''),
      note: (json['note'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      participantcount: (json['participantcount'] ?? '').toString(),
      skilllevel: (json['skilllevel'] ?? '').toString(),
      gametype: (json['gametype'] ?? '').toString(),
      feemode: (json['feemode'] ?? '').toString(),
      inviteid: (json['inviteid'] ?? '').toString(),
      selllevel: (json['selllevel'] ?? '').toString().trim(),
      creditscore: (json['creditscore'] ?? '').toString().trim(),
      joinednum: joinedNum,
    );
  }
}

class ParticipantUser {
  final String userid;
  final String username;
  final String headimg;

  ParticipantUser({
    required this.userid,
    required this.username,
    required this.headimg,
  });

  factory ParticipantUser.fromJson(Map<String, dynamic> json) {
    String headimgValue = '';
    for (final entry in json.entries) {
      if (entry.key.toLowerCase().contains('headimg')) {
        headimgValue = (entry.value ?? '').toString();
        break;
      }
    }
    return ParticipantUser(
      userid: (json['userid'] ?? '').toString(),
      username: (json['username'] ?? '').toString().trim().replaceAll('`', ''),
      headimg: headimgValue.trim().replaceAll('`', ''),
    );
  }
}

class MatchDetailPage extends StatefulWidget {
  final String inviteid;

  const MatchDetailPage({super.key, required this.inviteid});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  // 约球详情数据
  MatchDetailData? _matchData;
  bool _isLoading = true;
  String? _errorMessage;

  List<ParticipantUser> _joinedUsers = [];
  bool _isJoinedUsersLoading = false;

  // 列表数据
  // List<CommentItem> _commentList = [];


  @override
  void initState() {
    super.initState();
    _loadMatchData();
    _loadJoinedUsers();
  }

  // 获取约球详情数据
  Future<void> _loadMatchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 获取本地存储的 itsid
      String? itsid = await DataStorage.loadItsid();
      
      // 构建API请求URL
      String baseUrl = 'https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=09&itcid=11809&inviteid=${widget.inviteid}';
      if (itsid != null && itsid.isNotEmpty) {
        baseUrl += '&itsid=$itsid';
      }
      final url = Uri.parse(baseUrl);
      print('请求约球详情URL: $url');

      // 发送请求
      final response = await http.get(url);

      print('约球详情响应状态码: ${response.statusCode}');
      print('约球详情响应内容: ${response.body}');

      if (response.statusCode == 200) {
        // 解析JSON数据
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _matchData = MatchDetailData.fromJson(data);
        });
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('加载约球详情失败: $e');
      setState(() {
        _errorMessage = '加载失败，请稍后重试';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _avatarUrlFromHeadimg(String headimg) {
    final cleaned = headimg.trim().replaceAll('`', '');
    if (cleaned.isEmpty) return '';
    return 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$cleaned';
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
    return placeholder;
  }

  Widget _buildAvatarErrorPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.grey),
    );
  }

  Widget _buildNetworkAvatar({
    required double size,
    required String imageUrl,
  }) {
    if (imageUrl.trim().isEmpty) {
      return _buildAvatarErrorPlaceholder(size);
    }
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingPlaceholder(width: size, height: size, isAvatar: true);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildAvatarErrorPlaceholder(size);
          },
        ),
      ),
    );
  }

  Future<void> _loadJoinedUsers() async {
    setState(() {
      _isJoinedUsersLoading = true;
    });

    try {
      String? itsid = await DataStorage.loadItsid();

      String baseUrl = 'https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11810&inviteid=${widget.inviteid}';
      if (itsid != null && itsid.isNotEmpty) {
        baseUrl += '&itsid=$itsid';
      }
      final url = Uri.parse(baseUrl);
      print('请求已加入成员URL: $url');

      final response = await http.get(url);
      print('已加入成员接口响应 (11810): ${response.body}');
      print('已加入成员响应状态码: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['code']?.toString() == '0' && responseData['data'] is List) {
        final rawList = (responseData['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (mounted) {
          setState(() {
            _joinedUsers = rawList.map(ParticipantUser.fromJson).toList();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _joinedUsers = [];
          });
        }
      }
    } catch (e) {
      print('加载已加入成员失败: $e');
      if (mounted) {
        setState(() {
          _joinedUsers = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoinedUsersLoading = false;
        });
      }
    }
  }

  // 约球类型转换
  String _getGameType(String gametype) {
    switch (gametype) {
      case '0': return '中式八球';
      case '1': return '斯诺克';
      case '2': return '九球';
      case '3': return '四球';
      case '4': return '六球';
      case '5':
      default: return '其他';
    }
  }

  // 费用模式转换
  String _getFeeMode(String feemode) {
    switch (feemode) {
      case '0': return 'AA制';
      case '1': return '败方付';
      case '2': return '胜方付';
      case '3': return '对方付';
      default: return '未知';
    }
  }
  
  // Future<void> _loadMatchData() async {
  //   // 读取你的JSON文件
  //   final jsonList = await JsonReader.readJsonList('assets/json/venue/match.json');
    
  //   setState(() {
  //     // 转成模型
  //     _commentList = jsonList.map((json) => CommentItem.fromJson(json)).toList();
  //   });
  // }


  // 模拟评价列表数据
  final List<CommentItem> commentList = [
    CommentItem(
      avatarUrl: 'https://picsum.photos/200/200?random=1',
      userName: 'HHHHH',
      rating: 5,
      time: '昨天 22:15',
      content: '王先生人非常客气，球技是真的好，特别是走位，受教了！星爵这家的台子也维护得不错。',
    ),
    CommentItem(
      avatarUrl: 'https://picsum.photos/200/200?random=2',
      userName: '阿杰',
      rating: 4,
      time: '05-20',
      content: '很愉快的周末。大家都很准时，球场氛围很好，适合切磋交流。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 用户信息区域
                      _buildUserInfoSection(),
                      SizedBox(height: 3,child: Container(width: double.infinity,color: Colors.grey[200],),),

                      // 2. 对局标题与标签
                      _buildMatchTitleSection(),
                       SizedBox(height: 24,child: Container(width: double.infinity,color: Colors.grey[200],),),
                       
                      // 3. 活动信息区域（时间/地点/人数）
                      _buildActivityInfoSection(),
                       SizedBox(height: 24,child: Container(width: double.infinity,color: Colors.grey[200],),),

                      // 4. 活动备注
                      _buildActivityRemarkSection(),
                       SizedBox(height: 16,child: Container(width: double.infinity,color: Colors.grey[200],),),

                      // 5. 合规提醒
                      _buildComplianceSection(),
                       SizedBox(height: 24,child: Container(width: double.infinity,color: Colors.grey[200],),),

                      // 6. 地图区域
                      _buildMapSection(),
                       SizedBox(height: 24,child: Container(width: double.infinity,color: Colors.grey[200],),),

                      // 7. 评价区
                      _buildCommentSection(),
                      const SizedBox(height: 100), // 底部按钮预留空间
                    ],
                  ),
                ),
      // 8. 底部立即加入按钮
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // 顶部AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '对局详情',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black, size: 24),
          onPressed: () {},
        ),
      ],
    );
  }

  // 用户信息区域
  Widget _buildUserInfoSection() {
    final avatarUrl = _avatarUrlFromHeadimg(_matchData?.headimg ?? '');
    final sellLevel = (_matchData?.selllevel ?? '').trim();
    final userName = (_matchData?.username ?? '').trim().isNotEmpty
        ? (_matchData?.username ?? '')
        : ((_matchData?.userid ?? '').trim().isNotEmpty ? '用户${_matchData?.userid}' : '用户');
    final creditscore = (_matchData?.creditscore ?? '').trim();
    final skilllevel = (_matchData?.skilllevel ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        children: [
          // 头像
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildNetworkAvatar(size: 100, imageUrl: avatarUrl),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0033FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'V${sellLevel.isEmpty ? '0' : sellLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 用户名与等级
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  skilllevel.isEmpty ? '球技等级' : '球技Lv$skilllevel',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5856D6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 评分与胜率
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Color(0xFFFF9500), size: 16),
              const SizedBox(width: 4),
              Text(
                creditscore.isEmpty ? '信用分: -' : '信用分: $creditscore',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
              if ((_matchData?.userid ?? '').isNotEmpty) ...[
                const SizedBox(width: 24),
                Text(
                  'ID: ${_matchData?.userid}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // 查看主页/关注按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8E5FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '查看主页',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0033FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0033FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '关注',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 对局标题与标签
  Widget _buildMatchTitleSection() {
    final title = (_matchData?.location ?? '').toString().trim().isNotEmpty ? (_matchData?.location ?? '') : '对局信息';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildTag(_getGameType(_matchData?.gametype ?? ''), Colors.grey[200]!, Colors.grey[600]!),
              _buildTag(_getFeeMode(_matchData?.feemode ?? ''), Colors.grey[200]!, Colors.grey[600]!),
              _buildTag('准时开球', const Color(0xFFE8E5FF), const Color(0xFF0033FF)),
            ],
          ),
          const SizedBox(height: 3,)
        ],
      ),
    );
  }

  // 标签组件
  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 活动信息区域
  Widget _buildActivityInfoSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        children: [
          // 时间
          _buildInfoRow(
            icon: Icons.access_time,
            iconColor: const Color(0xFF0033FF),
            title: _matchData?.time ?? '时间待定',
            subtitle: '活动时间 (请准时到场)',
          ),
          const SizedBox(height: 16),
          // 地点
          _buildInfoRow(
            icon: Icons.location_on,
            iconColor: const Color(0xFF0033FF),
            title: _matchData?.location ?? '地点待定',
            subtitle: ((_matchData?.area ?? '').trim().isNotEmpty) ? '地区: ${_matchData?.area}' : '点击查看地图',
            hasArrow: true,
          ),
          const SizedBox(height: 16),
          // 人数
          _buildMemberRow(),
        ],
      ),
    );
  }

  // 信息行组件
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool hasArrow = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          if (hasArrow)
            const Icon(Icons.arrow_upward, color: Color(0xFF999999), size: 20),
        ],
      ),
    );
  }

  // 成员行组件
  Widget _buildMemberRow() {
    // 计算缺人数
    int participantCount = int.tryParse(_matchData?.participantcount ?? '0') ?? 0;
    int joinedNum = _matchData?.joinednum ?? 0;
    if (participantCount < 0) participantCount = 0;
    if (joinedNum < 0) joinedNum = 0;
    
    // 不限制 joinedNum 上限，因为有可能加入人数大于等于参与人数
    int missingCount = participantCount - joinedNum;
    String statusText = '';
    if (missingCount <= 0) {
      statusText = '已满人  (已加入: $joinedNum/$participantCount)';
    } else {
      statusText = '缺 $missingCount 人  (已加入: $joinedNum/$participantCount)';
    }
    
    // 用来渲染头像的 itemCount，至少显示 participantCount 个，若 joinedNum 更多则显示 joinedNum 个
    int avatarItemCount = participantCount > joinedNum ? participantCount : joinedNum;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0033FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.people, color: Color(0xFF0033FF), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // 成员头像列表
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatarItemCount,
                  itemBuilder: (context, index) {
                    if (index < joinedNum) {
                      if (_isJoinedUsersLoading) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildLoadingPlaceholder(width: 40, height: 40, isAvatar: true),
                        );
                      }
                      if (index < _joinedUsers.length) {
                        final url = _avatarUrlFromHeadimg(_joinedUsers[index].headimg);
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildNetworkAvatar(size: 40, imageUrl: url),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _buildAvatarErrorPlaceholder(40),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[100],
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 活动备注
  Widget _buildActivityRemarkSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '活动备注',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _matchData?.note ?? '暂无备注',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 合规提醒
  Widget _buildComplianceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber, color: Color(0xFF0033FF), size: 20),
              SizedBox(width: 8),
              Text(
                '合规提醒',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0033FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildComplianceItem('禁止任何形式的赌球行为，发现将永久封禁账号。'),
          const SizedBox(height: 8),
          _buildComplianceItem('请保持良好的体育精神，尊重球友和工作人员。'),
          const SizedBox(height: 8),
          _buildComplianceItem('如因临时退出，请至少提前2小时告知发起人。'),
        ],
      ),
    );
  }

  // 合规提醒项
  Widget _buildComplianceItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // 地图区域
  Widget _buildMapSection() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://picsum.photos/800/400?random=map'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.map, color: Color(0xFF0033FF), size: 20),
              SizedBox(width: 8),
              Text(
                '查看地图详情',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0033FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


//-------------------------------------------------------------------
  // 评价区
  Widget _buildCommentSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '评价区 (12)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  '更多评价',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0033FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 评价列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: commentList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildCommentItem(commentList[index]);
            },
          ),
        ],
      ),
    );
  }

  // 单个评价项
  Widget _buildCommentItem(CommentItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(item.avatarUrl),
            ),
            const SizedBox(width: 8),
            Text(
              item.userName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Text(
              item.time,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 星级评分
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < item.rating ? Icons.star : Icons.star_border,
              color: const Color(0xFFFF9500),
              size: 16,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          item.content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF333333),
            height: 1.4,
          ),
        ),
      ],
    );
  }


//-------------------------------------------------------------------
  // 底部立即加入按钮
  Widget _buildBottomButton() {
    int participantCount = int.tryParse(_matchData?.participantcount ?? '0') ?? 0;
    int joinedNum = _matchData?.joinednum ?? 0;
    
    bool isFull = joinedNum >= participantCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isFull ? null : () => _joinMatch(),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFull ? Colors.grey : const Color(0xFF0033FF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          isFull ? '已满人 ($joinedNum/$participantCount)' : '立即加入 ($joinedNum/$participantCount)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 加入约球
  Future<void> _joinMatch() async {
    try {
      // 使用 HttpClient.postWithMbid 发送请求
      final response = await HttpClient.postWithMbid(
        '11804',
        {
          'inviteid': widget.inviteid,
          'location': _matchData?.location ?? '',
        },
      );

      print('加入约球响应: $response');

      // 解析响应消息
      String code = response['code']?.toString() ?? '';
      String data = response['data']?.toString() ?? '';
      String message = data.isNotEmpty ? data : '操作完成';
      
      // 显示消息提示
      _showMessage(message);

      // 如果加入成功（code为"0"），更新页面数据并显示成功提示
      if (code == '0') {
        _loadJoinedUsers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('待发起人同意'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('加入约球失败: $e');
      _showMessage('加入失败，请稍后重试');
    }
  }

  // 显示消息提示
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
