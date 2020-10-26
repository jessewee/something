import 'dart:async';

import 'package:base/base/configs.dart';
import 'package:base/base/pub.dart';
import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forum/model/post.dart';

import 'package:forum/repository/repository.dart';
import 'package:forum/vm/forum_vm.dart';

import 'post_detail_page.dart';
import 'post_list.dart';
import 'post_list_item.dart';
import 'post_wall.dart';
import 'search_content_page.dart';
import 'select_post_label_page.dart';
import 'select_following_page.dart';
import 'user_page.dart';

/// 社区页
class ForumPage extends StatefulWidget {
  static const routeName = '/forum';

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  ForumVM _vm;
  StreamControllerWithData<bool> _displayType; // 显示方式，true:帖子墙、false:列表
  StreamControllerWithData<bool> _load; // true: 刷新、false: 下一页
  StreamControllerWithData<bool> _loading;
  List<Post> _lastPosts = []; // 上次显示的数据，刷新或者加载更多时要继续显示，只是为了这段时间显示，没有其他作用

  @override
  void initState() {
    _displayType = StreamControllerWithData(true, broadcast: true);
    _load = StreamControllerWithData(true, broadcast: true);
    _loading = StreamControllerWithData(true);
    _vm = ForumVM();
    SchedulerBinding.instance.addPostFrameCallback((_) => _load.add(true));
    super.initState();
  }

  @override
  void dispose() {
    _displayType.dispose();
    _load.dispose();
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<bool>(
          initialData: _loading.value,
            stream: _loading.stream,
            builder: (context, snapshot) {
              return snapshot.data != true
                  ? Text('社区')
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('社区'),
                        Container(
                          width: 12.0,
                          height: 12.0,
                          margin: const EdgeInsets.only(left: 5.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                        )
                      ],
                    );
            }),
        actions: [
          /// 切换显示方式
          StreamBuilder<bool>(
            initialData: _displayType.value,
            stream: _displayType.stream,
            builder: (context, snapshot) => AnimatedSwitcher(
              duration: animDuration,
              transitionBuilder: (child, animation) => ScaleTransition(
                child: child,
                scale: animation,
              ),
              child: IconButton(
                key: ValueKey(_displayType),
                color: Colors.white,
                icon: Icon(
                  snapshot.data ? Icons.auto_awesome_motion : Icons.list,
                ),
                onPressed: () => _displayType.add(!snapshot.data),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选条件
          _FilterArea(_vm.filter, () => _load.add(true)),
          // 列表显示
          Expanded(
            child: StreamBuilder<bool>(
                initialData: _load.value,
                stream: _load.stream,
                builder: (context, _) {
                  return FutureBuilder<Result<List<Post>>>(
                    future: _vm.getPosts(
                      refresh: _load.value,
                      // 列表比墙少的话会有问题，一般不会少
                      dataSize: _displayType.value ? 20 : 30,
                      onePageData: _displayType.value,
                    ),
                    builder: (context, dataSs) => _buildContent(
                      dataSs.data,
                      dataSs.connectionState != ConnectionState.done,
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }

  // 内容显示
  Widget _buildContent(Result<List<Post>> result, bool loading) {
    _loading.add(loading);
    final posts = loading || result.fail ? _lastPosts : result.data;
    if (result?.success == true) _lastPosts = result.data;
    return StreamBuilder<bool>(
      initialData: _displayType.value,
      stream: _displayType.stream,
      builder: (context, dt) => AnimatedSwitcher(
        duration: animDuration,
        child: dt.data
            ? PostWall(
                posts: posts,
                loading: loading ? _load.value : null,
                noMoreData: _vm.noMoreData,
                errorMsg: result?.fail == true ? result.msg : '',
                loadData: (refresh) => _load.add(refresh),
                onPostClick: _onPostClick,
              )
            : PostList(
                posts: posts,
                loading: loading ? _load.value : null,
                noMoreData: _vm.noMoreData,
                errorMsg: result?.fail == true ? result.msg : '',
                loadData: (refresh) => _load.add(refresh),
                onPostClick: _onPostClick,
              ),
      ),
    );
  }

  // 帖子的点击事件
  Future<bool> _onPostClick(String id, PostClickType clickType,
      [dynamic arg]) async {
    switch (clickType) {
      case PostClickType.LIKE:
        bool param;
        // 没传参数的话自己查找当前状态，然后改变状态
        if (arg == null) {
          if (_vm.getLikeStatus(id) == true) {
            param = null;
          } else {
            param = true;
          }
        }
        // 传了参数的话参数就是目标状态
        else {
          param = arg ? true : null;
        }
        final result = await _vm.changeLikeState(id, param);
        return result.success;
      case PostClickType.DISLIKE:
        bool param;
        // 没传参数的话自己查找当前状态，然后改变状态
        if (arg == null) {
          if (_vm.getLikeStatus(id) == false) {
            param = null;
          } else {
            param = false;
          }
        }
        // 传了参数的话参数就是目标状态
        else {
          param = arg ? false : null;
        }
        final result = await _vm.changeLikeState(id, param);
        return result.success;
      case PostClickType.VIEW_POST:
        Navigator.pushNamed(context, PostDetailPage.routeName, arguments: id);
        return false;
      case PostClickType.VIEW_USER:
        Navigator.pushNamed(context, UserPage.routeName, arguments: id);
        return false;
      default:
        return false;
    }
  }
}

/// 筛选条件区域
class _FilterArea extends StatefulWidget {
  final PostsFilter filter;
  final Function() onFilterChanged;

  const _FilterArea(this.filter, this.onFilterChanged);

  @override
  _FilterAreaState createState() => _FilterAreaState();
}

class _FilterAreaState extends State<_FilterArea> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textCaptionStyle = theme.textTheme.caption;
    final textPrimaryCaptionStyle =
        textCaptionStyle.copyWith(color: theme.primaryColor);
    final label = widget.filter.labels.join(',');
    final following = widget.filter.users.map((e) => e.name).join(',');
    // 标签
    Widget labelWidget = _buildLabelOrFollowing(
      label,
      '标签',
      textCaptionStyle,
      textPrimaryCaptionStyle,
      _onLabelClick,
    );
    // 关注人
    Widget followingWidget = _buildLabelOrFollowing(
      following,
      '关注人',
      textCaptionStyle,
      textPrimaryCaptionStyle,
      _onFollowingClick,
    );
    // 搜索
    Widget searchWidget = _buildSearchBtn(
      primaryColor,
      textCaptionStyle,
      textPrimaryCaptionStyle,
    );
    // 排序
    Widget sortWidget = TextSwitch(
      leftText: '最新',
      rightText: '最热',
      animDuration: animDuration,
      defaultStatus: widget.filter.sortBy == 2,
      onChange: (status) {
        widget.filter.sortBy = status ? 2 : 1;
        widget.onFilterChanged();
      },
    );
    // 页面
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(child: labelWidget),
          Expanded(child: followingWidget),
          Expanded(child: searchWidget),
          sortWidget,
        ],
      ),
    );
  }

  // 标签和关注人按钮
  Widget _buildLabelOrFollowing(
    String text,
    String defaultText,
    TextStyle textCaptionStyle,
    TextStyle textPrimaryCaptionStyle,
    void Function() onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlineButton(
        child: text.isEmpty
            ? Text(defaultText,
                overflow: TextOverflow.ellipsis, style: textCaptionStyle)
            : Tooltip(
                message: text,
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: textPrimaryCaptionStyle,
                ),
              ),
        onPressed: onPressed,
      ),
    );
  }

  // 搜索按钮
  Widget _buildSearchBtn(
    Color primaryColor,
    TextStyle textCaptionStyle,
    TextStyle textPrimaryCaptionStyle,
  ) {
    Widget searchWidget = TextButton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.filter.searchContent,
              overflow: TextOverflow.ellipsis,
              style: textPrimaryCaptionStyle,
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: 2.0,
              top: textPrimaryCaptionStyle.fontSize * 0.125,
            ),
            child: Icon(
              Icons.search,
              size: textPrimaryCaptionStyle.fontSize * 1.5,
              color: widget.filter.searchContent.isEmpty
                  ? textCaptionStyle.color
                  : primaryColor,
            ),
          ),
        ],
      ),
      onPressed: _onSearchClick,
    );
    if (widget.filter.searchContent.isNotEmpty) {
      searchWidget = Tooltip(
        message: widget.filter.searchContent,
        child: searchWidget,
      );
    }
    searchWidget = Container(
      alignment: Alignment.centerRight,
      child: searchWidget,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
    );
    return searchWidget;
  }

  // 点标签
  void _onLabelClick() async {
    final result =
        await Navigator.pushNamed(context, SelectPostLabelPage.routeName);
    if (result == null || !mounted) return;
    setState(() {
      widget.filter.labels = result;
      widget.onFilterChanged();
    });
  }

  // 点关注人
  void _onFollowingClick() async {
    final result =
        await Navigator.pushNamed(context, SelectFollowingPage.routeName);
    if (result == null || !mounted) return;
    setState(() {
      widget.filter.users = result;
      widget.onFilterChanged();
    });
  }

  // 点击搜索
  void _onSearchClick() async {
    final result =
        await Navigator.pushNamed(context, SearchContentPage.routeName);
    if (result == null || !mounted) return;
    setState(() {
      widget.filter.searchContent = result;
      widget.onFilterChanged();
    });
  }
}
