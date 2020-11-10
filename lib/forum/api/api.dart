import 'package:something/forum/model/media.dart';

import '../../common/network.dart';
import '../../common/models.dart';
import '../../common/pub.dart';
import '../../test_generator.dart';
import '../model/post.dart';
import '../vm/others.dart';

/// 上传文件
Future<Result> upload(
  String path,
  FileType type, {
  Function(double) onProgress,
  String tag,
}) async {
  // TODO
  await Future.delayed(Duration(seconds: 1));
  return Future.value(Result.success({
    'url': TestGenerator.generateImg(),
    'thumbUrl': TestGenerator.generateImg(),
    'width': TestGenerator.generateNumber(100),
    'height': TestGenerator.generateNumber(100),
  }));
}

/// 获取帖子列表
Future<Result<DataWidthPageInfo<Post>>> getPosts(
  int dataIdx,
  int dataPageSize,
  PostsFilter filter,
) async {
  final result = await network.get('/forum/get_posts', params: {
    'data_idx': dataIdx,
    'data_count': dataPageSize,
    'sort_by': filter.sortBy,
    'search_content': filter.searchContent,
    'labels': filter.labels.join(','),
    'users': filter.users.map((u) => u.id).join(',')
  });
  if (result.fail) return result;
  final list = result.data['list']
      .map<Post>((e) => Post(
            id: e['id'] ?? '',
            posterId: e['poster_id'] ?? '',
            avatar: e['avatar'] ?? '',
            avatarThumb: e['avatar_thumb'] ?? '',
            name: e['name'] ?? '',
            date: e['date'] ?? '',
            content: e['text'] ?? '',
            label: e['label'] ?? '',
            likeCnt: e['like_count'] ?? 0,
            dislikeCnt: e['dislike_count'] ?? 0,
            replyCnt: e['reply_count'] ?? 0,
            myAttitude: e['attitude'] ?? 0,
            posterFollowed: e['poster_followed'] == true,
            medias: e['medias']
                .map<Media>((m) {
                  if (m['type'] == 'image') {
                    return ImageMedia(
                            thumbUrl: m['thumb_url'] ?? '',
                            url: m['url'] ?? '',
                            width: m['width'] ?? 50,
                            height: m['height']) ??
                        50;
                  } else if (m['type' == 'video']) {
                    return VideoMedia(m['thumb_url'] ?? '', m['url'] ?? '');
                  }
                  return null;
                })
                .where((e) => e != null)
                .toList(),
          ))
      .toList();
  return Result.success(DataWidthPageInfo(
      list,
      result.data['total_count'] ?? list.length,
      result.data['last_data_index'],
      list.length));
}
