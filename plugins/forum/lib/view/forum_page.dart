import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forum/reposity/reposity.dart';
import 'package:forum/vm/forum.dart';

/// 社区页
class ForumPage extends StatefulWidget {
  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  ForumVM _vm;

  @override
  void initState() {
    _vm = ForumVM();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _vm.loadPosts().then((_) => setState(() {}));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// 切换显示方式
    /// 筛选条件
    /// 列表显示
    return Container();
  }
}

/// 筛选条件区域
class FilterArea extends StatelessWidget {
  final PostsFilter filter;
  final Function(PostsFilter) onFilterChanged;
  const FilterArea(this.filter, this.onFilterChanged);
  @override
  Widget build(BuildContext context) {
    // 标签
    // 关注人
    // 搜索
    // 最新、最热
    throw UnimplementedError();
  }
}
