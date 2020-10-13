import 'package:forum/model/other.dart';
import 'package:forum/model/post.dart';

class Reposity {
  /// 获取帖子列表
  static Future<List<Post>> getPosts({
    int dataIdx = 0,
    int dataPageSize = 100,
    PostsFilter filter,
  }) async {
    // TODO
    return [];
  }
}

/// 帖子列表筛选条件
class PostsFilter {
  /// 标签
  List<PostLabel> labels = [];

  /// 关注人
  List<ForumUser> users = [];

  /// 搜索
  String searchContent = '';

  /// 1最新、2最热
  int sortBy = 1;
}
