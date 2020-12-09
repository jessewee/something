import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../common/models.dart';
import '../../common/event_bus.dart';
import '../../common/extensions.dart';
import '../../common/play_video_page.dart';
import '../../common/view_images.dart';
import '../../common/widgets.dart';

import '../model/post.dart';
import '../../base/iconfont.dart';
import '../view/post_detail_page.dart';
import '../view/user_page.dart';
import '../vm/extensions.dart';

/// 列表里的帖子
class PostItem extends StatefulWidget {
  static final eventBusEventType = 'forum_post_item_changed';
  final Post post;

  const PostItem(this.post);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  int _screenW = 750;
  StreamController<int> _likeStatusStreamController; // 点赞点踩按钮改变

  @override
  void initState() {
    eventBus.on(
      EventBusType.forumPostItemChanged,
      (arg) {
        if (!mounted || arg is! Map<String, dynamic>) return;
        final map = arg as Map<String, dynamic>;
        if (map['postId'] != widget.post.id) return;
        final likeCnt = map['likeCnt'];
        if (likeCnt != null) widget.post.likeCnt = likeCnt;
        final dislikeCnt = map['dislikeCnt'];
        if (dislikeCnt != null) widget.post.dislikeCnt = dislikeCnt;
        final replyCnt = map['replyCnt'];
        if (replyCnt != null) widget.post.replyCnt = replyCnt;
        setState(() {});
      },
      '${PostItem.eventBusEventType}_${widget.post.id}',
    );
    _likeStatusStreamController = StreamController.broadcast();
    // 在详情页改变了关注状态
    eventBus.on(EventBusType.forumUserChanged, (arg) {
      if (arg == null || arg is! Map) return;
      if (arg['userId'] != widget.post.posterId) return;
      if (arg['followed'] == null) return;
      final followed = arg['followed'] as bool;
      if (followed != widget.post.posterFollowed) {
        setState(() => widget.post.posterFollowed = followed);
      }
    }, 'post_list_item');
    super.initState();
  }

  @override
  void dispose() {
    eventBus.off(tag: 'post_list_item');
    _likeStatusStreamController.makeSureClosed();
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
      backgroundColor: Colors.grey[200],
      errorWidget: Icon(Icons.emoji_people),
      onPressed: () => viewImages(context, [widget.post.avatar]),
    );
    // 日期
    Widget date = Text(widget.post.date, style: theme.textTheme.caption);
    // 标签
    Widget label = Text(
      widget.post.label,
      style: theme.textTheme.caption.copyWith(color: Colors.white),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
    label = Container(
      child: label,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: ShapeDecoration(
        color: Colors.yellow[900],
        shape: StadiumBorder(),
      ),
    );
    label = Tooltip(message: widget.post.label, child: label);
    // 头像、名字、日期区域
    Widget top = Row(
      children: <Widget>[
        avatar.withMargin(right: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              name,
              label == null
                  ? date.withMargin(top: 8.0)
                  : Row(
                      children: [
                        date.withMargin(right: 8.0),
                        Flexible(child: label),
                      ],
                    ).withMargin(top: 8.0),
            ],
          ),
        ),
      ],
    );
    top = FlatButton(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      onPressed: () => Navigator.pushNamed(
        context,
        UserPage.routeName,
        arguments: UserPageArg(userId: widget.post.posterId),
      ),
      child: top,
    ).withMargin(bottom: 8.0);
    // 回复
    Widget reply = NormalButton(
      color: Colors.black,
      icon: Iconfont.reply,
      text: '${widget.post.replyCnt}',
      onPressed: _toDetailPage,
    );
    // 点赞
    Widget like = StreamBuilder(
      stream: _likeStatusStreamController.stream,
      builder: (context, _) => NormalButton(
        color: widget.post.myAttitude == true ? theme.primaryColor : Colors.black,
        icon: Iconfont.like,
        text: '${widget.post.likeCnt}',
        onPressed: () => _changeLikeState(widget.post.myAttitude == true ? null : true),
      ),
    );
    // 点踩
    Widget dislike = StreamBuilder(
      stream: _likeStatusStreamController.stream,
      builder: (context, _) => NormalButton(
        color: widget.post.myAttitude == false ? theme.primaryColor : Colors.black,
        icon: Iconfont.dislike,
        text: '${widget.post.dislikeCnt}',
        onPressed: () => _changeLikeState(widget.post.myAttitude == false ? null : false),
      ),
    );
    // 回复、点赞、点踩区域
    Widget bottom = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[reply, like, dislike],
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
          children: [for (var i = 0; i < cnt; i++) _buildMedia(widget.post.medias[i], cnt)],
        );
      }
      media = Container(margin: const EdgeInsets.only(top: 5.0), child: media);
    }
    // 结果
    return InkWell(
      onTap: _toDetailPage,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            top,
            content,
            if (media != null) media,
            bottom.withMargin(top: 8.0),
            Divider(height: 1.0, thickness: 1.0).withMargin(top: 8.0),
          ],
        ),
      ),
    );
  }

  // 到详情页
  void _toDetailPage() {
    Navigator.pushNamed(context, PostDetailPage.routeName, arguments: widget.post);
  }

  // 构建图片或者视频Widget
  Widget _buildMedia(UploadedFile media, int cnt) {
    Widget w;
    if (media.type == FileType.image) {
      w = ImageWithUrl(
        media.thumbUrl,
        aspectRatio: 1,
        fit: BoxFit.cover,
        onPressed: () => _viewMediaImages(media),
      );
    } else if (media.type == FileType.video) {
      w = AspectRatio(
        aspectRatio: 1.75,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ImageWithUrl(media.thumbUrl, fit: BoxFit.cover).positioned(),
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
  void _viewMediaImages(UploadedFile cur) {
    final images = widget.post.medias.where((m) => m.type == FileType.image).toList();
    final idx = images.indexOf(cur);
    viewImages(
      context,
      images.map((e) => e.url).toList(),
      curIndex: max(0, idx),
    );
  }

  // 更改点赞点踩 [like] null表示中立
  Future _changeLikeState(bool like) async {
    final result = await widget.post.changeLikeState(like);
    if (result.isEmpty) _likeStatusStreamController.send(null);
    return;
  }
}
