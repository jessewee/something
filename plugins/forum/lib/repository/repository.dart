import 'package:base/base/pub.dart';
import 'package:base/test_generator.dart';
import 'package:forum/model/m.dart';
import 'package:forum/model/media.dart';
import 'package:forum/model/post.dart';

/// 数据仓库
class Repository {
  /// 获取帖子标签列表
  static Future<Result<List<String>>> getPostLabels(
    String searchContent,
  ) async {
    // TODO
    return Result.success(
      List.generate(
        TestGenerator.generateNumber(100),
        (index) => TestGenerator.generateChinese(10),
      ),
    );
  }

  /// 获取帖子列表
  static Future<Result<List<Post>>> getPosts({
    int dataIdx = 0,
    int dataPageSize = 100,
    PostsFilter filter,
  }) async {
    // TODO
    return Result.success(
      List.generate(
        dataPageSize,
        (index) => Post(
          id: (dataIdx + index).toString(),
          posterId: TestGenerator.generateId(12),
          avatar: TestGenerator.generateImg(),
          avatarThumb: TestGenerator.generateImg(),
          name: TestGenerator.generateChinese(20),
          date: TestGenerator.generateDate(),
          content: TestGenerator.generateChinese(500),
          replyCnt: TestGenerator.generateNumber(9999),
          likeCnt: TestGenerator.generateNumber(9999),
          myAttitude: TestGenerator.generateNumber(1, -1),
          medias: TestGenerator.generateImgs()
              .map((e) => ImageMedia(e, TestGenerator.generateImg()))
              .toList(),
        ),
      ),
    );
  }
}

/// 帖子列表筛选条件
class PostsFilter {
  /// 标签
  List<String> labels = [];

  /// 关注人
  List<ForumUser> users = [];

  /// 搜索
  String searchContent = '';

  /// 1最新、2最热
  int sortBy = 1;
}
