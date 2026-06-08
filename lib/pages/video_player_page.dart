import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? userName;
  final String? avatarUrl;
  final String? content;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    this.userName,
    this.avatarUrl,
    this.content,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isFastForwarding = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoUrl));
    }

    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
      _controller.setLooping(true);
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _startFastForward() {
    setState(() {
      _isFastForwarding = true;
      _controller.setPlaybackSpeed(3.0); // 3倍速快进
    });
  }

  void _stopFastForward() {
    setState(() {
      _isFastForwarding = false;
      _controller.setPlaybackSpeed(1.0); // 恢复正常语速
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        onDoubleTap: _togglePlayPause,
        onLongPressStart: (_) => _startFastForward(),
        onLongPressEnd: (_) => _stopFastForward(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 视频画面居中
            if (_controller.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const CircularProgressIndicator(color: Colors.white),

            // 快进提示
            if (_isFastForwarding)
              Positioned(
                top: 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fast_forward, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text("正在快进 3X", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),

            // 渐变背景（为了文字清晰）
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 300,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 用户信息和文字内容 (左下角)
            Positioned(
              bottom: 40, // 进度条上方
              left: 15,
              right: 80, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.userName != null || widget.avatarUrl != null)
                    Row(
                      children: [
                        if (widget.avatarUrl != null)
                          ClipOval(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: widget.avatarUrl!.startsWith('http')
                                  ? Image.network(
                                      widget.avatarUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.person, color: Colors.white),
                                    )
                                  : Image.asset(
                                      widget.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.person, color: Colors.white),
                                    ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        if (widget.userName != null)
                          Text(
                            '@${widget.userName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  if (widget.content != null)
                    Text(
                      widget.content!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                ],
              ),
            ),

            // 返回按钮
            Positioned(
              top: 40,
              left: 10,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // 暂停状态图标显示
            if (!_controller.value.isPlaying && !_isFastForwarding)
              IgnorePointer(
                child: Icon(
                  Icons.play_arrow,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),

            // 底部贴底进度条
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: VideoProgressColors(
                  playedColor: const Color(0xFF0500FA),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
