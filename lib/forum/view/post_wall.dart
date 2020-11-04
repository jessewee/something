import 'package:flutter/material.dart';

import '../../common/circle_menu.dart';
import '../../common/post_wall_widget.dart';
import '../../common/pub.dart';
import '../../common/widgets.dart';

import '../model/media.dart';
import '../model/post.dart';
import '../view/post_detail_page.dart';
import '../vm/extensions.dart';
import '../view/user_page.dart';

class PostWall extends StatelessWidget {
  final List<Post> posts;
  final bool loading; // true: 刷新、false: 下一页、null: 不在加载状态中
  final bool noMoreData;
  final String errorMsg;
  final Future Function(bool) loadData;

  const PostWall({
    this.posts = const [],
    this.loading = false,
    this.noMoreData = false,
    this.errorMsg = '',
    this.loadData,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isNotEmpty && errorMsg.isNotEmpty) showToast(errorMsg);
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (posts.isEmpty && errorMsg.isNotEmpty)
            CenterInfoText(errorMsg)
          else
            _buildPostWallWidget(context),
          // 刷新和下一页按钮
          Positioned(right: 0, bottom: 10, child: _buildButtons()),
        ],
      ),
    );
  }

  // 墙上的内容显示
  Widget _buildPostWallWidget(BuildContext context) {
    final items = posts.map((post) {
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
    }).toList();
    final menus = [
      CircleMenuItem(
        text: '查看',
        onClick: (id) {
          final post = posts.match(id);
          if (post == null) return;
          Navigator.pushNamed(
            context,
            PostDetailPage.routeName,
            arguments: post,
          );
        },
      ),
      CircleMenuItem(
        onGetText: (id) {
          final cnt = posts.match(id)?.likeCnt;
          return cnt == null || cnt == 0 ? '点赞' : '点赞$cnt';
        },
        onClick: (id) {
          final post = posts.match(id);
          if (post == null) return;
          post.changeLikeState(post.myAttitude == 1 ? null : true);
        },
      ),
      CircleMenuItem(
        onGetText: (id) {
          final cnt = posts.match(id)?.dislikeCnt;
          return cnt == null || cnt == 0 ? '点踩' : '点踩$cnt';
        },
        onClick: (id) {
          final post = posts.match(id);
          if (post == null) return;
          post.changeLikeState(post.myAttitude == -1 ? null : false);
        },
      ),
      CircleMenuItem(
        onGetText: (id) => posts.match(id)?.name ?? '',
        onClick: (id) {
          final post = posts.match(id);
          if (post == null) return;
          Navigator.pushNamed(
            context,
            UserPage.routeName,
            arguments: post.posterId,
          );
        },
      ),
    ];
    return PostWallWidget(items, menus);
  }

  // 刷新和下一页按钮
  Widget _buildButtons() {
    return Row(
      children: [
        ButtonWithIcon(
          loading: loading == true,
          disabled: loading != null,
          text: '刷新',
          onPressed: () => loadData(true),
        ),
        ButtonWithIcon(
          loading: loading == false,
          disabled: loading != null || noMoreData,
          text: '下一页',
          onPressed: () => loadData(false),
        ),
      ],
    );
  }
}

extension _FindPostById on List<Post> {
  Post match(String id) => firstWhere((p) => p.id == id, orElse: () => null);
}
