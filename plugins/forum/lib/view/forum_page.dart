import 'package:base/base/configs.dart';
import 'package:base/base/pub.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forum/repository/repository.dart';
import 'package:forum/view/post_list.dart';
import 'package:forum/view/post_wall.dart';
import 'package:forum/view/search_content_page.dart';
import 'package:forum/vm/forum.dart';

/// 社区页
class ForumPage extends StatefulWidget {
  static const routeName = '/forum';

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  ForumVM _vm;
  bool _displayType = true; // 显示方式，true:帖子墙、false:列表

  @override
  void initState() {
    _vm = ForumVM();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) => _loadData());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('社区'),
        actions: [
          /// 切换显示方式
          AnimatedSwitcher(
            duration: animDuration,
            transitionBuilder: (child, animation) =>
                ScaleTransition(child: child, scale: animation),
            child: IconButton(
              key: ValueKey(_displayType),
              color: Colors.white,
              icon: Icon(_displayType ? Icons.auto_awesome_motion : Icons.list),
              onPressed: () => setState(() => _displayType = !_displayType),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选条件
          FilterArea(_vm.filter, () => _loadData(true)),
          // 列表显示
          Expanded(
            child: AnimatedSwitcher(
              duration: animDuration,
              child: _displayType ? PostWall(_vm) : PostList(_vm),
            ),
          ),
        ],
      ),
    );
  }

  void _loadData([bool replace = false]) async {
    final result = await _vm.loadPosts(
      dataPageSize: _displayType ? 20 : 100,
      replace: replace,
    );
    if (result.success) {
      setState(() {});
    } else {
      showToast(result.msg);
    }
  }
}

/// 筛选条件区域
class FilterArea extends StatefulWidget {
  final PostsFilter filter;
  final Function() onFilterChanged;

  const FilterArea(this.filter, this.onFilterChanged);

  @override
  _FilterAreaState createState() => _FilterAreaState();
}

class _FilterAreaState extends State<FilterArea> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textCaptionStyle = theme.textTheme.caption;
    final textPrimaryCaptionStyle =
        theme.textTheme.caption.copyWith(color: primaryColor);
    final label = widget.filter.labels.map((e) => e.title).join(',');
    final followed = widget.filter.users.map((e) => e.name).join(',');
    // 标签
    Widget labelWidget = OutlineButton(
      child: Text(
        label.isEmpty ? '标签' : label,
        overflow: TextOverflow.ellipsis,
        style: textPrimaryCaptionStyle,
      ),
      onPressed: _onLabelClick,
    );
    labelWidget = Container(
      child: labelWidget,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
    );
    // 关注人
    Widget followedWidget = OutlineButton(
      child: Text(
        followed.isEmpty ? '关注人' : followed,
        overflow: TextOverflow.ellipsis,
        style: textPrimaryCaptionStyle,
      ),
      onPressed: _onFollowedClick,
    );
    followedWidget = Container(
      child: followedWidget,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
    );
    // 搜索
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
            ),
          ),
        ],
      ),
      onPressed: _onSearchClick,
    );
    searchWidget = Container(
      alignment: Alignment.centerRight,
      child: searchWidget,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
    );
    // 排序
    Widget sortWidget = AnimatedSwitcher(
      duration: animDuration,
      child: RichText(
        key: ValueKey(widget.filter.sortBy),
        text: widget.filter.sortBy == 2
            // 最热
            ? TextSpan(
                children: [
                  TextSpan(text: '最新 / ', style: textCaptionStyle),
                  TextSpan(text: '最热', style: textPrimaryCaptionStyle),
                ],
              )
            // 最新
            : TextSpan(
                children: [
                  TextSpan(text: '最新', style: textPrimaryCaptionStyle),
                  TextSpan(text: ' / 最热', style: textCaptionStyle),
                ],
              ),
      ),
    );
    sortWidget = TextButton(
      onPressed: () => setState(() {
        if (widget.filter.sortBy != 2) {
          widget.filter.sortBy = 2;
        } else {
          widget.filter.sortBy = 1;
        }
      }),
      child: sortWidget,
    );
    // 页面
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(child: labelWidget),
          Expanded(child: followedWidget),
          Expanded(child: searchWidget),
          sortWidget,
        ],
      ),
    );
  }

  // 点标签
  void _onLabelClick() async {
    // TODO
  }
  // 点关注人
  void _onFollowedClick() async {
// TODO
  }

  // 点击搜索
  void _onSearchClick() async {
    final result = await Navigator.pushNamed(
      context,
      SearchContentPage.routeName,
    );
    if (result != null && result != widget.filter.searchContent) {
      setState(() {
        widget.filter.searchContent = result;
        widget.onFilterChanged();
      });
    }
  }
}
