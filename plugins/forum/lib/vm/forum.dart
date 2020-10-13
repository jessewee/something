import 'package:forum/model/post.dart';
import 'package:forum/reposity/reposity.dart';

/// 数据和逻辑处理
class ForumVM {
  /// 筛选条件
  PostsFilter filter = PostsFilter();

  /// 当前数据索引
  int dataIdx = 0;

  /// 每页数据数量
  int dataPageSize = 100;

  /// 帖子列表
  List<Post> posts = [];

  /// 加载数据
  Future loadPosts() async {
    posts = await Reposity.getPosts(
      dataIdx: dataIdx,
      dataPageSize: dataPageSize,
      filter: filter,
    );
  }
}
