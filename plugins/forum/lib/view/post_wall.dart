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
  _PostWallWidget(List<Post> posts)
      : _posts = posts.map((p) => _PostWrapper(p)).toList();

  @override
  __PostWallWidgetState createState() => __PostWallWidgetState();
}

class __PostWallWidgetState extends State<_PostWallWidget> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        child: CustomPaint(
          painter: _PostWallPainter(
            widget._posts,
            MediaQuery.of(context).devicePixelRatio,
          ),
        ),
      ),
    );
  }
}

class _PostWallPainter extends CustomPainter with ChangeNotifier {
  final List<_PostWrapper> _posts;
  final Paint _painter;
  final double devicePixelRatio;
  _PostWrapperPubParams _params;

  _PostWallPainter(List<_PostWrapper> posts, this.devicePixelRatio)
      : _posts = posts,
        _painter = Paint()..color = Colors.cyan,
        _params = _PostWrapperPubParams();

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
    final existed = _drawImg(canvas, post, contentX, contentY);
    // 绘制文字
    final pb = dartUI.ParagraphBuilder(dartUI.ParagraphStyle(
      fontSize: _params.fontSize,
      height: _params.fontHeight,
      maxLines: existed ? _params.maxLinesAfterImg : _params.maxLines,
      ellipsis: '...',
    ))
      ..pushStyle(dartUI.TextStyle(color: Colors.white))
      ..addText(post.post.content);
    final paragraph = pb.build()
      ..layout(dartUI.ParagraphConstraints(width: _params.contentW));
    final textY = existed ? (contentY + _params.imgSize + 2) : contentY;
    canvas.drawParagraph(paragraph, Offset(contentX, textY));
    // 恢复canvas，主要是为了每个帖子的旋转
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PostWallPainter oldDelegate) {
    var result = false;
    // 遍历数据判断是否重绘，同时重复利用已有的数据，主要是图片数据
    final unusedOld = <_PostWrapper>[];
    for (var i = 0; i < oldDelegate._posts.length; i++) {
      final op = _posts[i];
      bool matchedImg = false;
      bool sameOrder = false;
      for (var j = 0; j < _posts.length; j++) {
        final np = oldDelegate._posts[j];
        // 查看旧列表里的图片是否在新列表里使用到了
        if (np.image == op.image || np.mediaImgUrl == op.mediaImgUrl) {
          matchedImg = true;
          np.image = op.image;
        }
        // 根据帖子id来匹配新旧列表
        if (np.post.id == op.post.id) {
          np.color = op.color;
          np.rotation = op.rotation;
          np.x = op.x;
          np.y = op.y;
          if (j == i) {
            sameOrder = true;
            break;
          }
        }
      }
      if (!sameOrder) result = true;
      if (!matchedImg && op.image != null) unusedOld.add(op);
    }
    // 释放不再使用的图片资源
    unusedOld.map((e) => e.image).toSet().forEach((e) => e.dispose());
    unusedOld.forEach((e) => e.image = null);
    // 再次判断，上边只是遍历，如果有没匹配到的说明长度不一样
    if (_posts.length != oldDelegate._posts.length) {
      result = true;
    }
    return result;
  }

  // 绘制图片
  bool _drawImg(
    Canvas canvas,
    _PostWrapper post,
    double contentX,
    double contentY,
  ) {
    String imgUrl = post.mediaImgUrl;
    if (imgUrl?.isNotEmpty != true) return false;
    // 绘制图片背景色
    final dst = Rect.fromLTWH(
      contentX,
      contentY,
      _params.imgSize,
      _params.imgSize,
    );
    canvas.drawRect(dst, _painter..color = Colors.grey);
    // 加载图片
    if (post.image == null) {
      final imgSmListener = ImageStreamListener((info, synchronousCall) {
        post.image = info.image;
        if (!synchronousCall) notifyListeners();
      });
      CachedNetworkImageProvider(imgUrl)
          .resolve(ImageConfiguration())
          .addListener(imgSmListener);
    }
    // 上边在listener里给post.image赋值有可能是同步的[synchronousCall]，所以这里再判断一次
    if (post.image == null) return false;
    final imgCx = post.image.width / 2;
    final imgCy = post.image.height / 2;
    final imgRadius = min(imgCx, imgCy);
    final src = Rect.fromLTRB(
      imgCx - imgRadius,
      imgCy - imgRadius,
      imgCx + imgRadius,
      imgCy + imgRadius,
    );
    canvas.drawImageRect(post.image, src, dst, _painter);
    return true;
  }
}

/// 帖子对象封装
class _PostWrapper {
  static Random rdm = Random.secure();
  final Post post;
  double x, y, rotation;
  Color color;
  dartUI.Image image;

  String get mediaImgUrl {
    final tmp = post.medias.isNotEmpty ? post.medias.first : null;
    if (tmp is ImageMedia) {
      return tmp.thumbUrl;
    } else if (tmp is VideoMedia) {
      return tmp.coverUrl;
    }
    return '';
  }

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
  double imgSize;
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
    imgSize = min(contentW, contentH);
    maxLines = contentH ~/ (fontSize * fontHeight);
    maxLinesAfterImg = (contentH - imgSize) ~/ (fontSize * fontHeight);
  }
}
