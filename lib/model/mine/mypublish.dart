/// 我的发布 - 活动数据模型
class PublishActivity {
  final String title;
  final String activityName;
  final String date;
  final String location;
  final bool isUsed;
  final int? participantCount;
  final int? totalCount;
  final bool? depositReturned;
  
  // 新增字段
  final String? itieId;
  final String? gameType;
  final String? feeMode;
  final String? note;
  
  // 新接口字段
  final String? userid;
  final String? skilllevel;
  final String? inviteid;

  PublishActivity({
    this.title = '',
    required this.activityName,
    required this.date,
    required this.location,
    required this.isUsed,
    this.participantCount,
    this.totalCount,
    this.depositReturned,
    // 新增字段
    this.itieId,
    this.gameType,
    this.feeMode,
    this.note,
    // 新接口字段
    this.userid,
    this.skilllevel,
    this.inviteid,
  });

  // 约球类型名称
  String get gameTypeName {
    switch (gameType) {
      case '0': return '中式八球';
      case '1': return '斯诺克';
      case '2': return '九球';
      case '3': return '六球';
      case '4': return '四球';
      case '5': return '其他';
      default: return '未知';
    }
  }

  // 费用模式名称
  String get feeModeName {
    switch (feeMode) {
      case '0': return 'AA制';
      case '1': return '败方付';
      case '2': return '胜方付';
      case '3': return '对方付';
      default: return '未知';
    }
  }

  // 球技等级名称
  String get skillLevelName {
    switch (skilllevel) {
      case '0': return '不限';
      case '1': return '新手';
      case '2': return '业余';
      case '3': return '业余进阶';
      case '4': return '业余高手';
      case '5': return '职业';
      default: return '未知';
    }
  }

  // 获取解析后的时间对象
  DateTime? get parsedDate {
    if (date.isEmpty) return null;
    try {
      String timeStr = date.replaceAll('/', '-');
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
          
          return DateTime.parse('$y-$m-$d $h:$min:$sec');
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 判断是否超过约球时间24小时
  bool get isExpired24h {
    final parsed = parsedDate;
    if (parsed == null) return false;
    // 判断当前时间是否大于约定时间 + 24小时
    return DateTime.now().isAfter(parsed.add(const Duration(hours: 24)));
  }

  // JSON 转 Model
  factory PublishActivity.fromJson(Map<String, dynamic> json) {
    int? parseParticipantCount() {
      dynamic count = json['participantcount'] ?? json['participantCount'];
      if (count != null) {
        return int.tryParse(count.toString());
      }
      return null;
    }
    
    return PublishActivity(
      title: json['title'] as String? ?? '',
      activityName: json['activityName'] as String? ?? json['location'] as String? ?? '未知活动',
      date: json['date'] as String? ?? json['time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      isUsed: json['isUsed'] as bool? ?? false,
      participantCount: parseParticipantCount(),
      totalCount: json['totalCount'] != null
          ? int.tryParse(json['totalCount'].toString())
          : parseParticipantCount(),
      depositReturned: json['depositReturned'] as bool? ?? false,
      itieId: json['itieId'] as String? ?? json['id'] as String? ?? json['inviteid'] as String?,
      gameType: json['gameType'] as String? ?? json['gametype'] as String?,
      feeMode: json['feeMode'] as String? ?? json['feemode'] as String?,
      note: json['note'] as String? ?? json['node'] as String? ?? '',
      userid: json['userid'] as String?,
      skilllevel: json['skilllevel'] as String?,
      inviteid: json['inviteid'] as String?,
    );
  }
}