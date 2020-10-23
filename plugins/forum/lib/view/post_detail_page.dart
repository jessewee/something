import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forum/vm/post_vm.dart';

class PostDetailPage extends StatelessWidget {
  static const routeName = '/forum/post_detail';
  final PostVM _vm;

  PostDetailPage(String id) : _vm = PostVM(id);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
