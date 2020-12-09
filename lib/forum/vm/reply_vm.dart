import '../../common/event_bus.dart';
import '../../common/models.dart';
import '../../common/extensions.dart';
import '../../common/pub.dart';
import '../model/post.dart';
import '../repository/repository.dart' as repository;

class ReplyVM {
  /// 发帖时用这个参数
  final bool showLabel;

  /// 回复楼主时用这个参数
  final String postId;

  /// 回复层主时用这个参数，同时还必须传postId
  final String floorId;

  /// 回复非层主时用这个参数，同时还必须传floorId和postId
  final String innerFloorId;

  /// 层内回复目标id
  final String targetId;

  /// 层内回复目标名字
  final String targetName;

  final String defaultText;

  /// 回复成功的回调，会把回复内容封装成Post、Floor、InnerFloor对象
  final void Function(PostBase) onReplied;

  String get hintText => innerFloorId?.isNotEmpty == true
      ? '回复$targetName'
      : floorId?.isNotEmpty == true
          ? '回复层主'
          : postId?.isNotEmpty == true
              ? '回复楼主'
              : '发帖';
  String postLabel = '';

  ReplyVM({
    this.showLabel,
    this.postId,
    this.floorId,
    this.innerFloorId,
    this.targetId,
    this.targetName,
    this.defaultText,
    this.onReplied,
  });

  Future<bool> submit(User user, String text, List<UploadedFile> medias) async {
    // 层内回复
    if (innerFloorId?.isNotEmpty == true) {
      final result = await repository.reply(
        postId: postId,
        floorId: floorId,
        innerFloorId: innerFloorId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      onReplied(InnerFloor(
        id: result.data.innerFloorId,
        posterId: user.id,
        avatar: user.avatar,
        avatarThumb: user.avatarThumb,
        name: user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        innerFloor: result.data.innerFloor,
        targetId: targetId ?? '',
        targetName: targetName ?? '',
        postId: postId,
        floorId: floorId,
      ));
      return true;
    }
    // 回复层主
    if (floorId?.isNotEmpty == true) {
      final result = await repository.reply(
        postId: postId,
        floorId: floorId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      onReplied(InnerFloor(
        id: result.data.innerFloorId,
        posterId: user.id,
        avatar: user.avatar,
        avatarThumb: user.avatarThumb,
        name: user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        innerFloor: result.data.innerFloor,
        postId: postId,
        floorId: floorId,
      ));
      return true;
    }
    // 回复楼主
    if (postId?.isNotEmpty == true) {
      final result = await repository.reply(
        postId: postId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      onReplied(Floor(
        id: result.data.floorId,
        posterId: user.id,
        avatar: user.avatar,
        avatarThumb: user.avatarThumb,
        name: user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        floor: result.data.floor,
        postId: postId,
      ));
      return true;
    }
    // 发帖
    if (postLabel?.isNotEmpty != true) return false;
    final result = await repository.post(
      label: postLabel,
      content: text,
      mediaIds: medias.map((e) => e.id).toList(),
    );
    if (result.fail) {
      showToast(result.msg);
      return false;
    }
    eventBus.sendEvent(
      EventBusType.forumPosted,
      Post(
          id: result.data,
          label: postLabel,
          posterId: user.id,
          avatar: user.avatar,
          avatarThumb: user.avatarThumb,
          name: user.name,
          date: DateTime.now().format(),
          content: text,
          medias: medias),
    );
    return true;
  }
}
