import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../base.dart';

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
  var alertDialog = AlertDialog(
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
