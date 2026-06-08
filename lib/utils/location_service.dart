import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationResult {
  final String province;
  final String city;
  final String district;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;

  LocationResult({
    required this.province,
    required this.city,
    required this.district,
    this.formattedAddress = '',
    this.latitude,
    this.longitude,
  });
}

class LocationService {
  // 高德 Web 服务 Key
  static const String _amapKey = '00d6dac6a7e0fee573ff4294d53d17ca';

  /// 获取当前位置的经纬度
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 检查定位服务是否开启
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('定位服务未开启');
      return null;
    }

    // 2. 检查并请求权限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('定位权限被拒绝');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('定位权限被永久拒绝');
      return null;
    }

    // 3. 获取当前位置
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('获取当前位置失败: $e');
      return null;
    }
  }

  /// 使用高德 Web API 根据经纬度获取完整的省市区信息
  static Future<LocationResult?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // 注意：高德 API 使用 经度,纬度 (longitude,latitude)
      final url = 'https://restapi.amap.com/v3/geocode/regeo?output=json&location=$longitude,$latitude&key=$_amapKey';
      
      print('请求高德逆地理编码 URL: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['regeocode'] != null) {
          final addressComponent = data['regeocode']['addressComponent'];
          
          String province = addressComponent['province']?.toString() ?? '';
          dynamic cityData = addressComponent['city'];
          String district = addressComponent['district']?.toString() ?? '';
          
          String city = '';
          // 如果 city 字段是空列表 [] 或空字符串，说明是直辖市，此时市的名字与省份相同（或者可以根据需求留空）
          if (cityData == null || (cityData is List && cityData.isEmpty) || (cityData is String && cityData.isEmpty)) {
            city = province;
          } else {
            city = cityData.toString();
          }
          
          // 如果直辖市不想重复显示，也可以在这里做处理。当前逻辑保留完整结构。
          
          // 获取更详细的地址
          String formattedAddress = data['regeocode']['formatted_address']?.toString() ?? '';
          // 有些情况下格式化地址带有省市，我们可以截取掉前缀以保持简洁，或者直接使用
          
          return LocationResult(
            province: province,
            city: city,
            district: district,
            formattedAddress: formattedAddress.isNotEmpty ? formattedAddress : '$province$city$district',
            latitude: latitude,
            longitude: longitude,
          );
        } else {
          print('高德 API 返回错误: ${data['info']}');
        }
      } else {
        print('高德 API 请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('高德逆地理编码异常: $e');
    }
    return null;
  }

  /// 一键获取当前完整地址信息
  static Future<LocationResult?> getCurrentAddress() async {
    Position? position = await getCurrentLocation();
    if (position != null) {
      return await getAddressFromCoordinates(position.latitude, position.longitude);
    }
    return null;
  }

  /// 使用高德周边搜索 API 获取附近的台球馆
  static Future<List<Map<String, dynamic>>?> searchNearbyBilliards(double latitude, double longitude) async {
    return searchNearbyPOI('台球|桌球|台球俱乐部', latitude, longitude, radius: 2000);
  }

  /// 通用的周边搜索方法
  static Future<List<Map<String, dynamic>>?> searchNearbyPOI(String keyword, double latitude, double longitude, {int radius = 50000, int page = 1}) async {
    try {
      // 开启全量扩展 (extensions=all) 以获取更多信息，并支持 page 参数
      final url = 'https://restapi.amap.com/v3/place/around?key=$_amapKey&location=$longitude,$latitude&keywords=${Uri.encodeComponent(keyword)}&radius=$radius&sortrule=distance&offset=20&page=$page&extensions=all';
      
      print('请求高德周边搜索 URL: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['pois'] != null) {
          return List<Map<String, dynamic>>.from(data['pois']);
        } else {
          print('高德周边搜索 API 返回错误: ${data['info']}');
        }
      } else {
        print('高德周边搜索 API 请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('高德周边搜索异常: $e');
    }
    return null;
  }

  /// 关键字搜索 POI (用于地址选择)
  static Future<List<Map<String, dynamic>>?> searchPOIByKeyword(String keyword, {String city = ''}) async {
    try {
      String url = 'https://restapi.amap.com/v3/place/text?key=$_amapKey&keywords=${Uri.encodeComponent(keyword)}&offset=20&page=1';
      if (city.isNotEmpty) {
        url += '&city=${Uri.encodeComponent(city)}';
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['pois'] != null) {
          return List<Map<String, dynamic>>.from(data['pois']);
        }
      }
    } catch (e) {
      print('高德关键字搜索异常: $e');
    }
    return null;
  }
}
