import 'package:flutter/material.dart';

import '../../common/pub.dart';
import '../../common/widgets.dart';
import '../../common/models.dart';

import '../repository/repository.dart' as repository;
import 'select_post_label_page.dart';
import 'post_long_content_sheet.dart';
import 'me_page.dart';
import 'posts_page.dart';

/// 社区页
class ForumPage extends StatefulWidget {
  static const routeName = '/forum';

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  int _curTabIdx = 0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _curTabIdx,
        type: BottomNavigationBarType.shifting,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: primaryColor,
            label: '社区',
            icon: Icon(Icons.mode_comment),
          ),
          BottomNavigationBarItem(
            backgroundColor: primaryColor,
            label: '我的',
            icon: Icon(Icons.menu),
          ),
        ],
        onTap: (index) => setState(() => _curTabIdx = index),
      ),
      body: IndexedStack(
        index: _curTabIdx,
        children: <Widget>[PostsPage(), MePage()],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: IconButton(
        icon: Icon(Icons.add),
        onPressed: () => PostLongContentSheet.show(context, _onPost),
      ),
    );
  }

  // 发帖
  Future<bool> _onPost(String text, List<UploadedFile> medias) async {
    final selected = await SelectionSheet.show(
      context,
      textSelections: ['选择', '输入'],
    );
    String text;
    if (selected == 1) {
      text = await Navigator.pushNamed(
        context,
        SelectPostLabelPage.routeName,
        arguments: true,
      );
    } else {
      text = await TextFileSheet.show(context, maxLength: 20);
    }
    if (text?.isNotEmpty != true) {
      showToast('请选择或填写标签');
      return false;
    }
    final result = await repository.post(
      label: text,
      content: text,
      mediaIds: medias.map((e) => e.id).toList(),
    );
    if (result.fail) {
      showToast(result.msg);
      return false;
    }
    return true;
  }
}
