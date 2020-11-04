import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'pub.dart';

const APP_BAR_HEIGHT = 44.0;

// 播放视频
Future playVideo(BuildContext context, String videoUrl, [String title]) {
  return showDialog(
    context: context,
    builder: (context) => VideoPlayerWidget(videoUrl: videoUrl, title: title),
  );
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerWidget({Key key, @required this.videoUrl, this.title})
      : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController _controller;
  StreamController<bool> _playingStreamController; // 是否显示标题栏和控制栏
  StreamController<bool> _layoutStreamController; // 是否播放中
  StreamController<int> _playingProgressStreamController; // 播放进度
  StreamController<int> _seekProgressStreamController; // 拖动进度
  StreamController<bool> _fullScreenStreamController; // 全屏
  bool _showLayout = true;
  bool _fullScreen = false;
  String title;

  @override
  void initState() {
    _playingStreamController = StreamController.broadcast();
    _layoutStreamController = StreamController.broadcast();
    _playingProgressStreamController = StreamController.broadcast();
    _seekProgressStreamController = StreamController();
    _fullScreenStreamController = StreamController.broadcast();
    // 初始化
    if (widget.videoUrl?.isNotEmpty != true) {
      Navigator.of(context).pop();
      return;
    }
    title = widget.title ?? '视频播放';
    _controller = widget.videoUrl.startsWith(RegExp("http[s]://"))
        ? VideoPlayerController.network(widget.videoUrl)
        : VideoPlayerController.file(File(widget.videoUrl));
    _controller.initialize().then((_) => setState(() {}));
    _controller.addListener(() {
      _controller.position.then((duration) {
        if (!_playingProgressStreamController.isClosed &&
            !_playingProgressStreamController.isPaused) {
          _playingProgressStreamController.add(duration?.inSeconds ?? 0);
        }
      });
      if (!_playingStreamController.isClosed &&
          !_playingStreamController.isPaused) {
        _playingStreamController.add(_controller.value.isPlaying);
      }
    });
    // 播放状态监听
    _playingStreamController.stream.listen((data) {
      if (!_controller.value.initialized) return;
      if (data && _controller.value.isPlaying) return;
      if (!data && !_controller.value.isPlaying) return;
      if (data) {
        _controller.play();
        if (_controller.value.position.inMilliseconds ==
            _controller.value.duration.inMilliseconds) {
          _controller.seekTo(Duration(seconds: 0));
        }
      } else {
        _controller.pause();
      }
    });
    // 拖动
    _seekProgressStreamController.stream.listen((data) {
      if (_controller != null && _controller.value.initialized)
        _controller.seekTo(Duration(seconds: data));
    });
    // 全屏
    _fullScreenStreamController.stream.listen((data) {
      if (_fullScreen == data) return;
      _fullScreen = data;
      SystemChrome.setPreferredOrientations(_fullScreen
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    });
    super.initState();
  }

  @override
  void dispose() {
    _playingStreamController.close();
    _layoutStreamController.close();
    _playingProgressStreamController.close();
    _seekProgressStreamController.close();
    _fullScreenStreamController.close();
    _controller?.dispose();
    if (_fullScreen) {
      SystemChrome.setPreferredOrientations([]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // 视频
            _controller.value.initialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller))
                : Container(),
            // 点击视频控制栏显示隐藏
            Positioned.fill(
              child: InkWell(
                onTap: () {
                  _showLayout = !_showLayout;
                  if (!_layoutStreamController.isClosed &&
                      !_layoutStreamController.isPaused) {
                    _layoutStreamController.add(_showLayout);
                  }
                },
              ),
            ),
            // 播放按钮
            StreamBuilder<bool>(
                initialData: false,
                stream: _playingStreamController.stream,
                builder: (_, snapshot) {
                  if (snapshot.data) return Container();
                  return FlatButton(
                    child: Icon(Icons.play_circle_filled,
                        color: Colors.white, size: 50.0),
                    onPressed: () {
                      if (!_playingStreamController.isClosed &&
                          !_playingStreamController.isPaused) {
                        _playingStreamController.add(true);
                      }
                      if (_showLayout) {
                        _showLayout = false;
                        if (!_layoutStreamController.isClosed &&
                            !_layoutStreamController.isPaused) {
                          _layoutStreamController.add(false);
                        }
                      }
                    },
                  );
                }),
            // 标题栏
            StreamBuilder<bool>(
              initialData: _showLayout,
              stream: _layoutStreamController.stream,
              builder: (_, snapshot) {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: 0,
                  right: 0,
                  top: snapshot.data ? 0 : -APP_BAR_HEIGHT - statusBarHeight,
                  child: _TitleBar(title),
                );
              },
            ),
            // 控制栏
            StreamBuilder<bool>(
              initialData: _showLayout,
              stream: _layoutStreamController.stream,
              builder: (_, snapshot) {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: 0,
                  right: 0,
                  bottom: snapshot.data ? 0 : -APP_BAR_HEIGHT,
                  child: _ControllerBar(
                    playingStreamController: _playingStreamController,
                    playingProgressStreamController:
                        _playingProgressStreamController,
                    seekProgressStreamController: _seekProgressStreamController,
                    fullScreenStreamController: _fullScreenStreamController,
                    maxDuration: _controller.value.duration?.inSeconds ?? 0,
                    showFullScreen: _controller.value.aspectRatio < 1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 标题栏
class _TitleBar extends StatelessWidget {
  final String title;

  const _TitleBar(this.title);

  @override
  Widget build(BuildContext context) {
    var statusBarHeight = MediaQuery.of(context).padding.top;
    const btnSize = APP_BAR_HEIGHT / 2;
    const btnPadding = APP_BAR_HEIGHT / 4;
    return Container(
      color: Color.fromARGB(150, 0, 0, 0),
      height: APP_BAR_HEIGHT + statusBarHeight,
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 返回按钮
          Positioned(
            left: 0,
            top: 0,
            child: FlatButton(
              child: Icon(Icons.arrow_back, color: Colors.white, size: btnSize),
              padding: EdgeInsets.all(btnPadding),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // 标题
          Text(
            title ?? "视频播放",
            style: TextStyle(
                color: Colors.white,
                fontSize: Theme.of(context).textTheme.headline6.fontSize),
          ),
        ],
      ),
    );
  }
}

// 控制栏
// ignore: must_be_immutable
class _ControllerBar extends StatelessWidget {
  final StreamController<bool> playingStreamController; // 是否播放中
  final StreamController<int> playingProgressStreamController; // 播放进度
  final StreamController<int> seekProgressStreamController; // 拖动进度
  final StreamController<bool> fullScreenStreamController; // 全屏
  final int maxDuration;
  final bool showFullScreen;
  bool _playing = false;
  bool _fullScreen = false;

  _ControllerBar({
    @required this.playingStreamController,
    @required this.playingProgressStreamController,
    @required this.seekProgressStreamController,
    this.fullScreenStreamController,
    @required this.maxDuration,
    this.showFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    const btnSize = APP_BAR_HEIGHT / 2;
    const btnPadding = APP_BAR_HEIGHT / 4;
    return Container(
      color: Color.fromARGB(150, 0, 0, 0),
      height: APP_BAR_HEIGHT,
      child: Row(
        children: <Widget>[
          // 播放按钮
          FlatButton(
            child: StreamBuilder<bool>(
              initialData: false,
              stream: playingStreamController.stream,
              builder: (_, snapshot) {
                _playing = snapshot.data;
                return Icon(
                  _playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: btnSize,
                );
              },
            ),
            padding: EdgeInsets.all(btnPadding),
            onPressed: () {
              if (!playingStreamController.isClosed &&
                  !playingStreamController.isPaused) {
                playingStreamController.add(!_playing);
              }
            },
          ),
          // 当前进度
          StreamBuilder<int>(
            initialData: 0,
            stream: playingProgressStreamController.stream,
            builder: (_, snapshot) => Text(
              secondsToTime(snapshot.data),
              style: TextStyle(color: Colors.white, fontSize: 12.0),
            ),
          ),
          // 进度条
          Expanded(
            child: StreamBuilder<int>(
              initialData: 0,
              stream: playingProgressStreamController.stream,
              builder: (_, snapshot) => Slider(
                value: snapshot.data.toDouble(),
                min: 0,
                max: maxDuration.toDouble(),
                onChanged: (data) {
                  if (!seekProgressStreamController.isClosed &&
                      !seekProgressStreamController.isPaused) {
                    seekProgressStreamController.add(data.toInt());
                  }
                },
              ),
            ),
          ),
          // 总时长
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              secondsToTime(maxDuration),
              style: TextStyle(color: Colors.white, fontSize: 12.0),
            ),
          ),
          // 全屏按钮
          if (showFullScreen == true && fullScreenStreamController != null)
            FlatButton(
              child: StreamBuilder(
                initialData: _fullScreen,
                stream: fullScreenStreamController.stream,
                builder: (_, snapshot) {
                  _fullScreen = snapshot.data;
                  return Icon(
                    _fullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                    size: btnSize,
                  );
                },
              ),
              onPressed: () {
                if (!fullScreenStreamController.isClosed &&
                    !fullScreenStreamController.isPaused) {
                  _fullScreen = !_fullScreen;
                  fullScreenStreamController.add(_fullScreen);
                }
              },
            ),
        ],
      ),
    );
  }
}
