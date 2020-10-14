import 'package:base/base/pub.dart';
import 'package:forum/model/post.dart';
import 'package:forum/repository/repository.dart';

/// 数据和逻辑处理
class ForumVM {
  /// 筛选条件
  PostsFilter filter = PostsFilter();

  /// 当前数据索引
  int dataIdx = 0;

  /// 帖子列表
  List<Post> posts = [];

  /// 加载数据
  Future<Result> loadPosts({
    int dataPageSize = 100,
    bool replace = false,
  }) async {
    final result = await Repository.getPosts(
      dataIdx: dataIdx,
      dataPageSize: dataPageSize,
      filter: filter,
    );
    if (result.fail) return result;
    if (replace || dataIdx == 0) {
      posts = result.data;
    } else {
      posts.addAll(result.data);
    }
    return result;
  }
}
