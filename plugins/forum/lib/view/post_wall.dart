import 'package:base/base/circle_menu.dart';
import 'package:flutter/material.dart';
import 'package:forum/model/media.dart';
import 'package:forum/vm/forum.dart';
import 'package:base/base/post_wall_widget.dart';

class PostWall extends StatelessWidget {
  final ForumVM _vm;

  const PostWall(this._vm);

  @override
  Widget build(BuildContext context) {
    final posts = _vm.posts.length <= 20 ? _vm.posts : _vm.posts.sublist(0, 20);
    return SizedBox.expand(
      child: PostWallWidget(
        posts.map((post) {
          var imgUrl = '';
          final tmp = post.medias.isNotEmpty ? post.medias.first : null;
          if (tmp is ImageMedia) {
            imgUrl = tmp.thumbUrl;
          } else if (tmp is VideoMedia) {
            imgUrl = tmp.coverUrl;
          }
          return PostWallItem(
            id: post.id,
            content: post.content,
            imgUrl: imgUrl,
          );
        }).toList(),
        [
          CircleMenuItem(
            text: '查看',
            onClick: (id) => print('----点了查看$id'), // TODO
          ),
          CircleMenuItem(
            text: '点赞',
            onClick: (id) => print('----点了点赞$id'), // TODO
          ),
          CircleMenuItem(
            text: '点踩',
            onClick: (id) => print('----点了点踩$id'), // TODO
          ),
          CircleMenuItem(
            onGetText: (id) =>
                posts.firstWhere((p) => p.id == id, orElse: () => null)?.name ??
                '',
            onClick: (id) => print('----点了发布人$id'), // TODO
          ),
        ],
      ),
    );
  }
}
