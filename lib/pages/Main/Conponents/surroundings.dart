import 'package:flutter/material.dart';

import 'package:flutter_application_1/model/main/surroundings_model.dart';   //model文件
import 'package:flutter_application_1/widgets/venue_card.dart';
import 'package:flutter_application_1/utils/location_service.dart';
import 'package:flutter_application_1/pages/Main/Conponents/address_select_page.dart';
import 'package:geolocator/geolocator.dart';

// 周边页面（独立的场馆列表页面）
class SurroundingsPage extends StatefulWidget {
  const SurroundingsPage({super.key});

  @override
  State<SurroundingsPage> createState() => _SurroundingsPageState();
}

class _SurroundingsPageState extends State<SurroundingsPage> {
  // 异步加载场馆列表数据
  String _currentCity = '定位中...'; // 默认城市
  String _currentFullAddress = '';
  
  int _selectedRadius = 3000; // 默认3km
  String _locationFilterType = '我的附近'; // '我的附近' 或 '指定地址'
  String _currentSort = '排序'; // 排序类型：'排序' (默认), '距离优先', '好评优先'

  // 筛选下拉状态
  bool _isLocationFilterOpen = false;
  bool _isSortFilterOpen = false;
  
  // 用于下拉菜单的临时状态
  String _tempLocationFilterType = '我的附近';
  int _tempSelectedRadius = 3000;
  
  // 顶部筛选栏显示的文本
  String _locationDisplayText = '我的位置';

  // 分页与数据状态
  List<VenueModel> _venueList = [];
  bool _isLoading = true; // 首次加载或刷新时的加载状态
  bool _isLoadingMore = false; // 上拉加载更多的状态
  bool _hasMore = true; // 是否还有更多数据
  int _currentPage = 1; // 当前页码
  final ScrollController _scrollController = ScrollController(); // 列表滚动控制器
  
  // 自定义指定的经纬度
  double? _customLatitude;
  double? _customLongitude;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 初始化时加载第一页数据
    _loadData(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 监听滚动到底部
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadData(isRefresh: false);
      }
    }
  }

  // 加载数据：isRefresh=true表示下拉刷新或条件改变重新加载，false表示上拉加载更多
  Future<void> _loadData({bool isRefresh = true}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    List<VenueModel> newVenues = await _fetchVenueList(page: _currentPage);

    setState(() {
      if (isRefresh) {
        _venueList = newVenues;
        _isLoading = false;
      } else {
        _venueList.addAll(newVenues);
        _isLoadingMore = false;
      }
      
      // 如果返回的数据少于 20 条，说明没有更多数据了 (高德API默认offset=20)
      if (newVenues.length < 20) {
        _hasMore = false;
      } else {
        _currentPage++; // 准备加载下一页
      }
    });
  }

  // 封装：调用接口获取指定页码的场馆模型列表
  Future<List<VenueModel>> _fetchVenueList({required int page}) async {
    List<VenueModel> realVenues = [];
    try {
      double targetLat;
      double targetLng;

      // 如果是指定地址且已有坐标，则使用指定坐标；否则使用当前定位
      if (_locationFilterType == '指定地址' && _customLatitude != null && _customLongitude != null) {
        targetLat = _customLatitude!;
        targetLng = _customLongitude!;
      } else {
        Position? position = await LocationService.getCurrentLocation();
        if (position == null) return [];
        targetLat = position.latitude;
        targetLng = position.longitude;
      }

      // 尝试获取当前城市名用于更新顶部筛选栏 (仅在第一页时更新)
      if (page == 1) {
        LocationResult? address = await LocationService.getAddressFromCoordinates(targetLat, targetLng);
        if (address != null && mounted) {
          setState(() {
            _currentCity = address.city.isNotEmpty ? address.city : address.province;
            // 如果是定位，则更新地址；如果是指定地址，我们已经在选择时更新了 _currentFullAddress，所以此处可以跳过或者覆盖
            if (_locationFilterType != '指定地址') {
              _currentFullAddress = address.formattedAddress;
            }
          });
        }
      }

      // 获取周边的台球馆 POI，传入 page 参数
      List<Map<String, dynamic>>? pois = await LocationService.searchNearbyPOI(
        '台球|桌球|台球俱乐部', 
        targetLat, 
        targetLng, 
        radius: _selectedRadius,
        page: page
      );
      if (pois != null && pois.isNotEmpty) {
          realVenues = pois.map((poi) {
            // 处理距离显示 (米 转换成 千米)
            String distanceStr = '';
            if (poi['distance'] != null && poi['distance'].toString().isNotEmpty) {
              double dist = double.tryParse(poi['distance'].toString()) ?? 0;
              if (dist > 1000) {
                distanceStr = '${(dist / 1000).toStringAsFixed(1)}km';
              } else {
                distanceStr = '${dist.toInt()}m';
              }
            }

            // 提取扩展信息 (extensions=all 时 biz_ext 包含更多字段)
            double venueScore = 4.5;
            String businessHours = ''; // 不再默认显示“全天营业”
            String status = ''; // 默认为空，根据营业时间判断
            
            if (poi['biz_ext'] != null && poi['biz_ext'] is Map) {
              final biz = poi['biz_ext'];
              // 1. 提取评分
              venueScore = double.tryParse(biz['rating']?.toString() ?? '4.5') ?? 4.5;
              
              // 2. 提取营业时间 (包含 opentime_today, open_time, opentime, opentime2)
              List<String> timeList = [];
              
              void addTime(dynamic timeData) {
                if (timeData == null) return;
                // 如果是列表且为空，则跳过
                if (timeData is List && timeData.isEmpty) return;
                
                String timeStr = timeData.toString().trim();
                // 如果字符串是 "[]" 或空字符串，则跳过
                if (timeStr == "[]" || timeStr.isEmpty) return;
                
                if (!timeList.contains(timeStr)) {
                  timeList.add(timeStr);
                }
              }

              addTime(biz['opentime_today']);
              addTime(biz['open_time']);
              addTime(biz['opentime']);
              addTime(biz['opentime2']);
              
              if (timeList.isNotEmpty) {
                businessHours = timeList.join(' ');
              }

              // 3. 判断营业状态 (优先参考 opentime_today, 其次 open_time, 再其次从 timeList 中寻找)
              String todayTime = '';
              if (biz['opentime_today'] != null && biz['opentime_today'].toString().isNotEmpty && biz['opentime_today'].toString() != "[]") {
                todayTime = biz['opentime_today'].toString();
              } else if (biz['open_time'] != null && biz['open_time'].toString().isNotEmpty && biz['open_time'].toString() != "[]") {
                todayTime = biz['open_time'].toString();
              } else if (timeList.isNotEmpty) {
                todayTime = timeList.first;
              }

              String apiTag = biz['tag']?.toString() ?? '';
              
              // 如果 API 没有返回营业时间，则不显示“营业中”
              if (todayTime.isEmpty || todayTime == "[]") {
                status = ''; // 不显示营业中
              } else {
                // 更加健壮的营业时间匹配逻辑
                bool isInBusinessHours = true;
                
                // 使用正则提取时间段 (支持 "10:00-04:00" 或 "周一至周日 10:00-04:00")
                final timeRegExp = RegExp(r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})');
                final match = timeRegExp.firstMatch(todayTime);

                if (match != null) {
                  try {
                    final now = DateTime.now();
                    final startStr = match.group(1)!;
                    final endStr = match.group(2)!;
                    
                    final startParts = startStr.split(':');
                    final endParts = endStr.split(':');
                    
                    final startHour = int.parse(startParts[0]);
                    final startMin = int.parse(startParts[1]);
                    final endHour = int.parse(endParts[0]);
                    final endMin = int.parse(endParts[1]);

                    // 将时间转换为自当天 00:00 以来的分钟数进行比较
                    final nowMinutes = now.hour * 60 + now.minute;
                    final startMinutes = startHour * 60 + startMin;
                    final endMinutes = endHour * 60 + endMin;

                    if (endMinutes > startMinutes) {
                      // 正常时段 (如 10:00 - 22:00)
                      isInBusinessHours = nowMinutes >= startMinutes && nowMinutes < endMinutes;
                    } else {
                      // 跨天时段 (如 10:00 - 02:00)
                      isInBusinessHours = nowMinutes >= startMinutes || nowMinutes < endMinutes;
                    }
                  } catch (e) {
                    // 解析失败则默认在营业时间内
                  }
                }

                // 综合判断：API 明确说休息，或者不在营业时段内，则置为休息中
                if (apiTag.contains('休息') || !isInBusinessHours) {
                  status = '休息中';
                } else {
                  status = '营业中';
                }
              }
            }

            // 将高德 API 返回的数据映射到 VenueModel
            return VenueModel(
              imageUrl: (poi['photos'] != null && poi['photos'] is List && poi['photos'].isNotEmpty) 
                  ? (poi['photos'][0] is Map ? poi['photos'][0]['url']?.toString() ?? 'https://picsum.photos/seed/${poi['id']}/400/300' : 'https://picsum.photos/seed/${poi['id']}/400/300')
                  : 'https://picsum.photos/seed/${poi['id']}/400/300', // 没有图片用随机占位
              name: poi['name']?.toString() ?? '未知场馆',
              score: venueScore,
              tags: [poi['type']?.toString().split(';').last ?? '台球馆'],
              address: poi['address']?.toString() ?? '',
              distance: distanceStr,
              status: status,
              businessHours: businessHours.isNotEmpty ? businessHours : null,
              promotion: '到店领取可乐一瓶', // 补回静态展示
              buttonText: '去约球',
              buttonEnabled: status == '营业中' || status == '', // 如果没有状态也允许点击
            );
          }).toList();
          
          // 对结果进行排序
          if (_currentSort == '好评优先') {
            realVenues.sort((a, b) => b.score.compareTo(a.score));
          } else if (_currentSort == '距离优先') {
            realVenues.sort((a, b) {
              double distA = _parseDistance(a.distance);
              double distB = _parseDistance(b.distance);
              return distA.compareTo(distB);
            });
          }
        }
    } catch (e) {
      print('解析周边场馆数据出错: $e');
    }

    // 2. 移除写死的本地 JSON 数据，只返回真实周边场馆
    return realVenues;
  }

  // 辅助方法：将字符串距离转换为米用于排序比较
  double _parseDistance(String distStr) {
    if (distStr.endsWith('km')) {
      return (double.tryParse(distStr.replaceAll('km', '')) ?? 0) * 1000;
    } else if (distStr.endsWith('m')) {
      return double.tryParse(distStr.replaceAll('m', '')) ?? 0;
    }
    return 0;
  }

  void _toggleLocationFilter() {
    setState(() {
      _isLocationFilterOpen = !_isLocationFilterOpen;
      _isSortFilterOpen = false;
      if (_isLocationFilterOpen) {
        _tempLocationFilterType = _locationFilterType;
        _tempSelectedRadius = _selectedRadius;
      }
    });
  }

  void _toggleSortFilter() {
    setState(() {
      _isSortFilterOpen = !_isSortFilterOpen;
      _isLocationFilterOpen = false;
    });
  }

  void _closeAllFilters() {
    setState(() {
      _isLocationFilterOpen = false;
      _isSortFilterOpen = false;
    });
  }

  Widget _buildDropdownOverlay() {
    if (!_isLocationFilterOpen && !_isSortFilterOpen) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 遮罩层
        GestureDetector(
          onTap: _closeAllFilters,
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // 下拉内容
        Container(
          color: Colors.white,
          width: double.infinity,
          child: _isLocationFilterOpen ? _buildLocationDropdownContent() : _buildSortDropdownContent(),
        ),
      ],
    );
  }

  Widget _buildLocationDropdownContent() {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          // 中间内容区 (左侧菜单 + 右侧内容)
          Expanded(
            child: Row(
              children: [
                // 左侧菜单
                Container(
                  width: 100,
                  color: Colors.grey[100],
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildLeftMenuItem('我的附近', _tempLocationFilterType, () {
                        setState(() => _tempLocationFilterType = '我的附近');
                      }),
                      _buildLeftMenuItem('指定地址', _tempLocationFilterType, () {
                        setState(() => _tempLocationFilterType = '指定地址');
                      }),
                    ],
                  ),
                ),
                
                // 右侧内容
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _tempLocationFilterType == '我的附近' 
                        ? _buildNearbyOptions(_tempSelectedRadius, (val) {
                            setState(() => _tempSelectedRadius = val);
                          })
                        : _buildCustomAddressOption(),
                  ),
                ),
              ],
            ),
          ),
          
          // 底部按钮
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _tempLocationFilterType = '我的附近';
                        _tempSelectedRadius = 3000;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('重置', style: TextStyle(color: Colors.black87, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _locationFilterType = _tempLocationFilterType;
                        _selectedRadius = _tempSelectedRadius;
                        
                        // 更新筛选栏显示的文本
                        if (_locationFilterType == '指定地址') {
                          _locationDisplayText = '指定地址';
                        } else {
                          if (_selectedRadius < 1000) {
                            _locationDisplayText = '附近${_selectedRadius}m';
                          } else {
                            _locationDisplayText = '附近${_selectedRadius ~/ 1000}km';
                        }
                      }

                      _loadData(isRefresh: true); // 重新加载数据
                      _isLocationFilterOpen = false;
                    });
                  },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0500FA),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('确定', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdownContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(
            '距离优先', 
            style: TextStyle(
              fontSize: 16, 
              color: _currentSort == '距离优先' ? const Color(0xFF0500FA) : Colors.black87,
              fontWeight: _currentSort == '距离优先' ? FontWeight.bold : FontWeight.normal
            )
          ),
          trailing: _currentSort == '距离优先' ? const Icon(Icons.check, color: Color(0xFF0500FA)) : null,
          onTap: () {
            setState(() {
              _currentSort = '距离优先';
              _loadData(isRefresh: true);
              _isSortFilterOpen = false;
            });
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(
            '好评优先', 
            style: TextStyle(
              fontSize: 16, 
              color: _currentSort == '好评优先' ? const Color(0xFF0500FA) : Colors.black87,
              fontWeight: _currentSort == '好评优先' ? FontWeight.bold : FontWeight.normal
            )
          ),
          trailing: _currentSort == '好评优先' ? const Icon(Icons.check, color: Color(0xFF0500FA)) : null,
          onTap: () {
            setState(() {
              _currentSort = '好评优先';
              _loadData(isRefresh: true);
              _isSortFilterOpen = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLeftMenuItem(String title, String currentType, VoidCallback onTap) {
    bool isSelected = title == currentType;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: isSelected ? Colors.white : Colors.transparent,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF0500FA) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyOptions(int currentRadius, Function(int) onSelect) {
    final options = [
      {'label': '500m', 'value': 500},
      {'label': '1km', 'value': 1000},
      {'label': '3km', 'value': 3000},
      {'label': '5km', 'value': 5000},
      {'label': '10km', 'value': 10000},
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final label = option['label'] as String;
        final value = option['value'] as int;
        final isSelected = currentRadius == value;

        return InkWell(
          onTap: () => onSelect(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? const Color(0xFF0500FA) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Color(0xFF0500FA), size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAddressOption() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('当前定位', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF0500FA), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _currentFullAddress.isNotEmpty ? _currentFullAddress : '正在获取定位...',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddressSelectPage(currentCity: _currentCity),
                  ),
                );

                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    _currentFullAddress = result['name'] ?? result['address'] ?? '';
                    _customLatitude = result['latitude'];
                    _customLongitude = result['longitude'];
                    
                    // 自动选择“指定地址”类型并刷新
                    _tempLocationFilterType = '指定地址';
                  });
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0500FA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('修改地址', style: TextStyle(color: Color(0xFF0500FA), fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationFilter() {
    _toggleLocationFilter();
  }

  void _showSortFilter() {
    _toggleSortFilter();
  }

  // 筛选栏按钮组件（复用原有逻辑）
  Widget _buildFilterChip(String text, {bool isDropdown = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: Colors.grey[600]),
          if (icon != null) const SizedBox(width: 2),
          Flexible(
            child: Text(
              text, 
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDropdown) const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // 筛选栏
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showLocationFilter,
                      child: _buildFilterChip(_locationDisplayText, isDropdown: true, icon: Icons.location_on),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showSortFilter,
                      child: _buildFilterChip(_currentSort, isDropdown: true),
                    ),
                  ],
                ),
              ),
              // 场馆列表（支持下拉刷新与上拉加载）
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) // 首次加载动画
                  : (_venueList.isEmpty 
                      ? const Center(child: Text("暂无场馆数据")) 
                      : RefreshIndicator(
                          onRefresh: () => _loadData(isRefresh: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
                            physics: const AlwaysScrollableScrollPhysics(), // 确保内容少也能下拉刷新
                            itemCount: _venueList.length + 1, // +1 用于显示底部加载状态
                            itemBuilder: (context, index) {
                              // 渲染到底部加载指示器
                              if (index == _venueList.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: _hasMore 
                                      ? const SizedBox(
                                          width: 24, 
                                          height: 24, 
                                          child: CircularProgressIndicator(strokeWidth: 2)
                                        )
                                      : const Text('没有更多商家了', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ),
                                );
                              }
                              
                              // 渲染正常的场馆卡片
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: VenueCard(venueData: _venueList[index]),
                              );
                            },
                          ),
                        )
                    ),
              ),
            ],
          ),
          
          // 下拉菜单层 (位于列表上方，筛选栏下方)
          if (_isLocationFilterOpen || _isSortFilterOpen)
            Positioned(
              top: 50, // 筛选栏的高度，约50px
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildDropdownOverlay(),
            ),
        ],
      ),
    );
  }
}