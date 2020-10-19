import 'dart:math';

import 'package:base/base/pub.dart';
import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forum/model/media.dart';
import 'package:forum/model/post.dart';
import 'package:forum/other/iconfont.dart';
import 'package:forum/vm/forum.dart';
import 'package:base/base/extensions.dart';

class PostList extends StatelessWidget {
  final ForumVM _vm;

  const PostList(this._vm);

  @override
  Widget build(BuildContext context) {
    if (_vm.posts.isEmpty) return Center(child: Text('暂无数据'));
    return ListView.builder(
      itemCount: _vm.posts.length,
      itemBuilder: (context, index) {
        final item = _vm.posts[index];
        return ListTile(
          title: Text(item.avatar),
        );
      },
    );
  }
}

/// 列表里的帖子
class _PostItem extends StatefulWidget {
  final Post post;
  final Future Function(Post, PostClickType, [dynamic arg]) onClick;

  const _PostItem(this.post, this.onClick);

  @override
  __PostItemState createState() => __PostItemState();
}

class __PostItemState extends State<_PostItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String avatarThumbUrl = widget.post.avatarThumb;
    String avatarUrl = widget.post.avatar;
    String infoText = widget.post.date;
    // 名字
    Widget name = Text(widget.post.name, style: theme.textTheme.headline6);
    // 头像
    Widget avatar = ImageWithUrl(
      avatarThumbUrl,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: 25.0, backgroundImage: imageProvider),
    );
    avatar = OutlineButton(
      child: avatar,
      shape: CircleBorder(),
      onPressed: () => showImgs(context, [avatarUrl]),
    );
    avatar = Container(
      width: 50.0,
      height: 50.0,
      child: avatar,
      decoration: ShapeDecoration(shape: CircleBorder(), color: Colors.grey),
    );
    // 日期或信息
    Widget info = Text(infoText, style: theme.textTheme.caption);
    // 头像、名字、信息区域
    Widget top = Row(
      children: <Widget>[
        avatar.withMargin(right: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[name, info.withMargin(top: 8.0)],
          ),
        ),
      ],
    );
    top = FlatButton(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      onPressed: _toUserPage,
      child: top,
    ).withMargin(bottom: 8.0);
    // 回复
    Widget reply = ButtonWithIcon(
      icon: Iconfont.reply,
      text: '${widget.post.replyCnt}',
      onPressed: _toPostPage,
    );
    // 点赞
    Widget like = ButtonWithIcon(
      icon: widget.post.myAttitude == 1 ? Iconfont.liked : Iconfont.like,
      text: '${widget.post.likeCnt}',
      onPressed: _onClick(
          PostClickType.LIKE,
          // widget.post.myAttitude==-1，原来是点赞，现在是取消点赞
          widget.post.myAttitude == 1),
    );
    // 点踩
    Widget dislike = ButtonWithIcon(
      icon: widget.post.myAttitude == -1 ? Iconfont.disliked : Iconfont.dislike,
      text: '${widget.post.dislikeCnt}',
      onPressed: _onClick(
          PostClickType.DISLIKE,
          // widget.post.myAttitude==-1，原来是点踩，现在是取消点踩
          widget.post.myAttitude == -1),
    );
    // 回复、点赞、点踩区域
    Widget bottom = Row(children: <Widget>[reply, like, dislike]);
    // 文本
    Widget content = Text(
      widget.post.content,
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
    // 图片和视频
    Widget media;
    if (widget.post.medias.isNotEmpty) {
      if()
    }
    // 图片
    Widget imgs;
    final postImgs = widget.post.medias.whereType<ImageMedia>().toList();
    if (postImgs.isNotEmpty) {
      if (postImgs.length == 1) {
        imgs = Container(
          margin: const EdgeInsets.all(5.0),
          alignment: Alignment.centerLeft,
          child: ButtonWithInk(
            width: 150.0,
            height: 150.0,
            child: ImageWithUrl(postImgs.first.thumbUrl, fit: BoxFit.cover),
            onClick: () => showImgs(context, [postImgs.first.url]),
          ),
        );
      } else {
        imgs = Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            for (var i = 0; i < 3 && i < postImgs.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ButtonWithInk(
                      child: ImageWithUrl(
                        postImgs[i].thumbUrl,
                        fit: BoxFit.cover,
                      ),
                      onClick: () => showImgs(
                        context,
                        postImgs.map((e) => e.url),
                        min(i, postImgs.length - 1),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }
    }
    // 视频
    Widget video;
    final postVideos = widget.post.medias.whereType<VideoMedia>();
    if (postVideos.isNotEmpty) {
      video = Container(
        child: VideoCover(
            coverUrl: widget.post.videoCover,
            onPressed: () => playVideo(context, widget.post.video)),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
      );
    }
    // 结果
    return FlatButton(
      onPressed: _toPostPage,
      padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          top,
          content,
          if (imgs != null) imgs,
          if (video != null) video,
          bottom.withMargin(top: 8.0),
          Divider().withMargin(top: 8.0),
        ],
      ),
    );
  }

  // 构建图片或者视频Widget
  Widget _buildMedia(Media media) {
    
  }

  Future Function() _onClick(PostClickType type, [dynamic arg]) {
    if (widget.onClick == null) return null;
    return () => widget.onClick(widget.post, type, arg).then((value) {
          if (value && mounted) setState(() {});
        });
  }

  void _toPostPage() =>
      Navigator.of(context).pushNamed('postPage', arguments: widget.post);

  void _toUserPage() =>
      Navigator.of(context).pushNamed('user', arguments: widget.post.posterId);
}

enum PostClickType {
  /// 回复
  REPLY,

  /// 点赞
  LIKE,

  /// 点踩
  DISLIKE,

  // 查看楼层回复
  VIEW_FLOOR_REPLIES,

  /// 关注
  FOLLOW,
}
