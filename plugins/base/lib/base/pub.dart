import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../base.dart';
import 'extensions.dart';

/// 通用返回结果数据对象
class Result<T> {
  final int code;
  final String msg;
  final T data;

  const Result({this.code = -1, this.msg = "", this.data});

  const Result.success([this.data])
      : this.code = 0,
        this.msg = "";

  // 返回结果判断
  bool get success => code == 0;

  bool get fail => code != 0;
}

/// 带总数量的列表返回结果
class DataWidthPageInfo<T> {
  final List<T> list;
  final int totalCount;
  final int lastDataIndex;
  final int pageSize;
  DataWidthPageInfo(this.list, this.totalCount, this.lastDataIndex, this.pageSize);
}

/// 带有数据的StreamController
class StreamControllerWithData<T> {
  StreamController<T> _controller;

  T _value;

  T get value => _value;

  Stream<T> get stream => _controller.stream;

  StreamControllerWithData(T defaultValue, {bool broadcast = false}) {
    _value = defaultValue;
    _controller =
        broadcast ? StreamController<T>.broadcast() : StreamController<T>();
  }

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }

  void add(T value, {bool ignoreIfSameValue = false}) {
    if (ignoreIfSameValue && value == _value) return;
    _value = value;
    if (_controller.isPaused || _controller.isClosed) return;
    _controller.add(value);
  }
}

/// 显示Toast
void showToast(String msg) {
  OverlayEntry overlayEntry = OverlayEntry(builder: (context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 50, 50, 50),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Text(msg,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(color: Colors.white)),
        ),
      ),
    );
  });
  SchedulerBinding.instance.addPostFrameCallback(
      (_) => navigatorKey.currentState.overlay.insert(overlayEntry));
  SchedulerBinding.instance.ensureVisualUpdate();
  Future.delayed(const Duration(seconds: 2)).then((_) => overlayEntry.remove());
}

/// 显示对话框
Future<T> showAlertDialog<T>({
  String title,
  String content,
  bool cancelable,
  String confirmText = "确定",
  String cancelText = "取消",
  Future<T> Function() onConfirm,
  Future<T> Function() onCancel,
}) {
  final context = navigatorKey.currentContext;
  final alertDialog = AlertDialog(
    title: title == null ? null : Text(title),
    content: content == null ? null : Text(content),
    actions: <Widget>[
      // 取消按钮
      if (cancelable != false)
        TextButton(
          child: Text(cancelText),
          onPressed: () async {
            if (onCancel == null)
              return Navigator.pop(context);
            else
              return Navigator.pop(context, await onCancel());
          },
        ),
      // 确定按钮
      TextButton(
        child: Text(confirmText),
        onPressed: () async {
          if (onConfirm == null)
            Navigator.pop(context);
          else
            Navigator.pop(context, await onConfirm());
        },
      ),
    ],
  );
  return showDialog<T>(
    context: context,
    barrierDismissible: cancelable != false,
    builder: (context) => cancelable == false
        ? WillPopScope(onWillPop: () => Future.value(false), child: alertDialog)
        : alertDialog,
  );
}

/// 编辑文本弹出框
Future<String> showEditTextDialog({
  String title = '文本编辑',
  String hint = '请输入内容',
}) {
  var text = '';
  final context = navigatorKey.currentContext;
  final dialog = AlertDialog(
    title: Text(title),
    content: TextField(
      decoration: InputDecoration(hintText: hint),
      onChanged: (value) => text = value,
    ),
    actions: <Widget>[
      // 取消按钮
      TextButton(
        child: Text('取消'),
        onPressed: () => Navigator.pop(context),
      ),
      // 确定按钮
      TextButton(
        child: Text('确定'),
        onPressed: () => Navigator.pop(context, text),
      ),
    ],
  );
  return showDialog<String>(context: context, builder: (context) => dialog);
}

String secondsToTime(int seconds) {
  int s = seconds % 60;
  if (seconds < 60) {
    return "00:${s.toStringWithTwoMinLength()}";
  }
  int tmp = seconds ~/ 60;
  int m = tmp % 60;
  if (m < 60) {
    return "${m.toStringWithTwoMinLength()}:${m.toStringWithTwoMinLength()}";
  }
  tmp = tmp ~/ 60;
  int h = tmp % 60;
  if (m < 24) {
    return "$h:${m.toStringWithTwoMinLength()}:${m.toStringWithTwoMinLength()}";
  }
  int d = tmp ~/ 60;
  return "$d:${h.toStringWithTwoMinLength()}:${m.toStringWithTwoMinLength()}:${s.toStringWithTwoMinLength()}";
}
