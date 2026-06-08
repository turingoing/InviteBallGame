import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_application_1/api/competition_api.dart';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/utils/location_service.dart';
import 'package:geolocator/geolocator.dart';

// ------------------------------
// 3. 发布比赛页（本次新增，完整实现）
// ------------------------------
class PublishCompetitionPage extends StatefulWidget {
  const PublishCompetitionPage({super.key});

  @override
  State<PublishCompetitionPage> createState() => _PublishCompetitionPageState();
}

class _PublishCompetitionPageState extends State<PublishCompetitionPage> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _participantController = TextEditingController(text: '1');
  final TextEditingController _locationController = TextEditingController();
  String _selectedGameType = '中式八球';
  int _participantCount = 1;
  int skillLevel = 0;
  String location = '';
  DateTime? starttime;
  DateTime? endtime;
  File? _posterImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _submitMessage;

  // 搜索相关状态
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _eventNameController.dispose();
    _noteController.dispose();
    _participantController.dispose();
    _locationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 搜索商家
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);

      try {
        Position? position = await LocationService.getCurrentLocation();
        if (position != null) {
          final results = await LocationService.searchNearbyPOI(
            query,
            position.latitude,
            position.longitude,
          );
          setState(() {
            _searchResults = results ?? [];
          });
        }
      } catch (e) {
        print('搜索商家失败: $e');
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  String _getSkillLevelText() {
    if (skillLevel == 0) {
      return '无要求';
    }
    return '等级 $skillLevel';
  }

  void _showSkillLevelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择球技要求',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSkillOption(0, '无要求'),
                  for (int i = 1; i <= 10; i++) _buildSkillOption(i, '等级 $i'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillOption(int level, String label) {
    final isSelected = skillLevel == level;
    return InkWell(
      onTap: () {
        setState(() {
          skillLevel = level;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '请选择时间';
    return DateFormat('MM月dd日 HH:mm').format(dt);
  }

  String _getTimeRangeText() {
    if (starttime == null && endtime == null) {
      return '请选择起止时间';
    } else if (starttime != null && endtime != null) {
      return '${_formatDateTime(starttime)} - ${_formatDateTime(endtime)}';
    } else if (starttime != null) {
      return '${_formatDateTime(starttime)} - 请选择结束时间';
    } else {
      return '请选择开始时间 - ${_formatDateTime(endtime)}';
    }
  }

  Future<void> _selectDateTime(bool isStart) async {
    final DateTime initialDate = isStart
        ? (starttime ?? DateTime.now())
        : (endtime ?? starttime ?? DateTime.now());
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            starttime = selectedDateTime;
            if (endtime != null && endtime!.isBefore(starttime!)) {
              endtime = null;
            }
          } else {
            endtime = selectedDateTime;
          }
        });
      }
    }
  }

  void _showDateTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择起止时间',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('开始时间'),
                subtitle: Text(
                  _formatDateTime(starttime),
                  style: TextStyle(
                    fontSize: 16,
                    color: starttime != null ? Colors.black : Colors.grey,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _selectDateTime(true);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('结束时间'),
                subtitle: Text(
                  _formatDateTime(endtime),
                  style: TextStyle(
                    fontSize: 16,
                    color: endtime != null ? Colors.black : Colors.grey,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _selectDateTime(false);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // 选择图片（相册/相机）
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _posterImage = File(pickedFile.path);
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String?> _uploadPosterImage(File imageFile, String compid) async {
    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileExtension = imageFile.path.split('.').last;
      String imageName = '${timestamp}_${DateTime.now().microsecond}.$fileExtension';

      final url = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx?mbid=5015&ituid=118');
      var request = http.MultipartRequest('POST', url);

      var file = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: imageName,
      );
      request.files.add(file);

      request.fields['filepath'] = 'images\\singeravatar';
      request.fields['filename1'] = imageName;
      request.fields['url'] = imageName;
      request.fields['compid'] = compid;

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();
      print('比赛宣传图上传响应: $responseBody');

      if (response.statusCode == 200) {
        return imageName;
      } else {
        return null;
      }
    } catch (e) {
      print('上传宣传图异常: $e');
      return null;
    }
  }

  Future<void> _submitMatch() async {
    if (_locationController.text.isEmpty) {
      _showError('请输入活动地点');
      return;
    }
    if (starttime == null) {
      _showError('请选择开始时间');
      return;
    }
    if (endtime == null) {
      _showError('请选择结束时间');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitMessage = '提交中...';
    });

    try {
      int compid = await DataStorage.getAndIncrementPostId();
      print('比赛帖子ID: $compid');

      String? imgurl;
      if (_posterImage != null) {
        imgurl = await _uploadPosterImage(_posterImage!, compid.toString());
        print('宣传图文件名: $imgurl');
      }

      final response = await CompetitionApi.submitMatch(
        location: _locationController.text,
        compname: _eventNameController.text,
        note: _noteController.text,
        starttime: starttime!,
        endtime: endtime!,
        participantcount: _participantCount,
        skilllevel: skillLevel,
        gametype: CompetitionApi.getGameTypeCode(_selectedGameType),
        imgurl: imgurl,
        compid: compid,
      );

      setState(() {
        _submitMessage = '发布成功！';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('比赛发布成功！')),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _submitMessage = '发布失败: $e';
      });
      _showError('发布失败: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight:45,
        scrolledUnderElevation: 0, // 滚动时不抬高
        surfaceTintColor: Colors.transparent, // 取消滚动变色

        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '发布比赛',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 活动名称输入框
            const Text(
              '活动名称',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                hintText: '请输入赛事名称',
                hintStyle: TextStyle(fontSize: 20, color: Color(0xFF9E9E9E)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
              style: const TextStyle(fontSize: 20, color: Colors.black),
            ),
            const SizedBox(height: 8),

            // 2. 活动地点选择
            _buildLocationItem(colorScheme),
            const SizedBox(height: 0),

            // 3. 起止时间选择
            _buildTimeRangeItem(colorScheme),
            const SizedBox(height: 12),

            // 4. 约球类型选择
            const Text(
              '约球类型',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            _buildGameTypeSelector(colorScheme),
            const SizedBox(height: 12),

            // 5. 参与人数 & 球技要求（双栏）
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '参与人数',
                          style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _participantController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final int? parsedValue = int.tryParse(value);
                            if (parsedValue != null) {
                              if (parsedValue < 1) {
                                _participantController.text = '1';
                                _participantCount = 1;
                              } else if (parsedValue > 128) {
                                _participantController.text = '128';
                                _participantCount = 128;
                              } else {
                                _participantCount = parsedValue;
                              }
                              _participantController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _participantController.text.length),
                              );
                            }
                          },
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '1-128',
                            hintStyle: TextStyle(fontSize: 20, color: Color(0xFF9E9E9E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputItem(
                    title: '球技要求',
                    value: _getSkillLevelText(),
                    suffixIcon: Icons.swap_vert,
                    onTap: _showSkillLevelPicker,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. 活动备注
            const Text(
              '活动备注',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '请输入比赛相关的备注信息，如奖品设置、场地细节等...',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 12),

            // 7. 比赛宣传图上传
            const Text(
              '比赛宣传图',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 10),
            _buildPosterUploader(colorScheme),
            const SizedBox(height: 12),

            // 8. 说明文字
            Text(
              '* 说明：需缴纳 10元 押金，押金将在比赛结束后原路退还至用户账户；爽约将扣除押金作为违约金赔付给发起方。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // 9. 立即发布比赛按钮
            _buildPublishButton(colorScheme),
          ],
        ),
      ),
    );
  }

  // 活动地点组件
  Widget _buildLocationItem(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '活动地点',
                      style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _locationController,
                      onChanged: (value) {
                        setState(() {
                          location = value;
                        });
                        _onSearchChanged(value);
                      },
                      maxLength: 50,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: '搜索商家/地点',
                        hintStyle: TextStyle(fontSize: 20, color: Color(0xFF9E9E9E)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final poi = _searchResults[index];
                  return ListTile(
                    title: Text(poi['name'] ?? '未知商家'),
                    subtitle: Text(poi['address'] is String ? poi['address'] : '地址未知', maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      setState(() {
                        _locationController.text = poi['name'];
                        location = poi['name'];
                        _searchResults = [];
                      });
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // 起止时间组件
  Widget _buildTimeRangeItem(ColorScheme colorScheme) {
    return InkWell(
      onTap: _showDateTimePicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time_outlined,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '起止时间',
                    style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeRangeText(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  // 约球类型选择器
  Widget _buildGameTypeSelector(ColorScheme colorScheme) {
    final gameTypes = ['中式八球', '斯诺克', '九球', '四球', '六球', '其他'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: gameTypes.map((type) {
        final isSelected = type == _selectedGameType;
        return InkWell(
          onTap: () => setState(() => _selectedGameType = type),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 双栏输入项组件
  Widget _buildInputItem({
    required String title,
    required String value,
    required IconData suffixIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Icon(suffixIcon, color: Colors.grey[400], size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 海报上传组件
  Widget _buildPosterUploader(ColorScheme colorScheme) {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: _posterImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _posterImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: colorScheme.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '上传比赛海报',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '建议尺寸 16:9，支持 JPG/PNG',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // 发布按钮
  Widget _buildPublishButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    '立即发布比赛',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 24),
                ],
              ),
      ),
    );
  }
}
