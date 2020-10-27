import 'package:flutter/material.dart';
import 'package:forum/model/post.dart';

class BottomReplyBar extends StatelessWidget {
  /// 回复楼主时用这个参数
  final String postId;

  /// 回复层主时用这个参数
  final String floorId;

  /// 回复非层主时用这个参数
  final String innerFloorId;

  /// 回复成功的回调，会把回复内容封装成Post、Floor、InnerFloor对象
  final void Function(PostBase) onReplied;

  const BottomReplyBar({
    this.postId,
    this.floorId,
    this.innerFloorId,
    this.onReplied,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
