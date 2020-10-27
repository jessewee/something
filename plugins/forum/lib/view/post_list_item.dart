import 'dart:math';

import 'package:base/base/event_bus.dart';
import 'package:base/base/play_video_page.dart';
import 'package:base/base/view_images.dart';
import 'package:flutter/material.dart';
import 'package:base/base/widgets.dart';
import 'package:base/base/extensions.dart';
import 'package:forum/model/media.dart';
import 'package:forum/model/post.dart';
import 'package:forum/other/iconfont.dart';

/// 列表里的帖子
class PostItem extends StatefulWidget {
  static final eventBusEventType = 'forum_post_item_changed';
  final Post post;
  final Future<bool> Function(String, PostClickType, [dynamic arg]) onClick;

  const PostItem(this.post, this.onClick);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  int _screenW = 750;

  @override
  void initState() {
    eventBus.on(
      PostItem.eventBusEventType,
      (arg) {
        if (!mounted || arg is! Map<String, dynamic>) return;
        final map = arg as Map<String, dynamic>;
        if (map['postId'] != widget.post.id) return;
        final likeCnt = map['likeCnt'];
        if (likeCnt != null) widget.post.likeCnt = likeCnt;
        final dislikeCnt = map['dislikeCnt'];
        if (dislikeCnt != null) widget.post.dislikeCnt = dislikeCnt;
        setState(() {});
      },
      '${PostItem.eventBusEventType}_${widget.post.id}',
    );
    super.initState();
  }

  @override
  void dispose() {
    eventBus.off(tag: '${PostItem.eventBusEventType}_${widget.post.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenW = MediaQuery.of(context).size.width.toInt();
    final theme = Theme.of(context);
    // 名字
    Widget name = Text(widget.post.name, style: theme.textTheme.subtitle2);
    // 头像
    Widget avatar = ImageWithUrl(
      widget.post.avatarThumb,
      round: true,
      width: 50.0,
      height: 50.0,
      onPressed: () => viewImages(context, [widget.post.avatar]),
    );
    // 日期
    Widget date = Text(widget.post.date, style: theme.textTheme.caption);
    // 头像、名字、日期区域
    Widget top = Row(
      children: <Widget>[
        avatar.withMargin(right: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[name, date.withMargin(top: 8.0)],
          ),
        ),
      ],
    );
    top = FlatButton(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      onPressed: _onClick(PostClickType.VIEW_USER, widget.post.posterId),
      child: top,
    ).withMargin(bottom: 8.0);
    // 点赞
    Widget like = ButtonWithIcon(
      color: widget.post.myAttitude == 1 ? theme.primaryColor : Colors.black,
      icon: Iconfont.like,
      text: '${widget.post.likeCnt}',
      onPressed: _onClick(PostClickType.LIKE, widget.post.myAttitude != 1),
    );
    // 点踩
    Widget dislike = ButtonWithIcon(
      color: widget.post.myAttitude == -1 ? theme.primaryColor : Colors.black,
      icon: Iconfont.dislike,
      text: '${widget.post.dislikeCnt}',
      onPressed: _onClick(PostClickType.DISLIKE, widget.post.myAttitude != -1),
    );
    // 点赞、点踩区域
    Widget bottom = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[like, dislike],
    );
    // 文本
    Widget content = Text(
      widget.post.content,
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
    // 图片和视频
    Widget media;
    if (widget.post.medias.isNotEmpty) {
      if (widget.post.medias.length == 1) {
        media = _buildMedia(widget.post.medias.first, 1);
      } else {
        final cnt = min(9, widget.post.medias.length);
        media = Wrap(
          spacing: 5.0,
          runSpacing: 5.0,
          children: [
            for (var i = 0; i < cnt; i++)
              _buildMedia(widget.post.medias[i], cnt)
          ],
        );
      }
      media = Container(margin: const EdgeInsets.only(top: 5.0), child: media);
    }
    // 结果
    return InkWell(
      onTap: () => _onClick(PostClickType.VIEW_POST),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            top,
            content,
            if (media != null) media,
            bottom.withMargin(top: 8.0),
            Divider().withMargin(top: 8.0),
          ],
        ),
      ),
    );
  }

  // 构建图片或者视频Widget
  Widget _buildMedia(Media media, int cnt) {
    Widget w;
    if (media is ImageMedia) {
      w = AspectRatio(
        aspectRatio: 1,
        child: ImageWithUrl(
          media.thumbUrl,
          fit: BoxFit.cover,
          onPressed: () => _viewMediaImages(media),
        ),
      );
    } else if (media is VideoMedia) {
      w = AspectRatio(
        aspectRatio: 1.75,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ImageWithUrl(media.coverUrl, fit: BoxFit.cover).positioned(),
            IconButton(
              icon: Icon(Icons.play_circle_outline),
              color: Colors.white,
              iconSize: 50.0,
              onPressed: () => playVideo(context, media.url),
            ),
          ],
        ),
      );
    } else {
      w = Container();
    }
    final contentW = _screenW - 40;
    if (cnt == 1) {
      w = SizedBox(width: contentW / 3 * 2, child: w);
    } else if (cnt == 2) {
      w = SizedBox(width: contentW / 2, child: w);
    } else {
      w = SizedBox(width: contentW / 3, child: w);
    }
    return w;
  }

  // 查看图片
  void _viewMediaImages(ImageMedia cur) {
    final images = widget.post.medias.whereType<ImageMedia>().toList();
    final idx = images.indexOf(cur);
    viewImages(context, images.map((e) => e.url).toList(), max(0, idx));
  }

  // 点击事件
  Future Function() _onClick(PostClickType type, [dynamic arg]) {
    if (widget.onClick == null) return null;
    return () async {
      final result = await widget.onClick(widget.post.id, type, arg);
      if (result && mounted) setState(() {});
    };
  }
}

enum PostClickType {
  /// 点赞
  LIKE,

  /// 点踩
  DISLIKE,

  /// 查看用户
  VIEW_USER,

  /// 查看帖子详情
  VIEW_POST,
}
