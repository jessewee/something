import 'package:base/base/pub.dart';
import 'package:base/model/m.dart';
import 'package:base/test_generator.dart';

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
