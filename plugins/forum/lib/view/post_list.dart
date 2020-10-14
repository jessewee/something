import 'package:flutter/material.dart';
import 'package:forum/vm/forum.dart';

class PostList extends StatelessWidget {
  final ForumVM _vm;

  const PostList(this._vm);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('列表'));
  }
}
