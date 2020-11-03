import 'dart:async';
import 'dart:typed_data';

import 'package:base/base/extensions.dart';
import 'package:base/base/play_video_page.dart';
import 'package:base/base/pub.dart';
import 'package:base/base/view_images.dart';
import 'package:base/base/widgets.dart';
import 'package:base/model/m.dart';
import 'package:flutter/material.dart';
import 'package:forum/api/api.dart' as api;
import 'package:forum/model/m.dart';
import 'package:forum/model/media.dart';
import 'package:forum/model/post.dart';
import 'package:forum/repository/repository.dart' as repository;
import 'package:forum/view/select_following_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class BottomReplyBar extends StatefulWidget {
  /// 回复楼主时用这个参数
  final String postId;

  /// 回复层主时用这个参数
  final String floorId;

  /// 回复非层主时用这个参数
  final String innerFloorId;

  /// 层内回复目标id
  final String targetId;

  /// 层内回复目标名字
  final String targetName;

  /// 回复成功的回调，会把回复内容封装成Post、Floor、InnerFloor对象
  final void Function(PostBase) onReplied;

  const BottomReplyBar({
    this.postId,
    this.floorId,
    this.innerFloorId,
    this.targetId,
    this.targetName,
    this.onReplied,
  });

  @override
  _BottomReplyBarState createState() => _BottomReplyBarState();
}

class _BottomReplyBarState extends State<BottomReplyBar> {
  TextEditingController _controller;
  FocusNode _focusNode;
  StreamControllerWithData<bool> _sending;

  @override
  void initState() {
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _sending = StreamControllerWithData(false);
    super.initState();
  }

  @override
  void dispose() {
    _sending.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const minHeight = 44.0;
    const tbPadding = 3.0;
    const iconSize = 24.0;
    const iconPadding = 7.0;
    const inputRadius = 19.0;
    final hintText = widget.targetName?.isNotEmpty == true
        ? '回复${widget.targetName}'
        : widget.postId?.isNotEmpty == true
            ? '回复楼主'
            : '回复层主';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200])),
      ),
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: tbPadding,
      ),
      child: Row(
        children: <Widget>[
          // 发送中的loading
          StreamBuilder(
            stream: _sending.stream,
            builder: (context, snapshot) => Visibility(
              child: Container(
                margin: const EdgeInsets.only(right: 5.0),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.grey),
                ),
              ),
              visible: snapshot.data == true,
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: hintText,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 8.0,
                ),
                fillColor: Colors.grey[100],
                filled: true,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(inputRadius)),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(inputRadius)),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              onSubmitted: (text) => _onSubmit(text, []),
            ),
          ),
          // 长回复按钮
          FlatButton(
            padding: const EdgeInsets.all(iconPadding),
            child: Text('长回复'),
            onPressed: () => _onLongReplyClick(context),
          ),
          // @好友
          FlatButton(
            minWidth: 0,
            padding: const EdgeInsets.all(iconPadding),
            child: Icon(Icons.alternate_email, size: iconSize),
            onPressed: () => _onAtFriendClick(context),
          ),
        ],
      ),
    );
  }

  // 长回复
  void _onLongReplyClick(BuildContext context) async {
    _focusNode.unfocus();
    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      context: context,
      builder: (context) => _LongReplyPage(
        onSend: _onSubmit,
        defaultText: _controller.text,
      ),
    );
  }

  // @某人
  void _onAtFriendClick(BuildContext context) async {
    dynamic user = await Navigator.pushNamed(
      context,
      SelectFollowingPage.routeName,
      arguments: true,
    );
    if (user != null && user is ForumUser) {
      _controller.text = '${_controller.text} @${user.name} ';
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  // 提交回复
  Future<bool> _onSubmit(String text, List<Media> medias) async {
    _sending.add(true);
    final result = await _doSubmit(text, medias);
    _sending.add(false);
    return result;
  }

  Future<bool> _doSubmit(String text, List<Media> medias) async {
    // 回复楼主
    if (widget.postId?.isNotEmpty == true) {
      final result = await repository.replyPost(widget.postId, text, medias);
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      final loginUser = context.read<User>();
      final floorId = result.data['floorId'];
      final floor = result.data['floor'];
      widget.onReplied(Floor(
        id: floorId,
        posterId: loginUser.id,
        avatar: loginUser.avatar,
        avatarThumb: loginUser.avatarThumb,
        name: loginUser.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        floor: floor,
      ));
      _controller.text = '';
      return true;
    }
    // 回复层主
    if (widget.floorId?.isNotEmpty == true) {
      final result = await repository.replyFloor(widget.floorId, text, medias);
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      final loginUser = context.read<User>();
      final innerFloorId = result.data['innerFloorId'];
      final innerFloor = result.data['innerFloor'];
      widget.onReplied(InnerFloor(
        id: innerFloorId,
        posterId: loginUser.id,
        avatar: loginUser.avatar,
        avatarThumb: loginUser.avatarThumb,
        name: loginUser.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        innerFloor: innerFloor,
      ));
      _controller.text = '';
      return true;
    }
    // 层内回复
    if (widget.innerFloorId?.isNotEmpty == true) {
      final result =
          await repository.replyInnerFloor(widget.innerFloorId, text, medias);
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      final loginUser = context.read<User>();
      final innerFloorId = result.data['innerFloorId'];
      final innerFloor = result.data['innerFloor'];
      widget.onReplied(InnerFloor(
        id: innerFloorId,
        posterId: loginUser.id,
        avatar: loginUser.avatar,
        avatarThumb: loginUser.avatarThumb,
        name: loginUser.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        innerFloor: innerFloor,
        targetId: widget.targetId ?? '',
        targetName: widget.targetName ?? '',
      ));
      _controller.text = '';
      return true;
    }
    return false;
  }
}

/// 长回复，多行文本，图片，视频
class _LongReplyPage extends StatefulWidget {
  final String defaultText;

  /// 发送
  final Future<bool> Function(String, List<Media>) onSend;

  const _LongReplyPage({this.defaultText, this.onSend});

  @override
  __LongReplyPageState createState() => __LongReplyPageState();
}

class __LongReplyPageState extends State<_LongReplyPage> {
  TextEditingController _controller;
  StreamController<List> _imgSc;
  StreamController<String> _videoSc;
  List<String> imgPaths;
  String videoPath;
  Uint8List videoCover;
  ImagePicker _imagePicker;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.defaultText);
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
    final medias = List<Media>();
    // 图片
    if (imgPaths?.isNotEmpty == true) {
      for (int i = 0; i < imgPaths.length; i++) {
        Result result = await api.upload(imgPaths[i], FileType.image);
        if (result.fail) {
          showToast('第${i + 1}张图片上传失败');
          return;
        }
        medias.add(ImageMedia(
          thumbUrl: result.data['thumbUrl'],
          url: result.data['url'],
          width: result.data['width'],
          height: result.data['height'],
        ));
      }
    }
    // 视频
    if (videoPath?.isNotEmpty == true) {
      Result result = await api.upload(videoPath, FileType.video);
      if (result.fail) {
        showToast('视频上传失败');
        return;
      }
      medias.add(VideoMedia(result.data['thumbUrl'], result.data['url']));
    }
    final sendResult = await widget.onSend(_controller.text, medias);
    if (sendResult) Navigator.pop(context);
    return;
  }
}
