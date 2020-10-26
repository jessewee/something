import 'package:flutter/material.dart';
import 'package:forum/vm/post_vm.dart';

/// 帖子详情
class PostDetailPage extends StatelessWidget {
  static const routeName = '/forum/post_detail';
  final PostVM _vm;

  PostDetailPage(String id) : _vm = PostVM(id);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// 楼层
class _PostFloor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}
