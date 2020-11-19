import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../common/event_bus.dart';
import '../../configs.dart';
import '../../common/pub.dart';
import '../../common/widgets.dart';
import '../../common/extensions.dart';

import 'post_list.dart';
import 'post_wall.dart';
import 'search_content_page.dart';
import 'select_following_page.dart';
import 'select_post_label_page.dart';
import '../model/post.dart';
import '../vm/posts_vm.dart';
import '../vm/others.dart';

/// 帖子列表页，在社区首页的标签上显示，不注册都路由
class PostsPage extends StatefulWidget {
  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage>
    with AutomaticKeepAliveClientMixin {
  PostsVM _vm;
  StreamControllerWithData<bool> _displayType; // 显示方式，true:帖子墙、false:列表
  StreamControllerWithData<Result<List<Post>>> _dataChanged;
  StreamControllerWithData<bool> _loading;

  @override
  void initState() {
    _displayType = StreamControllerWithData(true, broadcast: true);
    _dataChanged = StreamControllerWithData(null, broadcast: true);
    _loading = StreamControllerWithData(true);
    _vm = PostsVM();
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadData(true));
    eventBus.on(EventBusType.forumPosted, (arg) {
      if (arg is! Post) {
        _loadData(true);
      } else {
        final list = _vm.addNewPostAndReturnList(arg);
        _dataChanged.add(Result.success(list));
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _displayType.dispose();
    _dataChanged.dispose();
    _loading.dispose();
    eventBus.off(type: EventBusType.forumPosted);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            // 筛选条件
            _FilterArea(_vm.filter, () => _loadData(true)),
            // 列表显示
            Expanded(
              child: StreamBuilder<Result<List<Post>>>(
                initialData: _dataChanged.value,
                stream: _dataChanged.stream,
                builder: (context, snapshot) => _buildContent(snapshot.data),
              ),
            ),
          ],
        ),
        // 切换显示方式
        StreamBuilder<bool>(
          initialData: _displayType.value,
          stream: _displayType.stream,
          builder: (context, snapshot) => AnimatedSwitcher(
            duration: animDuration,
            transitionBuilder: (child, animation) => ScaleTransition(
              child: child,
              scale: animation,
            ),
            child: FloatingActionButton(
              key: ValueKey(_displayType),
              heroTag: 'posts_page_floating_action_button',
              mini: true,
              child: Icon(
                snapshot.data ? Icons.auto_awesome_motion : Icons.list,
                color: Colors.white,
              ),
              onPressed: () => _displayType.add(!snapshot.data),
            ),
          ),
        ).positioned(right: null, top: null),
        // 加载中
        StreamBuilder(
          initialData: _loading.value,
          stream: _loading.stream,
          builder: (context, snapshot) => Visibility(
            visible: snapshot.data == true,
            child: Container(
              margin: const EdgeInsets.only(left: 5.0),
              width: 15.0,
              height: 15.0,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.grey),
              ),
            ),
          ),
        ).positioned(right: null, bottom: null),
      ],
    );
  }

  // 内容显示
  Widget _buildContent(Result<List<Post>> result) {
    final posts = result?.data ?? [];
    return StreamBuilder<bool>(
      initialData: _displayType.value,
      stream: _displayType.stream,
      builder: (context, dt) => AnimatedSwitcher(
        duration: animDuration,
        child: dt.data
            ? PostWall(
                posts: posts,
                loading: _dataChanged.value == null ? true : null,
                noMoreData: _vm.noMoreData,
                errorMsg: result?.fail == true ? result.msg : '',
                loadData: _loadData,
              )
            : PostList(
                posts: posts,
                loading: _dataChanged.value == null ? true : null,
                noMoreData: _vm.noMoreData,
                errorMsg: result?.fail == true ? result.msg : '',
                loadData: _loadData,
              ),
      ),
    );
  }

  // 加载数据
  Future _loadData(bool refresh) async {
    _loading.add(true);
    final result = await _vm.getPosts(
      refresh: refresh,
      // 列表比墙少的话会有问题，一般不会少
      dataSize: _displayType.value ? 20 : 100,
      onePageData: _displayType.value,
    );
    _loading.add(false);
    if (result.success) {
      _dataChanged.add(result);
    } else {
      _dataChanged.add(Result());
      showToast(result.msg);
    }
  }

  @override
  bool get wantKeepAlive => true;
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
    final following = widget.filter.userIds.join(',');
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
    if (!mounted || result == null || result is! List) return;
    setState(() {
      widget.filter.userIds = (result as List).map((e) => e.userId);
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
