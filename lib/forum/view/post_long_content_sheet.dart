import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../common/models.dart';
import '../../common/extensions.dart';
import '../../common/widgets.dart';
import '../../common/view_images.dart';
import '../../common/play_video_page.dart';
import '../../common/pub.dart';
import 'select_following_page.dart';
import '../model/m.dart';
import '../repository/repository.dart' as repository;

/// 发帖或发长回复的页面，这个用showModalBottomSheet显示，不注册在页面路由里
class PostLongContentSheet extends StatefulWidget {
  static Future show(
    BuildContext context,
    Future<bool> Function(String, List<UploadedFile>) onSend, {
    String defaultText = '',
  }) {
    return showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      context: context,
      builder: (context) => PostLongContentSheet(
        onSend: onSend,
        defaultText: defaultText,
      ),
    );
  }

  final String defaultText;

  /// 发送，参数是文字内容和图片视频列表
  final Future<bool> Function(String, List<UploadedFile>) onSend;

  const PostLongContentSheet({this.defaultText = '', this.onSend});

  @override
  _PostLongContentSheetState createState() => _PostLongContentSheetState();
}

class _PostLongContentSheetState extends State<PostLongContentSheet> {
  TextEditingController _controller;
  StreamController<List> _imgSc;
  StreamController<String> _videoSc;
  List<String> imgPaths;
  String videoPath;
  Uint8List videoCover;
  ImagePicker _imagePicker;

  @override
  void initState() {
    _controller = TextEditingController();
    _imgSc = StreamController();
    _videoSc = StreamController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _imgSc.makeSureClosed();
    _videoSc.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenH = size.height;
    final screenW = size.width;
    // 顶行
    Widget top = Stack(
      children: <Widget>[
        // 关闭按钮
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // @好友
            IconButton(
              icon: Icon(Icons.alternate_email),
              onPressed: _onAtFriendClick,
            ),
            // 图片按钮
            IconButton(
              icon: Icon(Icons.image),
              onPressed: _onSelectImgClick,
            ),
            // 视频按钮
            IconButton(
              icon: Icon(Icons.video_call),
              onPressed: _onSelectVideoClick,
            ),
          ],
        ).positioned(),
        // 发送按钮
        ButtonWithIcon(
          text: '发送',
          onPressed: _onSendPressed,
        ).positioned(left: null),
        // 分割线
        Divider().positioned(top: null),
      ],
    );
    // 多行输入框
    Widget input = TextField(
      controller: _controller,
      minLines: 5,
      maxLines: 10,
      maxLength: 500,
      buildCounter: (context, {currentLength, isFocused, maxLength}) =>
          Text('$currentLength/$maxLength'),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 8.0,
        ),
        fillColor: Colors.grey[100],
        filled: true,
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          borderSide: BorderSide(color: Colors.transparent),
        ),
      ),
    );
    // 图片
    Widget images = StreamBuilder<List>(
      initialData: imgPaths,
      stream: _imgSc.stream,
      builder: (context, snapshot) {
        if (snapshot.data == null || snapshot.data.isEmpty) return Container();
        return Flexible(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
            children: <Widget>[
              for (var i = 0; i < snapshot.data.length; i++)
                Stack(
                  children: <Widget>[
                    // 图片
                    ImageWithUrl(
                      snapshot.data[i],
                      fit: BoxFit.cover,
                      onPressed: () => viewImages(context, snapshot.data, i),
                    ),
                    // 删除按钮
                    IconButton(
                      icon: Icon(Icons.delete),
                      color: Colors.white,
                      onPressed: () {
                        imgPaths.removeAt(i);
                        _imgSc.add(imgPaths);
                      },
                    ).positioned(left: null, bottom: null),
                  ],
                ),
            ],
          ),
        );
      },
    );
    // 视频
    Widget video = StreamBuilder<String>(
      initialData: videoPath,
      stream: _videoSc.stream,
      builder: (context, snapshot) {
        if (snapshot.data == null || snapshot.data.isEmpty) return Container();
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
          child: Container(
            color: Colors.grey[100],
            width: screenW / 3,
            height: screenW / 3,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // 封面
                AspectRatio(
                  aspectRatio: 1.75,
                  child: Image.memory(videoCover, fit: BoxFit.cover),
                ),
                // 播放按钮
                IconButton(
                  icon: Icon(Icons.play_circle_outline),
                  color: Colors.white,
                  iconSize: 50.0,
                  onPressed: () => playVideo(context, videoPath),
                ),
                // 删除按钮
                IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.white,
                  onPressed: () {
                    videoPath = '';
                    videoCover = null;
                    _videoSc.add(videoPath);
                  },
                ).positioned(left: null, bottom: null),
              ],
            ),
          ),
        );
      },
    );
    // 结果
    return Container(
      height: screenH - 60,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            top,
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                child: input,
              ),
            ),
            video,
            images,
          ],
        ),
      ),
    );
  }

  // 选择图片
  Future<void> _onSelectImgClick() async {
    if (_imagePicker == null) _imagePicker = ImagePicker();
    final pickedFile = await _imagePicker.getImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    if (imgPaths == null) imgPaths = [];
    imgPaths.add(pickedFile.path);
    _imgSc.add(imgPaths);
  }

  // 选择视频
  Future<void> _onSelectVideoClick() async {
    if (_imagePicker == null) _imagePicker = ImagePicker();
    final pickedFile = await _imagePicker.getVideo(source: ImageSource.gallery);
    if (pickedFile == null) return;
    videoPath = pickedFile.path;
    videoCover = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 25,
    );
    _videoSc.add(videoPath);
  }

  // 点@好友按钮
  Future<void> _onAtFriendClick() async {
    ForumUser user = await Navigator.of(context)
        .pushNamed(SelectFollowingPage.routeName, arguments: true);
    if (user != null) {
      _controller.text = '${_controller.text} @${user.name} ';
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  // 点发送按钮
  Future _onSendPressed() async {
    final medias = List<UploadedFile>();
    // 图片
    if (imgPaths?.isNotEmpty == true) {
      for (int i = 0; i < imgPaths.length; i++) {
        final result = await repository.upload(imgPaths[i], FileType.image);
        if (result.fail) {
          showToast('第${i + 1}张图片上传失败');
          return;
        }
        medias.add(result.data);
      }
    }
    // 视频
    if (videoPath?.isNotEmpty == true) {
      final result = await repository.upload(videoPath, FileType.video);
      if (result.fail) {
        showToast('视频上传失败');
        return;
      }
      medias.add(result.data);
    }
    final sendResult = await widget.onSend(_controller.text, medias);
    if (sendResult) Navigator.pop(context);
    return;
  }
}
