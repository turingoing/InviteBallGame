import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/VenueList/components/MatchDetailPage.dart';

import 'package:flutter_application_1/model/venue/list_venue.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';

class VenueListPage extends StatelessWidget {
  const VenueListPage({super.key});
  @override
  Widget build(BuildContext context){
    return BallReservationPage();
  }
}

class BallReservationPage extends StatefulWidget {
  const BallReservationPage({super.key});

  @override
  State<BallReservationPage> createState() => _BallReservationPageState();
}

class _BallReservationPageState extends State<BallReservationPage> {

  // 列表数据
  List<BallReservationItem> _reservationList = [];
  bool _isLoading = true;

  // 下拉框选择值
  String _selectedLocation = '位置';
  String _selectedProject = '项目';
  String _selectedDate = '日期';
  String _selectedLevel = '级别';

  // 下拉框选项
  final List<String> _locationOptions = ['位置', '南京东路', '徐家汇', '静安'];
  final List<String> _projectOptions = ['项目', '台球', '乒乓球', '羽毛球'];
  final List<String> _dateOptions = ['日期', '今天', '明天', '后天'];
  final List<String> _levelOptions = ['级别', '初级', '中级', '高级'];

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
      return SizedBox(
        width: width ?? 48,
        height: height ?? 48,
        child: placeholder,
      );
    }
    return placeholder;
  }

  @override
  void initState() {
    super.initState();
    _loadMessageData(); // 页面一打开就加载JSON
  }
  
  Future<void> _loadMessageData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // 获取本地存储的 itsid
      String? itsid = await DataStorage.loadItsid();
      
      // 构建API请求URL - 首页约球按钮使用 11806 接口
      String baseUrl = 'https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11806';
      if (itsid != null && itsid.isNotEmpty) {
        baseUrl += '&itsid=$itsid';
      }
      final url = Uri.parse(baseUrl);
      print('请求约球数据URL: $url');
      
      // 发送请求
      var response = await http.get(url);
      print('约球数据响应状态码: ${response.statusCode}');
      print('约球数据响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        // 解析响应数据
        Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['code'] == '0' && responseData['data'] is List) {
          List<dynamic> rawDataList = responseData['data'];
          
          // 转换API数据为BallReservationItem模型
          List<BallReservationItem> newList = [];
          
          for (var item in rawDataList) {
            // 将API字段映射到模型字段（使用小写字段名）
            int participantCount = int.tryParse(item['participantcount'] ?? '0') ?? 0;
            String sellLevel = (item['selllevel'] ?? '0').toString();
            String feeMode = item['feemode'] ?? '0';
            String gameType = item['gametype'] ?? '0';
            String note = item['note'] ?? '';
            String time = item['time'] ?? '';
            String userId = (item['userid'] ?? '未知').toString();
            String userName = (item['username'] ?? '').toString().trim().replaceAll('`', '');
            if (userName.isEmpty) {
              userName = '用户$userId';
            }
            String headimg = (item['headimg'] ?? '').toString().trim().replaceAll('`', '');
            String avatarUrl = headimg.isNotEmpty
                ? 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$headimg'
                : 'https://www.example.com/avatar.jpg';
            String area = (item['area'] ?? '').toString().trim().replaceAll('`', '');
            if (area.isEmpty) {
              area = '未知';
            }
            double creditScore = double.tryParse((item['creditscore'] ?? '0').toString()) ?? 0.0;
            double score = (creditScore / 20).clamp(0.0, 5.0).toDouble();
            
            // 处理时间格式
            String displayTime = time;
            bool isExpired = false;
            if (time.isNotEmpty) {
              try {
                // 判断是否已截止
                String timeStr = time.replaceAll('/', '-');
                List<String> timeParts = timeStr.split(' ');
                if (timeParts.isNotEmpty) {
                  List<String> dateParts = timeParts[0].split('-');
                  if (dateParts.length == 3) {
                    String y = dateParts[0];
                    String m = dateParts[1].padLeft(2, '0');
                    String d = dateParts[2].padLeft(2, '0');
                    
                    String h = '00', min = '00', sec = '00';
                    if (timeParts.length >= 2) {
                      List<String> clockParts = timeParts[1].split(':');
                      h = clockParts.isNotEmpty ? clockParts[0].padLeft(2, '0') : '00';
                      min = clockParts.length > 1 ? clockParts[1].padLeft(2, '0') : '00';
                      sec = clockParts.length > 2 ? clockParts[2].padLeft(2, '0') : '00';
                    }
                    
                    DateTime parsedTime = DateTime.parse('$y-$m-$d $h:$min:$sec');
                    isExpired = DateTime.now().isAfter(parsedTime);
                  }
                }
                
                if (time.contains('/') || time.contains('-')) {
                  List<String> parts = time.split(' ');
                  if (parts.isNotEmpty) {
                    displayTime = parts[0];
                  }
                }
              } catch (e) {
                displayTime = time;
              }
            }
            
            // 从API获取已加入人数
            int joinedNumber = item['joinednum'] is int 
                ? item['joinednum'] 
                : int.tryParse(item['joinednum']?.toString() ?? '1') ?? 1;
            
            // 创建BallReservationItem对象
            BallReservationItem reservationItem = BallReservationItem(
              avatarUrl: avatarUrl,
              name: userName,
              levelTag: _getLevelTag(sellLevel),
              tagColor: _getLevelColor(sellLevel),
              score: score,
              location: item['location'] ?? '', // 直接使用API返回的location
              area: area,
              time: displayTime, // 使用处理后的时间
              lackCount: participantCount > joinedNumber ? participantCount - joinedNumber : 0, // 缺少人数 = 总人数 - 已加入人数
              joinedCount: joinedNumber, // 使用API返回的已加入人数
              totalCount: participantCount, // 总人数
              feeType: _getFeeType(feeMode), // 根据feeMode获取费用类型
              roomNo: item['inviteid'] ?? '', // 使用inviteid作为房间号
              gameType: _getGameType(gameType), // 约球类型
              note: note, // 备注
              inviteId: item['inviteid'] ?? '', // 约球ID
              isExpired: isExpired, // 是否已截止
            );
            
            newList.add(reservationItem);
          }
          
          // 根据 inviteid 降序排序，最大的在最上面
          newList.sort((a, b) {
            int idA = int.tryParse(a.inviteId) ?? 0;
            int idB = int.tryParse(b.inviteId) ?? 0;
            return idB.compareTo(idA);
          });
          
          if (mounted) {
            setState(() {
              _reservationList = newList;
            });
          }
        } else {
          print('数据格式错误: ${response.body}');
        }
      } else {
        print('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('加载约球数据失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // 根据skillLevel获取等级标签
  String _getLevelTag(String skillLevel) {
    switch (skillLevel) {
      case '0': return '初级';
      case '1': return '中级';
      case '2': return '高级';
      default: return '初级';
    }
  }
  
  // 根据skillLevel获取等级颜色
  Color _getLevelColor(String skillLevel) {
    switch (skillLevel) {
      case '0': return const Color(0xFF34C759); // 绿色
      case '1': return const Color(0xFF007AFF); // 蓝色
      case '2': return const Color(0xFFFF9500); // 橙色
      default: return const Color(0xFF34C759);
    }
  }
  
  // 根据feeMode获取费用类型
  String _getFeeType(String feeMode) {
    switch (feeMode) {
      case '0': return 'AA制';
      case '1': return '败方付';
      case '2': return '胜方付';
      case '3': return '对方付';
      default: return 'AA制';
    }
  }
  
  // 根据gameType获取约球类型
  String _getGameType(String gameType) {
    switch (gameType) {
      case '0': return '中式八球';
      case '1': return '斯诺克';
      case '2': return '九球';
      case '3': return '六球';
      case '4': return '四球';
      case '5': return '其他';
      default: return '中式八球';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),   //顶部
      body: RefreshIndicator(
        onRefresh: _loadMessageData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(   
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索栏
              _buildSearchBar(),
              const SizedBox(height: 6),
              // 提醒卡片
              _buildComplianceCard(),
              const SizedBox(height: 6),
              // 筛选栏
              _buildFilterBar(),
              const SizedBox(height: 6),
              // 约球列表
              _buildReservationList(),
              const SizedBox(height: 80), // 底部导航预留空间
            ],
          ),
        ),
      ),
    );
  }

  // 顶部AppBar（约球 + 通知铃铛）
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      toolbarHeight:45,
      elevation: 0,   //让阴影为0

      scrolledUnderElevation: 0, // 滚动时不抬高
      surfaceTintColor: Colors.transparent, // 取消滚动变色
      title: const Text(
        '约球',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications, color: Colors.black, size: 24),
          ),
        ),
      ],
    );
  }

  // 搜索栏
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey, size: 20),
          SizedBox(width: 8),
          Text(
            '搜索俱乐部、球友或房间号',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // 合规运动提醒卡片
  Widget _buildComplianceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified, color: Color(0xFF5856D6), size: 20),
              SizedBox(width: 8),
              Text(
                '合规运动提醒',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '请遵守场馆规定，文明约球。严禁任何形式的违规行为，共同维护绿色台球环境。',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF575C6F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {},
            child: const Text(
              '查看详情 >',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 筛选栏（位置/项目/日期/级别）
  Widget _buildFilterBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDropdown('位置', _selectedLocation, _locationOptions, (value) {
          setState(() {
            _selectedLocation = value!;
          });
        }),
        _buildDropdown('项目', _selectedProject, _projectOptions, (value) {
          setState(() {
            _selectedProject = value!;
          });
        }),
        _buildDropdown('日期', _selectedDate, _dateOptions, (value) {
          setState(() {
            _selectedDate = value!;
          });
        }),
        _buildDropdown('级别', _selectedLevel, _levelOptions, (value) {
          setState(() {
            _selectedLevel = value!;
          });
        }),
      ],
    );
  }

  // 下拉框组件
  Widget _buildDropdown(String label, String selectedValue, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        onChanged: onChanged,
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.black,
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
        iconSize: 18,
        elevation: 4,
        underline: Container(),
        isDense: true,
        dropdownColor: Colors.white,
      ),
    );
  }

  // 约球列表
  Widget _buildReservationList() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: _buildLoadingPlaceholder()),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reservationList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildReservationItem(_reservationList[index]);
      },
    );
  }

  // 单个约球列表项
  Widget _buildReservationItem(BallReservationItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12,bottom: 3,left: 12,right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：头像 + 姓名/标签/评分 + 费用/房间号
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              SizedBox(
                width: 40,
                height: 40,
                child: ClipOval(
                  child: Image.network(
                    item.avatarUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildLoadingPlaceholder(
                        width: 40,
                        height: 40,
                        isAvatar: true,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: Color(0xFFEDEDED),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: 22,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 中间信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 姓名 + 等级标签
                    Row(
                      children: [
                        const SizedBox(height: 30,),
                        Text(   //姓名
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.tagColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.levelTag,
                            style: TextStyle(
                              fontSize: 10,
                              color: item.tagColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 评分 + 活跃区域
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFF9500), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '球品 ${item.score.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF575C6F),
                          ),
                        ),
                        if (item.area.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· 活跃于 ${item.area}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF575C6F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 右侧：费用 + 房间号
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '费用: ${item.feeType}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0500FA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '房间号: ${item.roomNo}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF575C6F),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 场馆位置
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF6E6E73), size: 14),
              const SizedBox(width: 6),
              Text(
                item.location,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // 时间
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF6E6E73), size: 14),
              const SizedBox(width: 6),
              Text(
                item.time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // 缺人信息
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF6E6E73), size: 14),
              const SizedBox(width: 6),
              Text(
                '缺 ${item.lackCount} 人 (已加入: ${item.joinedCount}/${item.totalCount})',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // 约球类型
          Row(
            children: [
              const Icon(Icons.sports_bar, color: Color(0xFF6E6E73), size: 14),
              const SizedBox(width: 6),
              Text(
                '约球类型: ${item.gameType}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          // 备注信息（如果有）
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, color: Color(0xFF6E6E73), size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '备注: ${item.note}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF575C6F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          // 操作栏：立即加入 + 分享 + 聊天
          Row(
            children: [
              // 立即加入按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: item.isExpired ? null : () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>MatchDetailPage(inviteid: item.inviteId)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.isExpired ? Colors.grey : const Color(0xFF0500FA),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  child: Text(
                    item.isExpired ? '已截止加入' : '立即加入',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 分享按钮
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              // 聊天按钮
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble, color: Colors.black, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
