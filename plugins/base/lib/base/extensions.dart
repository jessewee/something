import 'dart:async';

import 'package:flutter/widgets.dart';

/// StreamController调用add之前判断是否已经关闭
extension CheckBeforAdd<T> on StreamController<T> {
  void send(T event) {
    if (this.isPaused || this.isClosed) return;
    this.add(event);
  }

  void makeSureClosed() {
    if (!this.isClosed) this.close();
  }
}

extension IntExt on int {
  /// 数字转字符串，小于10自动补一个0
  String toStringWithTwoMinLength() {
    if (this >= 10)
      return this.toString();
    else
      return '0$this';
  }
}

/// Widget加padding
extension WidgetExt on Widget {
  Widget withPadidng(
      {double left = 0.0,
      double top = 0.0,
      double right = 0.0,
      double bottom = 0.0}) {
    return Padding(
        padding: EdgeInsets.fromLTRB(left, top, right, bottom), child: this);
  }

  Widget withMargin(
      {double left = 0.0,
      double top = 0.0,
      double right = 0.0,
      double bottom = 0.0}) {
    return Container(
        margin: EdgeInsets.fromLTRB(left, top, right, bottom), child: this);
  }

  Widget positioned(
      {double left = 0.0,
      double top = 0.0,
      double right = 0.0,
      double bottom = 0.0}) {
    return Positioned(
        left: left, top: top, right: right, bottom: bottom, child: this);
  }
}
