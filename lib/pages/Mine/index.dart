import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Mine/components/member.dart';
import 'package:flutter_application_1/pages/Mine/components/myplay.dart';
import 'package:flutter_application_1/pages/Mine/components/mypublish.dart';
import 'package:flutter_application_1/pages/Mine/components/my_dynamic.dart';
import 'package:flutter_application_1/pages/Mine/components/edit_profile.dart';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/pages/Auth/login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MinePage extends StatelessWidget {
  const MinePage({super.key});
  @override
  Widget build(BuildContext context){
    return ProfilePage();
  }
}


// 核心功能项数据模型
class CoreFunctionItem {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color bgColor;

  CoreFunctionItem({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.bgColor,
  });
}

// 更多服务项数据模型
class ServiceItem {
  final IconData icon;
  final String title;
  final String? status;
  final Color iconColor;
  final Color statusColor;
  final Color bgColor;

  ServiceItem({
    required this.icon,
    required this.title,
    this.status,
    required this.iconColor,
    required this.statusColor,
    required this.bgColor,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // 用户核心数据
  String _userName = '    ';
  String _userId = 'ID:   ';
  String _location = '  ';
  String _creditScore = ' ';
  String _levelTag = '    ';
  String _avatarUrl = 'assets/images/zb/AppShow.png';
  
  // 会员及身份标识
  String _userType = '0'; // 0:非会员, 1:会员
  String _userTitle = '0'; // 0:普通用户, 1:教练, 2:商家, 3:官方

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  String _getBallRatingStr(String ratingStr) {
    final rating = int.tryParse(ratingStr) ?? 0;
    switch (rating) {
      case 0:
        return '新手';
      case 1:
        return '业余';
      case 2:
        return '高手';
      default:
        return '新手';
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid == null || itsid.isEmpty) return;

      final url = Uri.parse('https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=07&itcid=11807&itsid=$itsid');
      print('请求个人中心接口URL: $url');
      final response = await http.get(url);
      print('个人中心接口响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('个人中心接口返回数据: ${response.body}');
        var data = json.decode(response.body);
        // 如果数据包裹在 data 字段中
        Map<String, dynamic> userInfo = data;
        if (data is Map && data.containsKey('data')) {
          userInfo = data['data'];
        }

        setState(() {
          if (userInfo['username'] != null && userInfo['username'].toString().isNotEmpty) {
            _userName = userInfo['username'].toString();
          }
          if (userInfo['headimg'] != null && userInfo['headimg'].toString().isNotEmpty) {
            _avatarUrl = 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/${userInfo['headimg']}';
            print('最终解析拼接后的头像URL: $_avatarUrl');
          }

          // 其他个人信息展示
          if (userInfo['userid'] != null) {
            String city = userInfo['city']?.toString() ?? '';
            _userId = '搭子号：${userInfo['userid']} | 坐标：$city';
            _location = city; // 若别处仍需用单独的 location，顺便更新
          }

          if (userInfo['creditscore'] != null) {
            _creditScore = userInfo['creditscore'].toString();
          }

          if (userInfo['ballrateing'] != null) {
            _levelTag = _getBallRatingStr(userInfo['ballrateing'].toString());
          }

          // 解析会员及身份标识
          if (userInfo['usertype'] != null) {
            _userType = userInfo['usertype'].toString();
          }
          if (userInfo['usertitle'] != null) {
            _userTitle = userInfo['usertitle'].toString();
          }

          // 数据统计栏：关注，粉丝，获赞，动态
          _statsList = [
            {'value': userInfo['followcount']?.toString() ?? '0', 'label': '关注'},
            {'value': userInfo['followercount']?.toString() ?? '0', 'label': '粉丝'},
            {'value': userInfo['likecount']?.toString() ?? '0', 'label': '获赞'},
            {'value': userInfo['postcount']?.toString() ?? '0', 'label': '动态'},
          ];
        });
      }
    } catch (e) {
      print('获取用户信息失败: $e');
    }
  }

  // 数据统计
  List<Map<String, String>> _statsList = [
    {'value': '128', 'label': '关注'},
    {'value': '1.2k', 'label': '粉丝'},
    {'value': '3.5k', 'label': '获赞'},
    {'value': '42', 'label': '动态'},
  ];

  // 核心功能列表
  final List<CoreFunctionItem> _coreFunctionList = [
    CoreFunctionItem(
      icon: Icons.description,
      title: '我的发布',
      iconColor: const Color(0xFF2962FF),
      bgColor: const Color(0xFFF0F4FF),
    ),
    CoreFunctionItem(
      icon: Icons.people,
      title: '我的约玩',
      iconColor: const Color(0xFF6750A4),
      bgColor: const Color(0xFFF5F0FF),
    ),
    CoreFunctionItem(
      icon: Icons.qr_code_scanner,
      title: '扫一扫',
      iconColor: const Color(0xFF00B4D8),
      bgColor: const Color(0xFFE8FBFF),
    ),
    CoreFunctionItem(
      icon: Icons.receipt_long,
      title: '账单记录',
      iconColor: const Color(0xFF00C853),
      bgColor: const Color(0xFFE8FFF0),
    ),
  ];

  // 更多服务列表
  final List<ServiceItem> _serviceList = [
    ServiceItem(
      icon: Icons.verified_user,
      title: '认证中心',
      status: '未认证',
      iconColor: const Color(0xFF2962FF),
      statusColor: const Color(0xFF9E9E9E),
      bgColor: const Color(0xFFF0F4FF),
    ),
    ServiceItem(
      icon: Icons.badge,
      title: '实名认证',
      status: '已认证',
      iconColor: const Color(0xFF6750A4),
      statusColor: const Color(0xFF00C853),
      bgColor: const Color(0xFFF5F0FF),
    ),
    ServiceItem(
      icon: Icons.headphones,
      title: '联系客服',
      status: null,
      iconColor: const Color(0xFF00C853),
      statusColor: Colors.black,
      bgColor: const Color(0xFFE8FFF0),
    ),
    ServiceItem(
      icon: Icons.card_giftcard,
      title: '邀请有礼',
      status: null,
      iconColor: const Color(0xFFFF3D00),
      statusColor: Colors.black,
      bgColor: const Color(0xFFFFF0F0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题栏
            _buildTopBar(),
            // 用户信息区域
            _buildUserInfoSection(),
            const SizedBox(height: 20),
            // 数据统计栏
            _buildStatsBar(),
            const SizedBox(height: 20),
            // 黑金会员卡片
            _buildVipCard(),
            const SizedBox(height: 16),
            // 申请教练按钮 (仅对普通用户 usertitle=='0' 展示)
            if (_userTitle == '0') ...[
              _buildApplyCoachButton(),
              const SizedBox(height: 32),
            ],
            // 核心功能
            _buildSectionTitle('核心功能'),
            const SizedBox(height: 5),
            _buildCoreFunctionGrid(),
            const SizedBox(height: 20),
            // 更多服务
            _buildSectionTitle('更多服务'),
            const SizedBox(height: 5),
            _buildServiceList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 顶部标题栏（个人中心 + 通知 + 设置）
  Widget _buildTopBar() {
    return Container(
      // height: 60,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '个人中心',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                _buildTopIcon(Icons.edit),
                const SizedBox(width: 16),
                _buildTopIcon(Icons.notifications_none),
                const SizedBox(width: 16),
                _buildTopIcon(Icons.settings),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 顶部图标按钮
  Widget _buildTopIcon(IconData icon) {
    return InkWell(
      onTap: () {
        if (icon == Icons.settings) {
          _showSettingsMenu();
        } else if (icon == Icons.edit) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfilePage()),
          );
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  // 显示设置菜单弹窗
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _buildMenuItem('退出登录', Icons.logout, const Color(0xFFFF4444), () async {
                // 清除itsid
                await DataStorage.clearItsid();
                // 关闭弹窗
                Navigator.pop(context);
                // 跳转到登录页面
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // 菜单项组件
  Widget _buildMenuItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  // 用户信息区域
  Widget _buildUserInfoSection() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像（带认证蓝勾）
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      _avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, size: 50, color: Colors.grey[400]);
                      },
                    ),
                  ),
                ),
                // 身份标识（教练：蓝标；商家：红标；普通用户/官方不显示此处图标）
                if (_userTitle == '1' || _userTitle == '2')
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _userTitle == '2' ? const Color(0xFFFF4444) : const Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 姓名 + V3等级
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'V3',
                          style: TextStyle(
                            fontSize: 3,
                            color: Color(0xFF2962FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ID + 坐标
                  Text(
                    _userId,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 信用 + 实力达人标签
                  Row(
                    children: [
                      Flexible(
                        child: _buildTag(Icons.shield, '信用 $_creditScore', const Color(0xFF2962FF)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildTag(Icons.star, _levelTag, const Color(0xFFFF9800)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 标签组件
  Widget _buildTag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 6, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 数据统计栏
  Widget _buildStatsBar() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _statsList.map((item) {
            return InkWell(
              onTap: () {
                if (item['label'] == '动态') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyDynamicPage()),
                  );
                }
              },
              child: Column(
                children: [
                  Text(
                    item['value']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 黑金会员VIP卡片
  Widget _buildVipCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24),
          ),
          const SizedBox(width: 16),
          //文字区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '黑金会员·VIP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '开通会员享12项专属特权',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          ),
          // 开通或进入专区按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: (){
                Navigator.push(context,MaterialPageRoute(builder: (context)=>MemberCenterApp()));
              },
              child: Text(
                _userType == '1' ? '会员专区' : '立即开通',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ),
        ],
      ),
    );
  }

  // 申请成为认证教练按钮
  Widget _buildApplyCoachButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 7, 69, 238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E5FF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 11, 93, 247),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color.fromARGB(255, 255, 255, 255),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '想通过台球邀约客户？',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '申请成为认证用户',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text(
              '去申请',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0033FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 章节标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  // 核心功能网格
  Widget _buildCoreFunctionGrid() {
    return Container(
      color: Colors.white,
      child: GridView.count(
        padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        children: _coreFunctionList.map((item) {
          return Column(
            children: [
              InkWell(
                onTap: (){
                  if(item.title=="我的约玩"){
                    Navigator.push(context,MaterialPageRoute(builder: (context)=>MyPlayPage()));
                  }else if(item.title=="我的发布" ){
                    Navigator.push(context,MaterialPageRoute(builder: (context)=>MyPublishPage()));
                  }

                },
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, size: 32, color: item.iconColor),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ); 
  }

  // 更多服务列表
  Widget _buildServiceList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _serviceList.map((item) {
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.bgColor,
                // borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 24, color: item.iconColor),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.status != null)
                  Text(
                    item.status!,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCCCCCC)),
              ],
            ),
            onTap: () {},
          );
        }).toList(),
      ),
    );
  }
}