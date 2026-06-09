import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';

class InviteDetailPage extends StatefulWidget {
  final String inviteId;
  final String location;

  const InviteDetailPage({super.key, required this.inviteId, this.location = ''});

  @override
  State<InviteDetailPage> createState() => _InviteDetailPageState();
}

class _InviteDetailPageState extends State<InviteDetailPage> {
  List<dynamic> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11811&inviteid=${widget.inviteId}');
      final response = await http.get(url);
      
      print('加入者列表接口响应: ${response.body}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        
        // Handle different possible JSON structures (List or Map containing List)
        List<dynamic> participantsList = [];
        if (data is List) {
          participantsList = data;
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          participantsList = data['data'];
        } else if (data is Map) {
          // Sometimes single object is returned instead of list if there's only one
          participantsList = [data];
        }

        // 过滤掉 time 为空的加入者
        participantsList = participantsList.where((item) {
          if (item is! Map) return false;
          final time = item['time']?.toString() ?? '';
          return time.isNotEmpty;
        }).toList();

        setState(() {
          _participants = participantsList;
        });
      } else {
        setState(() {
          _errorMessage = '服务器错误: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '获取数据失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getAvatarUrl(String? headimg) {
    if (headimg == null || headimg.isEmpty) {
      return 'https://picsum.photos/200/200?random=user';
    }
    return 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$headimg';
  }

  Future<void> _handleAction(String participatorId, int isConsent) async {
    try {
      // 显示 loading 弹窗 (可选)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 获取本地存储的 itsid
      String? itsid = await DataStorage.loadItsid();
      String baseUrl = 'https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11808';
      if (itsid != null && itsid.isNotEmpty) {
        baseUrl += '&itsid=$itsid';
      }
      final url = Uri.parse(baseUrl);
      final requestBody = {
        "Participatorid": participatorId,
        "Isconsent": isConsent,
        "Inviteid": widget.inviteId,
        "location": widget.location,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (mounted) {
        Navigator.pop(context); // 关掉 loading
      }

      if (response.statusCode == 200) {
        if (mounted) {
          String message = '操作成功';
          if (isConsent == 1) {
            message = '已同意待支付';
          } else if (isConsent == -1) {
            message = '已拒绝加入';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        // 操作成功后刷新列表
        _fetchParticipants();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失败，服务器状态码: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关掉 loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作异常: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('加入者列表', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _participants.isEmpty
                  ? const Center(child: Text('暂无成员加入', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final participant = _participants[index];
                        final headimg = participant['headimg']?.toString();
                        final username = participant['username']?.toString() ?? '未知用户';
                        final isConsent = participant['isconsent']?.toString() ?? '0';
                        final time = participant['time']?.toString() ?? '';
                        final participatorId = participant['userid']?.toString() ?? '';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[300]!, width: 1),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    _getAvatarUrl(headimg),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person, size: 30, color: Colors.grey[400]);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '申请时间: $time',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Actions
                              if (isConsent == '-1')
                                const Text(
                                  '已拒绝加入',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else if (isConsent == '1')
                                const Text(
                                  '已同意待支付',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else if (isConsent == '2')
                                const Text(
                                  '已同意已支付',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        if (participatorId.isNotEmpty) {
                                          _handleAction(participatorId, -1);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法获取参与者ID')));
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('拒绝', style: TextStyle(fontSize: 13)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (participatorId.isNotEmpty) {
                                          _handleAction(participatorId, 1);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法获取参与者ID')));
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        elevation: 0,
                                      ),
                                      child: const Text('同意', style: TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
