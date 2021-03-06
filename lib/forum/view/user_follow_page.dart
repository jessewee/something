import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../common/event_bus.dart';
import '../../common/pub.dart';
import '../../common/view_images.dart';
import '../../common/models.dart';
import '../../common/widgets.dart';
import '../../common/extensions.dart';
import '../model/m.dart';
import '../vm/user_follow_vm.dart';
import '../../base/iconfont.dart';
import 'user_page.dart';

/// 用户关注和粉丝列表页
class UserFollowPage extends StatefulWidget {
  static const routeName = 'forum_user_follow_page';
  final UserFollowPageArg arg;
  const UserFollowPage(this.arg);

  @override
  _UserFollowPageState createState() => _UserFollowPageState();
}

class _UserFollowPageState extends State<UserFollowPage> {
  ScrollController _scrollController;
  StreamControllerWithData<bool> _loading;
  bool loadingMore = false;
  UserFollowVM _vm;

  @override
  void initState() {
    loadingMore = false;
    _vm = UserFollowVM(widget.arg.userId, widget.arg.flag);
    _loading = StreamControllerWithData(true);
    _scrollController = ScrollController();
    _scrollController.addListener(() async {
      if (loadingMore || _vm.noMoreData) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - LoadMore.validHeight) {
        loadingMore = true;
        _loadData(false);
      }
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = _vm.list.length;
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<bool>(
          stream: _loading.stream,
          builder: (context, _) => TextWithLoading(
            _vm.flag ? '关注的人' : '粉丝',
            _loading.value == true,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: len + 1,
          itemBuilder: (context, index) => index == len
              ? LoadMore(noMore: _vm.noMoreData)
              : _UserItem(
                  _vm.list[index],
                  (userId) => _vm.changeFollowState(userId),
                ),
        ),
      ),
    );
  }

  Future<void> _loadData([bool refresh = true]) async {
    _loading.add(true);
    await _vm.loadData(refresh);
    _loading.setValueWithoutNotify(false);
    loadingMore = false;
    setState(() {});
  }
}

class _UserItem extends StatefulWidget {
  final ForumUser user;
  final Future<String> Function(String) onFollowClick;
  const _UserItem(this.user, this.onFollowClick);

  @override
  __UserItemState createState() => __UserItemState();
}

class __UserItemState extends State<_UserItem> {
  StreamController<bool> _followStreamController; // 关注按钮改变

  @override
  void initState() {
    _followStreamController = StreamController();
    // 在其它页改变了关注状态
    eventBus.on(EventBusType.forumUserChanged, (arg) {
      if (arg == null || arg is! Map) return;
      if (arg['userId'] != widget.user.id) return;
      if (arg['followed'] == null) return;
      final followed = arg['followed'] as bool;
      if (followed != widget.user.followed) {
        widget.user.followed = followed;
        _followStreamController.send(null);
      }
    }, 'user_follow_page');
    super.initState();
  }

  @override
  void dispose() {
    eventBus.off(tag: 'user_follow_page');
    _followStreamController?.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: FlatButton(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        onPressed: () => Navigator.pushNamed(
          context,
          UserPage.routeName,
          arguments: UserPageArg(userId: widget.user.id),
        ),
        child: Row(
          children: [
            // 头像
            ImageWithUrl(
              widget.user.avatarThumb,
              width: 40.0,
              height: 40.0,
              round: true,
              backgroundColor: Colors.grey[200],
              errorWidget: Icon(Icons.emoji_people),
              onPressed: () => viewImages(context, [widget.user.avatar]),
            ),
            // 名字
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 2.0),
              child: Text(widget.user.name),
            ),
            // 性别
            if (widget.user.isGenderClear)
              Icon(
                widget.user.isMale ? Iconfont.male : Iconfont.female,
                color: widget.user.isMale ? Colors.blue : Colors.pink,
                size: 16.0,
              ),
            // 关注按钮
            Spacer(),
            StreamBuilder<bool>(
              stream: _followStreamController.stream,
              builder: (context, _) => NormalButton(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                color: widget.user.followed ? theme.primaryColorLight : theme.primaryColor,
                text: widget.user.followed ? '已关注' : '关注',
                onPressed: _onFollowClick,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 关注按钮
  Future _onFollowClick() async {
    final result = await widget.onFollowClick(widget.user.id);
    if (result.isNotEmpty) {
      showToast(result);
      return;
    }
    _followStreamController.send(null);
    eventBus.sendEvent(
      EventBusType.forumUserChanged,
      {'userId': widget.user.id, 'followed': widget.user.followed},
    );
    return;
  }
}

class UserFollowPageArg {
  /// true:关注列表、false:粉丝列表
  final bool flag;
  final String userId;
  const UserFollowPageArg(this.userId, [this.flag = true]);
}
