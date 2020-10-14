import 'dart:math';

import 'base/extensions.dart';

class TestGenerator {
  static const imgs = [
    'http://attach.bbs.miui.com/forum/201408/07/194456i55q58pqnb55fi88.jpg',
    'http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1208/15/c0/12924355_1344999165562.jpg',
    'http://attach.bbs.miui.com/forum/201310/19/235356fyjkkugokokczyo0.jpg',
    'http://attach.bbs.miui.com/forum/201311/17/174124tp3sa6vvckc25oc8.jpg',
    'http://hbimg.b0.upaiyun.com/b238ed8327c456bfd9807e0253138b4e2c11d23920b55-7wxt0v_fw658',
    'http://attachments.gfan.com/forum/201504/06/0638202b7ws2d2w4bzsyuu.jpg'
  ];

  static String generateImg() {
    final idx = Random.secure().nextInt(imgs.length + 1);
    return idx < imgs.length ? imgs[idx] : '';
  }

  static List<String> generateImgs() {
    final cnt = Random.secure().nextInt(10);
    List<String> result = [];
    int idx = 0;
    while (idx < cnt) {
      idx++;
      result.add(generateImg());
    }
    return result;
  }

  static String generateChinese(int maxCount) {
    final random = Random.secure();
    final count = random.nextInt(maxCount) + 1;
    final list = <int>[];
    int idx = 0;
    while (idx < count) {
      idx++;
      list.add(random.nextInt(0x9FA5 - 0x4E00) + 0x4E00);
    }
    return String.fromCharCodes(list);
  }

  static String generateId(int maxCount) {
    const tmp = [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z',
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9'
    ];
    final result = StringBuffer();
    final random = Random.secure();
    final count = random.nextInt(maxCount) + 1;
    int idx = 0;
    while (idx < count) {
      idx++;
      result.write(tmp[random.nextInt(tmp.length)]);
    }
    return result.toString();
  }

  static String generateDate() {
    final random = Random.secure();
    final result = StringBuffer('20');
    result.write(random.nextInt(3).toString());
    result.write(random.nextInt(10).toString());
    result.write('-');
    var tmp = random.nextInt(12) + 1;
    result.write(tmp.toStringWithTwoMinLength());
    result.write('-');
    tmp = random.nextInt(30) + 1;
    result.write(tmp.toStringWithTwoMinLength());
    result.write(' ');
    tmp = random.nextInt(24) + 1;
    result.write(tmp.toStringWithTwoMinLength());
    result.write(':');
    tmp = random.nextInt(60) + 1;
    result.write(tmp.toStringWithTwoMinLength());
    result.write(':');
    tmp = random.nextInt(60) + 1;
    result.write(tmp.toStringWithTwoMinLength());
    return result.toString();
  }

  static int generateNumber(int max, [int min = 0]) {
    int result;
    if (min == 0) {
      result = Random.secure().nextInt(max);
    } else {
      final tmp = max - min;
      result = Random.secure().nextInt(tmp) + min;
    }
    return result;
  }
}
