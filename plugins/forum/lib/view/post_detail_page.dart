import 'package:flutter/material.dart';
import 'package:forum/model/post.dart';
import 'package:forum/vm/post_vm.dart';

/// 帖子详情
class PostDetailPage extends StatelessWidget {
  static const routeName = '/forum/post_detail';
  final PostVM _vm;

  PostDetailPage(Post post) : _vm = PostVM(post);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vm.post.label),
        actions: [
          TextButton(child: Text('跳转楼层'), onPressed: _showToFloors),
        ],
      ),
      body: ListView.builder(itemBuilder: null),
    );
  }

  // 显示跳转楼层的选项弹出框
  void _showToFloors() {}
}

/// 楼层
class _PostFloor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO
    return Container();
  }
}
