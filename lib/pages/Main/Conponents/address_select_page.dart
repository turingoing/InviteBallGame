import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/location_service.dart';
import 'dart:async';

class AddressSelectPage extends StatefulWidget {
  final String currentCity;

  const AddressSelectPage({super.key, required this.currentCity});

  @override
  State<AddressSelectPage> createState() => _AddressSelectPageState();
}

class _AddressSelectPageState extends State<AddressSelectPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await LocationService.searchPOIByKeyword(query, city: widget.currentCity);
      if (mounted) {
        setState(() {
          _searchResults = results ?? [];
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择地址', style: TextStyle(fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 搜索框区域
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜索地点、小区、大厦等',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // 结果列表
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? const Center(child: Text('未找到相关地址', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final poi = _searchResults[index];
                          final name = poi['name']?.toString() ?? '未知地点';
                          final address = poi['address']?.toString() ?? '';
                          // 解析经纬度
                          final location = poi['location']?.toString() ?? '';
                          double? lat;
                          double? lng;
                          if (location.isNotEmpty && location.contains(',')) {
                            final parts = location.split(',');
                            if (parts.length == 2) {
                              lng = double.tryParse(parts[0]);
                              lat = double.tryParse(parts[1]);
                            }
                          }
                          
                          return ListTile(
                            tileColor: Colors.white,
                            leading: const Icon(Icons.location_on, color: Colors.grey),
                            title: Text(name, style: const TextStyle(fontSize: 16)),
                            subtitle: address.isNotEmpty && address != '[]' 
                                ? Text(address, style: const TextStyle(fontSize: 13, color: Colors.grey))
                                : null,
                            onTap: () {
                              // 返回选中的地址和坐标
                              Navigator.pop(context, {
                                'name': name,
                                'address': address,
                                'latitude': lat,
                                'longitude': lng,
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}