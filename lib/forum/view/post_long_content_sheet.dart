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
    Widget label,
  }) {
    return showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.0)),
      ),
      context: context,
      builder: (context) => PostLongContentSheet(
        onSend: onSend,
        defaultText: defaultText,
        label: label,
      ),
    );
  }

  final String defaultText;

  /// 发送，参数是文字内容和图片视频列表
  final Future<bool> Function(String, List<UploadedFile>) onSend;

  /// 发帖页需要有标签选择
  final Widget label;

  const PostLongContentSheet({this.defaultText = '', this.onSend, this.label});

  @override
  _PostLongContentSheetState createState() => _PostLongContentSheetState();
}

class _PostLongContentSheetState extends State<PostLongContentSheet> {
  TextEditingController _controller;
  StreamController<List> _imgSc;
  StreamController<String> _videoSc;
  StreamControllerWithData<bool> _sendBtnSc; // true:加载中、false:不可用、null:正常
  List<String> _imgPaths;
  String _videoPath;
  Uint8List _videoCover;
  ImagePicker _imagePicker;
  bool get _contentEmpty =>
      _controller.text?.isNotEmpty != true &&
      _imgPaths?.isNotEmpty != true &&
      _videoPath?.isNotEmpty != true;

  @override
  void initState() {
    _controller = TextEditingController();
    _sendBtnSc = StreamControllerWithData(
        widget.defaultText?.isNotEmpty == true ? null : false);
    _imgSc = StreamController();
    _videoSc = StreamController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _sendBtnSc.dispose();
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
    Widget top = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // 关闭按钮
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 发送按钮
        StreamBuilder<bool>(
            initialData: _sendBtnSc.value,
            stream: _sendBtnSc.stream,
            builder: (context, snapshot) {
              return NormalButton(
                text: '发送',
                padding: const EdgeInsets.all(15.0),
                disabled: snapshot.data != null,
                loading: snapshot.data == true,
                onPressed: _onSendPressed,
              );
            }),
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
      onChanged: (_) {
        if (_sendBtnSc.value == true) return;
        _sendBtnSc.add(_contentEmpty ? false : null);
      },
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
    // 按钮行
    Widget buttons = Row(
      children: <Widget>[
        // 标签
        if (widget.label != null) widget.label,
        Spacer(),
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
    );
    // 图片
    Widget images = StreamBuilder<List>(
      initialData: _imgPaths,
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
                        _imgPaths.removeAt(i);
                        _imgSc.add(_imgPaths);
                        if (_sendBtnSc.value == true) return;
                        _sendBtnSc.add(_contentEmpty ? false : null);
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
      initialData: _videoPath,
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
                  child: Image.memory(_videoCover, fit: BoxFit.cover),
                ),
                // 播放按钮
                IconButton(
                  icon: Icon(Icons.play_circle_outline),
                  color: Colors.white,
                  iconSize: 50.0,
                  onPressed: () => playVideo(context, _videoPath),
                ),
                // 删除按钮
                IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.white,
                  onPressed: () {
                    _videoPath = '';
                    _videoCover = null;
                    _videoSc.add(_videoPath);
                    if (_sendBtnSc.value == true) return;
                    _sendBtnSc.add(_contentEmpty ? false : null);
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
            Divider(height: 1.0, thickness: 1.0).positioned(top: null),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                child: input,
              ),
            ),
            buttons,
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
    if (_imgPaths == null) _imgPaths = [];
    _imgPaths.add(pickedFile.path);
    _imgSc.add(_imgPaths);
    if (_sendBtnSc.value == true) return;
    _sendBtnSc.add(_contentEmpty ? false : null);
  }

  // 选择视频
  Future<void> _onSelectVideoClick() async {
    if (_imagePicker == null) _imagePicker = ImagePicker();
    final pickedFile = await _imagePicker.getVideo(source: ImageSource.gallery);
    if (pickedFile == null) return;
    _videoPath = pickedFile.path;
    _videoCover = await VideoThumbnail.thumbnailData(
      video: _videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 25,
    );
    _videoSc.add(_videoPath);
    if (_sendBtnSc.value == true) return;
    _sendBtnSc.add(_contentEmpty ? false : null);
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
  void _onSendPressed() async {
    _sendBtnSc.add(true);
    final medias = List<UploadedFile>();
    // 图片
    if (_imgPaths?.isNotEmpty == true) {
      for (int i = 0; i < _imgPaths.length; i++) {
        final result = await repository.upload(_imgPaths[i], FileType.image);
        if (result.fail) {
          showToast('第${i + 1}张图片上传失败');
          _sendBtnSc.add(_contentEmpty ? false : null);
          return;
        }
        medias.add(result.data);
      }
    }
    // 视频
    if (_videoPath?.isNotEmpty == true) {
      final result = await repository.upload(_videoPath, FileType.video);
      if (result.fail) {
        showToast('视频上传失败');
        _sendBtnSc.add(_contentEmpty ? false : null);
        return;
      }
      medias.add(result.data);
    }
    final sendResult = await widget.onSend(_controller.text, medias);
    _sendBtnSc.add(_contentEmpty ? false : null);
    if (sendResult) Navigator.pop(context);
  }
}
