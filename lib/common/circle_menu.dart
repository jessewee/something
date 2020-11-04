import 'dart:math';
import 'dart:ui' as dartUI;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CircleMenu extends CustomPainter with ChangeNotifier {
  final fontSize = 12.0;
  final fontHeight = 1.2;
  final String id; // 外部传入的用来识别的id，在获取按钮文本和按钮点击事件时传递这个值
  final List<CircleMenuItem> menus;
  final double centerX, centerY, radius; // 外部传入的参数，内部需要根据情况改变
  final Function() onDismiss;
  final double _arcDif;
  final Paint _painter;
  int _tickerTime;
  double _animatedRadius;
  double _animatedItemRadius;
  double _centerX;
  double _centerY;
  double _radius;
  double _itemRadius;
  Map<int, Offset> _itemCenters;
  Ticker _ticker;

  CircleMenu(
    this.id,
    this.menus,
    this.centerX,
    this.centerY,
    this.radius,
    this.onDismiss,
  )   : _arcDif = pi * 2 / menus.length,
        _painter = Paint(),
        _animatedRadius = 0,
        _animatedItemRadius = 0;

  @override
  bool shouldRepaint(covariant CircleMenu oldDelegate) {
    bool result = false;
    if (centerX != oldDelegate.centerX ||
        centerY != oldDelegate.centerY ||
        radius != oldDelegate.radius) result = true;
    if (_animatedRadius != oldDelegate._animatedRadius) result = true;
    if (menus.length != oldDelegate.menus.length) result = true;
    for (var i = 0; i < menus.length; i++) {
      if (menus[i] != oldDelegate.menus[i]) {
        result = true;
        break;
      }
    }
    if (result) _radius = null;
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (menus == null || menus.isEmpty) return;
    // 计算各属性
    if (_radius == null) {
      _centerX = centerX;
      _centerY = centerY;
      _radius = min(radius, min(size.width, size.height) / 2);
      // 左右不超边界
      final left = _centerX - _radius;
      if (left < 0) {
        _centerX -= left;
      } else {
        final right = _centerX + _radius;
        if (right > size.width) {
          _centerX -= right - size.width;
        }
      }
      // 上下不超边界
      final top = _centerY - _radius;
      if (top < 0) {
        _centerY -= top;
      } else {
        final bottom = _centerY + _radius;
        if (bottom > size.height) {
          _centerY -= bottom - size.height;
        }
      }
      // 按钮半径和菜单圆环半径计算
      _itemRadius = _radius / 4;
      _radius = _radius - _itemRadius;
      // 刷新动画显示的ticker
      _tickerTime = 0;
      _ticker = Ticker((elapsed) {
        _tickerTime += elapsed.inMilliseconds;
        final tmp = min(1, _tickerTime / 250);
        _animatedRadius = tmp * _radius;
        _animatedItemRadius = tmp * _itemRadius;
        notifyListeners();
        if (tmp >= 1) _ticker.dispose();
      });
      _ticker.start();
    }
    final center = Offset(_centerX, _centerY);
    // 画外部传入的中心点和实际中心点之间的线
    canvas.drawLine(
      Offset(centerX, centerY),
      center,
      _painter
        ..color = Colors.red
        ..strokeWidth = 3.0,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      3.0,
      _painter..style = PaintingStyle.fill,
    );
    canvas.drawCircle(center, 3.0, _painter);
    // 画圆环
    final path = Path()
      ..addOval(Rect.fromCircle(
        center: center,
        radius: _animatedRadius + _animatedItemRadius,
      ));
    canvas.drawShadow(path, Colors.black38, 2, true);
    _painter.style = PaintingStyle.stroke;
    _painter.strokeWidth = _animatedItemRadius * 2;
    _painter.color = Color.fromARGB(50, 0, 0, 0);
    canvas.drawCircle(center, _animatedRadius, _painter);
    // 画菜单
    _painter.strokeWidth = 2.0;
    _painter.color = Colors.black87;
    final cnt = menus.length;
    for (int i = 0; i < cnt; i++) _drawItem(canvas, i, cnt);
  }

  void _drawItem(Canvas canvas, int index, int cnt) {
    var arc = _arcDif * index - pi / 2; // -pi/2是为了让第一个选项在最上边，要不是在最右边
    // 偶数个选项时第一个和最后一个在最上边左右对称
    if (cnt % 2 == 0) arc += _arcDif / 2;
    final itemCenterX = _centerX + _animatedRadius * cos(arc);
    final itemCenterY = _centerY + _animatedRadius * sin(arc);
    if (_itemCenters == null) _itemCenters = {};
    _itemCenters[index] = Offset(itemCenterX, itemCenterY);
    // 画边框
    final path = Path()
      ..addOval(Rect.fromCircle(
        center: _itemCenters[index],
        radius: _animatedItemRadius,
      ));
    canvas.drawShadow(path, Colors.black, 1, true);
    canvas.drawCircle(
      _itemCenters[index],
      _animatedItemRadius,
      _painter
        ..style = PaintingStyle.fill
        ..color = Color.fromARGB(200, 0, 200, 200),
    );
    // 字
    final textW = _animatedItemRadius * 2 - 10;
    dartUI.ParagraphBuilder pb = dartUI.ParagraphBuilder(dartUI.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: fontSize,
      height: fontHeight,
      maxLines: textW ~/ (fontSize * fontHeight),
      ellipsis: '...',
    ))
      ..pushStyle(dartUI.TextStyle(color: Colors.white))
      ..addText(menus[index].getTitle(id));
    final paragraph = pb.build()
      ..layout(dartUI.ParagraphConstraints(width: textW));
    final offsetX = itemCenterX - paragraph.width / 2;
    final offsetY = itemCenterY - paragraph.height / 2;
    canvas.drawParagraph(paragraph, Offset(offsetX, offsetY));
    // 点击蒙版
    if (_tappedIdx == null || _tappedIdx != index) return;
    canvas.drawCircle(
      _itemCenters[index],
      _animatedItemRadius,
      _painter
        ..style = PaintingStyle.fill
        ..color = Colors.black12,
    );
  }

  /// ------------------------------------点击事件相关------------------------------------ ///
  double _downX, _downY;
  int _tappedIdx;

  /// 点中了第几个菜单
  void onTapDown(double x, double y) {
    if (_itemCenters == null || _itemCenters.isEmpty) return;
    for (var item in _itemCenters.entries) {
      final center = item.value;
      if (x >= center.dx - _itemRadius &&
          x <= center.dx + _itemRadius &&
          y >= center.dy - _itemRadius &&
          y <= center.dy + _itemRadius) {
        _tappedIdx = item.key;
        _downX = x;
        _downY = y;
        notifyListeners();
      }
    }
  }

  void onTapUp(double x, double y) {
    if (_downX == null || _downY == null || _tappedIdx == null) {
      onDismiss();
      return;
    }
    if (x >= _downX - 5 &&
        x <= _downX + 5 &&
        y >= _downY - 5 &&
        y <= _downY + 5) {
      menus[_tappedIdx].onClick(id);
      onDismiss();
    }
    _tappedIdx = null;
    _downX = null;
    _downY = null;
    onDismiss();
    notifyListeners();
  }

  void onTapCancel() {
    _tappedIdx = null;
    _downX = null;
    _downY = null;
    notifyListeners();
  }
}

/// 菜单按钮所需参数
class CircleMenuItem {
  final String text;
  final Function(String) onGetText;
  final Function(String) onClick;

  String getTitle(String id) {
    if (text?.isNotEmpty == true) return text;
    return onGetText?.call(id) ?? '';
  }

  CircleMenuItem({this.text, this.onGetText, this.onClick}) {
    assert(text != null || onGetText != null);
  }
}
