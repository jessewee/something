import 'dart:io';
import 'dart:math';
import 'dart:ui' as dartUI;

import 'package:flutter/material.dart' hide TextStyle;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:forum/model/media.dart';
import 'package:forum/model/post.dart';
import 'package:forum/vm/forum.dart';

class PostWall extends StatelessWidget {
  final ForumVM _vm;

  const PostWall(this._vm);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: _PostWallWidget(_vm.posts));
  }
}

class _PostWallWidget extends StatefulWidget {
  final List<_PostWrapper> _posts;
  final ChangeNotifier notifier;
  _PostWallWidget(List<Post> posts)
      : _posts = posts.map((p) => _PostWrapper(p)).toList(),
        notifier = ChangeNotifier();

  @override
  __PostWallWidgetState createState() => __PostWallWidgetState();
}

class __PostWallWidgetState extends State<_PostWallWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CustomPaint(
        painter: _PostWallPainter(widget._posts, widget.notifier),
      ),
    );
  }
}

class _PostWallPainter extends CustomPainter with ChangeNotifier {
  final List<_PostWrapper> _posts;
  final Paint _painter;
  final ChangeNotifier _notifier;
  _PostWrapperPubParams _params;

  _PostWallPainter(List<_PostWrapper> posts, ChangeNotifier notifier)
      : _posts = posts,
        _painter = Paint()..color = Colors.cyan,
        _notifier = notifier,
        _params = _PostWrapperPubParams(),
        super(repaint: notifier);

  @override
  void paint(Canvas canvas, Size size) {
    if (_posts?.isNotEmpty != true) return;
    _params.calculateParams(size);
    canvas.drawRect(
      Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
      _painter..color = Colors.grey[200],
    );
    _posts.forEach((p) => _drawPost(p, canvas));
  }

  // 绘制单个帖子
  void _drawPost(_PostWrapper post, Canvas canvas) {
    if (post.x == null || post.y == null) post.random(_params);
    final contentX = post.x + _params.padding;
    final contentY = post.y + _params.padding;
    final cx = post.x + _params.width / 2;
    final cy = post.y + _params.height / 2;
    // 旋转当前帖子
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(post.rotation);
    canvas.translate(-cx, -cy);
    // 绘制背景色
    final postRect = Rect.fromLTWH(
      post.x,
      post.y,
      _params.width,
      _params.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(postRect, Radius.circular(2.0)),
      _painter..color = post.color,
    );
    // 绘制图片
    final media = post.media;
    String imgUrl;
    if (media != null) {
      if (media is ImageMedia) {
        imgUrl = media.thumbUrl;
      } else if (media is VideoMedia) {
        imgUrl = media.coverUrl;
      }
      if (imgUrl?.isNotEmpty == true) {
        final dst = Rect.fromLTWH(
          contentX,
          contentY,
          _params.minOfContentWH,
          _params.minOfContentWH,
        );
        canvas.drawRect(dst, _painter..color = Colors.grey);
        if (post.image == null) {
          _loadImg(imgUrl, post);
        } else {
          final src = Rect.fromLTWH(
            contentX,
            contentY,
            post.image.width.toDouble(), // TODO
            post.image.height.toDouble(),
          );
          print(
              '---------${post.image.width}--${post.image.height}------${_params.minOfContentWH}');
          canvas.drawImageRect(post.image, src, dst, _painter);
        }
      }
    }
    // 绘制文字
    final pb = dartUI.ParagraphBuilder(dartUI.ParagraphStyle(
      fontSize: _params.fontSize,
      height: _params.fontHeight,
      maxLines: imgUrl == null ? _params.maxLines : _params.maxLinesAfterImg,
      ellipsis: '...',
    ))
      ..pushStyle(dartUI.TextStyle(color: Colors.white))
      ..addText(post.post.content);
    final paragraph = pb.build()
      ..layout(dartUI.ParagraphConstraints(width: _params.contentW));
    final textY =
        imgUrl == null ? contentY : (contentY + _params.minOfContentWH + 2);
    canvas.drawParagraph(paragraph, Offset(contentX, textY));
    // 恢复canvas，主要是为了每个帖子的旋转
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  // 加载图片
  void _loadImg(String url, _PostWrapper post) {
    CachedNetworkImageProvider(url).resolve(ImageConfiguration()).addListener(
      ImageStreamListener((info, synchronousCall) {
        post.image = info.image;
        _notifier.notifyListeners();
      }),
    );
  }
}

/// 帖子对象封装
class _PostWrapper {
  static Random rdm = Random.secure();
  final Post post;
  double x, y, rotation;
  Color color;
  dartUI.Image image;

  Media get media => post.medias.isNotEmpty ? post.medias.first : null;

  _PostWrapper(this.post);

  void random(_PostWrapperPubParams params) {
    x = rdm.nextDouble() * (params.frameSize.width - params.width);
    y = rdm.nextDouble() * (params.frameSize.height - params.height);
    rotation = rdm.nextDouble() / 4;
    color = colors[rdm.nextInt(colors.length)];
  }

  static const List<Color> colors = [
    Color.fromARGB(255, 150, 150, 50),
    Color.fromARGB(255, 50, 150, 150),
    Color.fromARGB(255, 150, 50, 150),
    Color.fromARGB(255, 100, 150, 100),
    Color.fromARGB(255, 150, 100, 100),
  ];
}

class _PostWrapperPubParams {
  Size frameSize;
  double width, height;
  double minOfContentWH;
  double padding;
  double contentW;
  double contentH;
  double fontSize = 12.0;
  double fontHeight = 1.25;
  int maxLines = 1;
  int maxLinesAfterImg = 1;

  void calculateParams(Size size) {
    if (frameSize == size) return;
    frameSize = size;
    final tmp = min(frameSize.width, frameSize.height);
    width = tmp / 2;
    height = width * 1.2;
    padding = min(width, height) / 20;
    contentW = width - padding * 2;
    contentH = height - padding * 2;
    minOfContentWH = min(contentW, contentH);
    maxLines = contentH ~/ (fontSize * fontHeight);
    maxLinesAfterImg = (contentH - minOfContentWH) ~/ (fontSize * fontHeight);
  }
}
