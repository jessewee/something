import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../common/models.dart';
import '../../common/widgets.dart';
import '../../common/pub.dart';
import '../../configs.dart';
import '../vm/others.dart';
import '../model/post.dart';
import '../vm/posts_vm.dart';
import 'post_list.dart';
import 'search_content_page.dart';
import 'select_post_label_page.dart';

/// 用户发帖记录页
class UserPostPage extends StatefulWidget {
  static const routeName = '/forum/user_post_page';
  final UserPostPageArg arg;
  const UserPostPage(this.arg);

  @override
  _UserPostPageState createState() => _UserPostPageState();
}

class _UserPostPageState extends State<UserPostPage> {
  PostsVM _vm;
  StreamControllerWithData<Result<List<Post>>> _dataChanged;
  StreamControllerWithData<bool> _loading;
  bool _myself;

  @override
  void initState() {
    _dataChanged = StreamControllerWithData(null, broadcast: true);
    _loading = StreamControllerWithData(true);
    _vm = PostsVM();
    _vm.filter.userIds = [widget.arg.userId];
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadData(true));
    super.initState();
  }

  @override
  void dispose() {
    _dataChanged.dispose();
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_myself == null)
      _myself = widget.arg.userId == context.watch<UserVM>().user.id;
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<bool>(
          initialData: _loading.value,
          stream: _loading.stream,
          builder: (context, snapshot) => TextWithLoading(
            _myself ? '我的发帖' : '${widget.arg.userName}的发帖',
            snapshot.data == true,
          ),
        ),
      ),
      body: Column(
        children: [
          // 筛选条件
          _FilterArea(_vm.filter, () => _loadData(true)),
          // 列表显示
          Expanded(
            child: StreamBuilder<Result<List<Post>>>(
              initialData: _dataChanged.value,
              stream: _dataChanged.stream,
              builder: (context, snapshot) {
                final result = snapshot.data;
                final posts = result?.data ?? [];
                return PostList(
                  posts: posts,
                  loading: _dataChanged.value == null ? true : null,
                  noMoreData: _vm.noMoreData,
                  errorMsg: result?.fail == true ? result.msg : '',
                  loadData: _loadData,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 加载数据
  Future _loadData(bool refresh) async {
    _loading.add(true);
    final result = await _vm.getPosts(refresh: refresh);
    _loading.add(false);
    if (result.success) {
      _dataChanged.add(result);
    } else {
      showToast(result.msg);
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
    // 标签
    Widget labelWidget = _buildLabelOrFollowing(
      label,
      '标签',
      textCaptionStyle,
      textPrimaryCaptionStyle,
      _onLabelClick,
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

class UserPostPageArg {
  final String userId;
  final String userName;
  const UserPostPageArg(this.userId, this.userName);
}
