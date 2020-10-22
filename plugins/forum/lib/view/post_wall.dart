import 'dart:math';
import 'dart:ui' as dartUI;

import 'package:flutter/material.dart' hide TextStyle;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:base/base/consts_and_enums.dart';
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
    final postWallPainter = _PostWallPainter(
      widget._posts,
      MediaQuery.of(context).devicePixelRatio,
    );
    return RepaintBoundary(
      child: GestureDetector(
        child: CustomPaint(painter: postWallPainter),
        onTapDown: (details) => postWallPainter.onTouch(
          TouchEvt.down,
          details.localPosition.dx,
          details.localPosition.dy,
        ),
        onTapUp: (details) => postWallPainter.onTouch(
          TouchEvt.up,
          details.localPosition.dx,
          details.localPosition.dy,
        ),
        onTapCancel: () => postWallPainter.onTouch(
          TouchEvt.cancel,
          0,
          0,
        ),
        onPanDown: (details) => postWallPainter.onTouch(
          TouchEvt.dragDown,
          details.localPosition.dx,
          details.localPosition.dy,
        ),
        onPanStart: (details) => postWallPainter.onTouch(
          TouchEvt.dragStart,
          details.localPosition.dx,
          details.localPosition.dy,
        ),
        onPanUpdate: (details) => postWallPainter.onTouch(
          TouchEvt.dragUpdate,
          details.localPosition.dx,
          details.localPosition.dy,
        ),
        onPanEnd: (details) => postWallPainter.onTouch(
          TouchEvt.dragEnd,
          0,
          0,
        ),
        onPanCancel: () => postWallPainter.onTouch(
          TouchEvt.dragEnd,
          0,
          0,
        ),
      ),
    );
  }
}

class _PostWallPainter extends CustomPainter
    with ChangeNotifier, _PostWallTouchEvent {
  final List<_PostWrapper> _posts;
  final Paint _painter;
  final double devicePixelRatio;
  _PostWrapperPubParams _params;

  _PostWallPainter(List<_PostWrapper> posts, this.devicePixelRatio)
      : _posts = posts,
        _painter = Paint()..color = Colors.cyan,
        _params =
            _PostWrapperPubParams(); // TODO 重新创建以后shouldRepaint是false，所以这里边的frameSize没有值

  @override
  List<_PostWrapper> get posts => _posts;
  @override
  _PostWrapperPubParams get params => _params;

  @override
  void paint(Canvas canvas, Size size) {
    _params.calculateParams(size);
    if (_posts?.isNotEmpty != true) return;
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    _posts.reversed.forEach((p) => _drawPost(p, canvas));
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
    if (!result) {
      _params = oldDelegate._params;
    }
    return result;
  }

  @override
  void _onPostClicked(_PostWrapper post) {
    // TODO
    print('---------点中了帖子----id:${post.post.id}');
  }

  @override
  void _repaint() {
    notifyListeners();
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
    // 绘制阴影
    final path = Path()
      ..moveTo(post.x, post.y)
      ..lineTo(post.x + params.width, post.y)
      ..lineTo(post.x + params.width, post.y + params.height)
      ..lineTo(post.x, post.y + params.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 5, false);
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
    rotation = (rdm.nextDouble() - 0.5) * pi / 6;
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

/// 绘制帖子时用到的一些公用的参数
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

/// 帖子墙的点击事件处理
mixin _PostWallTouchEvent {
  double _downX, _downY; // 按下时的xy值，抬起时如果xy没变则触发点击事件
  _PostWrapper _touchedPost; // 按下时点中的帖子对象
  double _postDeltX, _postDeltY; // 点中帖子时xy与帖子xy的差值，移动时需要减去这个差值
  List<_PostWrapper> get posts;
  _PostWrapperPubParams get params;

  /// 处理点击事件
  void onTouch(TouchEvt event, double x, double y) {
    final w = params.frameSize.width;
    final h = params.frameSize.height;
    // 超出区域
    if (x > w || x < 0 || y > h || y < 0) {
      _touchedPost = null;
      return;
    }
    // 按下
    if (event == TouchEvt.down || event == TouchEvt.dragDown) {
      _downX = x;
      _downY = y;
      _checkTouchedPost(x, y);
    }
    // 抬起
    else if (event == TouchEvt.up) {
      if (_touchedPost == null ||
          x > _downX + 5 ||
          x < _downX - 5 ||
          y > _downY + 5 ||
          y < _downY - 5) return;
      _onPostClicked(_touchedPost);
      _touchedPost = null;
    }
    // 拖动
    else if (event == TouchEvt.dragUpdate) {
      if (_touchedPost == null) return;
      _touchedPost.x = x - _postDeltX;
      _touchedPost.y = y - _postDeltY;
      _repaint();
    }
    // 拖动抬起
    else if (event == TouchEvt.dragEnd || event == TouchEvt.dragCancel) {
      _touchedPost = null;
    }
  }

  // 检查点中了哪个帖子对象，并置顶
  void _checkTouchedPost(double x, double y) {
    _touchedPost = null;
    for (var post in posts) {
      final points = _calcPostPoints(post);
      final result = _pointInArea(x, y, points);
      if (result) {
        _touchedPost = post;
        break;
      }
    }
    if (_touchedPost != null) {
      _postDeltX = x - _touchedPost.x;
      _postDeltY = y - _touchedPost.y;
      posts.remove(_touchedPost);
      posts.insert(0, _touchedPost);
      _repaint();
    }
  }

  // 获取帖子对象的四个顶点的列表
  List<Offset> _calcPostPoints(_PostWrapper post) {
    // x= (x1 - x2)*cos(θ) - (y1 - y2)*sin(θ) + x2 ; y= (x1 - x2)*sin(θ) + (y1 - y2)*cos(θ) + y2
    final cx = post.x + params.width / 2;
    final cy = post.y + params.height / 2;
    final r = post.rotation;
    final src = [
      Offset(post.x, post.y),
      Offset(post.x + params.width, post.y),
      Offset(post.x + params.width, post.y + params.height),
      Offset(post.x, post.y + params.height),
      Offset(post.x, post.y),
    ];
    final points = src.map((e) {
      final dx = e.dx - cx;
      final dy = e.dy - cy;
      return Offset(
        dx * cos(r) - dy * sin(r) + cx,
        dx * sin(r) + dy * cos(r) + cy,
      );
    }).toList();
    return points;
  }

  // 判断点是否在区域内
  bool _pointInArea(double x, double y, List<Offset> points) {
    var result = false;
    for (var i = 0; i < points.length - 1; i++) {
      final x1 = points[i].dx;
      final y1 = points[i].dy;
      final x2 = points[i + 1].dx;
      final y2 = points[i + 1].dy;
      if (((y2 <= y && y < y1) || (y1 <= y && y < y2)) &&
          (x < (x1 - x2) * (y - y2) / (y1 - y2) + x2)) {
        result = !result;
      }
    }
    return result;
  }

  // 点击了某个帖子
  void _onPostClicked(_PostWrapper post);

  // 通知Canvas刷新
  void _repaint();
}
