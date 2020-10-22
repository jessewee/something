import 'dart:math';
import 'dart:ui' as dartUI;

import 'package:base/base/circle_menu.dart';
import 'package:base/base/pub.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 帖子墙、布告墙，类似墙上贴一个个便签
class PostWallWidget extends StatefulWidget {
  final List<PostWallItem> items;

  /// 菜单列表
  final List<CircleMenuItem> menus;

  PostWallWidget(this.items, this.menus);

  @override
  _PostWallWidgetState createState() => _PostWallWidgetState();
}

class _PostWallWidgetState extends State<PostWallWidget> {
  StreamControllerWithData<PostWallClickParams> _controller;
  @override
  void initState() {
    _controller = StreamControllerWithData(null);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postWallPainter = _PostWallPainter(
      widget.items,
      MediaQuery.of(context).devicePixelRatio,
      (postWallClickParams) => _controller.add(postWallClickParams),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        // 墙
        RepaintBoundary(
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
        ),
        // 环形菜单
        StreamBuilder<PostWallClickParams>(
            stream: _controller.stream,
            builder: (context, snapshot) {
              if (snapshot.data == null || widget.menus?.isNotEmpty != true)
                return Container();
              final params = snapshot.data;
              final circleMenu = CircleMenu(
                params.id,
                widget.menus,
                params.x + params.w / 2,
                params.y + params.h / 2,
                min(params.w, params.h) * 0.7,
                () => _controller.add(null),
              );
              return RepaintBoundary(
                child: GestureDetector(
                  child: CustomPaint(painter: circleMenu),
                  onTapDown: (details) => circleMenu.onTapDown(
                    details.localPosition.dx,
                    details.localPosition.dy,
                  ),
                  onTapUp: (details) => circleMenu.onTapUp(
                    details.localPosition.dx,
                    details.localPosition.dy,
                  ),
                  onTapCancel: () => circleMenu.onTapCancel(),
                ),
              );
            }),
      ],
    );
  }
}

class _PostWallPainter extends CustomPainter
    with ChangeNotifier, _PostWallTouchEvent {
  final List<PostWallItem> _items;
  final Paint _painter;
  final double devicePixelRatio;
  final Function(PostWallClickParams) onItemClick;
  PostWallItemPubParams _params;

  _PostWallPainter(
    List<PostWallItem> items,
    this.devicePixelRatio,
    this.onItemClick,
  )   : _items = items,
        _painter = Paint()..color = Colors.cyan,
        _params = PostWallItemPubParams();

  @override
  List<PostWallItem> get items => _items;

  @override
  PostWallItemPubParams get params => _params;

  @override
  void paint(Canvas canvas, Size size) {
    _params.calculateParams(size);
    if (_items?.isNotEmpty != true) return;
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    _items.reversed.forEach((e) => _drawItem(e, canvas));
  }

  @override
  bool shouldRepaint(covariant _PostWallPainter oldDelegate) {
    var result = false;
    // 遍历数据判断是否重绘，同时重复利用已有的数据，主要是图片数据
    for (var i = 0; i < oldDelegate._items.length; i++) {
      final oi = oldDelegate._items[i];
      bool sameOrder = false;
      for (var j = 0; j < _items.length; j++) {
        final ni = _items[j];
        // 查看旧列表里的图片是否在新列表里使用到了
        if (ni.image == oi.image || ni.imgUrl == oi.imgUrl) {
          ni.image = oi.image;
        }
        // 根据item.id来匹配新旧列表
        if (ni.id == oi.id) {
          ni.color = oi.color;
          ni.rotation = oi.rotation;
          ni.x = oi.x;
          ni.y = oi.y;
          if (j == i) {
            sameOrder = true;
            break;
          }
        }
      }
      if (!sameOrder) result = true;
    }
    // 再次判断，上边只是遍历，如果有没匹配到的说明长度不一样
    if (_items.length != oldDelegate._items.length) {
      result = true;
    }
    if (!result) {
      _params = oldDelegate._params;
    }
    return result;
  }

  @override
  void _onItemClicked(PostWallItem item) {
    onItemClick(
      PostWallClickParams(
        item.id,
        item.x,
        item.y,
        _params.width,
        _params.height,
      ),
    );
  }

  @override
  void _repaint() {
    notifyListeners();
  }

  // 绘制单个item
  void _drawItem(PostWallItem item, Canvas canvas) {
    if (item.x == null || item.y == null) item.random(_params);
    final contentX = item.x + _params.padding;
    final contentY = item.y + _params.padding;
    final cx = item.x + _params.width / 2;
    final cy = item.y + _params.height / 2;
    // 旋转当前item
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(item.rotation);
    canvas.translate(-cx, -cy);
    // 绘制阴影
    final path = Path()
      ..moveTo(item.x, item.y)
      ..lineTo(item.x + params.width, item.y)
      ..lineTo(item.x + params.width, item.y + params.height)
      ..lineTo(item.x, item.y + params.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 5, false);
    // 绘制背景色
    final itemRect = Rect.fromLTWH(
      item.x,
      item.y,
      _params.width,
      _params.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(itemRect, Radius.circular(2.0)),
      _painter..color = item.color,
    );
    // 绘制图片
    final existed = _drawImg(canvas, item, contentX, contentY);
    // 绘制文字
    final pb = dartUI.ParagraphBuilder(dartUI.ParagraphStyle(
      fontSize: _params.fontSize,
      height: _params.fontHeight,
      maxLines: existed ? _params.maxLinesAfterImg : _params.maxLines,
      ellipsis: '...',
    ))
      ..pushStyle(dartUI.TextStyle(color: Colors.white))
      ..addText(item.content);
    final paragraph = pb.build()
      ..layout(dartUI.ParagraphConstraints(width: _params.contentW));
    final textY = existed ? (contentY + _params.imgSize + 2) : contentY;
    canvas.drawParagraph(paragraph, Offset(contentX, textY));
    // 恢复canvas，主要是为了每个item的旋转
    canvas.restore();
  }

  // 绘制图片
  bool _drawImg(
    Canvas canvas,
    PostWallItem item,
    double contentX,
    double contentY,
  ) {
    if (item.imgUrl?.isNotEmpty != true) return false;
    // 绘制图片背景色
    final dst = Rect.fromLTWH(
      contentX,
      contentY,
      _params.imgSize,
      _params.imgSize,
    );
    canvas.drawRect(dst, _painter..color = Colors.grey);
    // 加载图片
    if (item.image == null) {
      final imgSmListener = ImageStreamListener((info, synchronousCall) {
        item.image = info.image;
        if (!synchronousCall) notifyListeners();
      });
      CachedNetworkImageProvider(item.imgUrl)
          .resolve(ImageConfiguration())
          .addListener(imgSmListener);
    }
    // 上边在listener里给post.image赋值有可能是同步的[synchronousCall]，所以这里再判断一次
    if (item.image == null) return false;
    final imgCx = item.image.width / 2;
    final imgCy = item.image.height / 2;
    final imgRadius = min(imgCx, imgCy);
    final src = Rect.fromLTRB(
      imgCx - imgRadius,
      imgCy - imgRadius,
      imgCx + imgRadius,
      imgCy + imgRadius,
    );
    canvas.drawImageRect(item.image, src, dst, _painter);
    return true;
  }
}

/// 点击事件处理
mixin _PostWallTouchEvent {
  double _downX, _downY; // 按下时的xy值，抬起时如果xy没变则触发点击事件
  PostWallItem _touchedItem; // 按下时点中的数据对象
  double _itemDifX, _itemDifY; // 点中item时点击xy与item的xy的差值，移动时需要减去这个差值
  List<PostWallItem> get items;

  PostWallItemPubParams get params;

  /// 处理点击事件
  void onTouch(TouchEvt event, double x, double y) {
    final w = params.frameSize.width;
    final h = params.frameSize.height;
    // 超出区域
    if (x > w || x < 0 || y > h || y < 0) {
      _touchedItem = null;
      return;
    }
    // 按下
    if (event == TouchEvt.down || event == TouchEvt.dragDown) {
      _downX = x;
      _downY = y;
      _checkTouchedItem(x, y);
    }
    // 抬起
    else if (event == TouchEvt.up) {
      if (_touchedItem == null ||
          x > _downX + 5 ||
          x < _downX - 5 ||
          y > _downY + 5 ||
          y < _downY - 5) return;
      _onItemClicked(_touchedItem);
      _touchedItem = null;
    }
    // 拖动
    else if (event == TouchEvt.dragUpdate) {
      if (_touchedItem == null) return;
      _touchedItem.x = x - _itemDifX;
      _touchedItem.y = y - _itemDifY;
      _repaint();
    }
    // 拖动抬起
    else if (event == TouchEvt.dragEnd || event == TouchEvt.dragCancel) {
      _touchedItem = null;
    }
  }

  // 检查点中了哪个item，并置顶
  void _checkTouchedItem(double x, double y) {
    _touchedItem = null;
    for (var item in items) {
      final points = _calcItemPoints(item);
      final result = _pointInArea(x, y, points);
      if (result) {
        _touchedItem = item;
        break;
      }
    }
    if (_touchedItem != null) {
      _itemDifX = x - _touchedItem.x;
      _itemDifY = y - _touchedItem.y;
      items.remove(_touchedItem);
      items.insert(0, _touchedItem);
      _repaint();
    }
  }

  // 获取item的四个顶点的列表
  List<Offset> _calcItemPoints(PostWallItem item) {
    // x= (x1 - x2)*cos(θ) - (y1 - y2)*sin(θ) + x2 ; y= (x1 - x2)*sin(θ) + (y1 - y2)*cos(θ) + y2
    final cx = item.x + params.width / 2;
    final cy = item.y + params.height / 2;
    final r = item.rotation;
    final src = [
      Offset(item.x, item.y),
      Offset(item.x + params.width, item.y),
      Offset(item.x + params.width, item.y + params.height),
      Offset(item.x, item.y + params.height),
      Offset(item.x, item.y),
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

  // 点击了某个item
  void _onItemClicked(PostWallItem item);

  // 通知Canvas刷新
  void _repaint();
}

/// 数据
class PostWallItem {
  final String id; // 主要用来判断是否需要刷新
  final String content;
  final String imgUrl;
  double x, y, rotation;
  Color color;
  dartUI.Image image;

  PostWallItem({this.id, this.content, this.imgUrl});

  void random(PostWallItemPubParams params) {
    x = params.rdm.nextDouble() * (params.frameSize.width - params.width);
    y = params.rdm.nextDouble() * (params.frameSize.height - params.height);
    rotation = (params.rdm.nextDouble() - 0.5) * pi / 6;
    color = colors[params.rdm.nextInt(colors.length)];
  }

  static const List<Color> colors = [
    Color.fromARGB(255, 150, 150, 50),
    Color.fromARGB(255, 50, 150, 150),
    Color.fromARGB(255, 150, 50, 150),
    Color.fromARGB(255, 100, 150, 100),
    Color.fromARGB(255, 150, 100, 100),
  ];
}

/// 绘制数据时用到的一些公用的参数
class PostWallItemPubParams {
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
  Random rdm;

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
    rdm = Random.secure();
  }
}

/// 点击事件
enum TouchEvt {
  down,
  up,
  cancel,
  dragDown,
  dragStart,
  dragEnd,
  dragCancel,
  dragUpdate,
}

/// PostWall点击时通知外层用到的参数
class PostWallClickParams {
  final String id;
  final double x, y, w, h;
  PostWallClickParams(this.id, this.x, this.y, this.w, this.h);
  @override
  String toString() {
    return 'id:$id,x:$x,y:$y,w:$w,h:$h';
  }
}
