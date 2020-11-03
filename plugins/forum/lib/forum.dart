library forum;

import 'package:base/base.dart';
import 'package:flutter/widgets.dart';

import 'model/post.dart';
import 'view/select_following_page.dart';
import 'view/select_post_label_page.dart';
import 'view/forum_page.dart';
import 'view/search_content_page.dart';
import 'view/post_detail_page.dart';
import 'view/user_page.dart';

final Map<String, WidgetBuilder> forumRoutes = {
  ForumPage.routeName: (_) => ForumPage(),
  SearchContentPage.routeName: (_) => SearchContentPage(),
  SelectPostLabelPage.routeName: (_) => SelectPostLabelPage(),
  SelectFollowingPage.routeName: (context) {
    final arg = ModalRoute.of(context).settings.arguments;
    if (arg != null && arg is bool) {
      return SelectFollowingPage(singleSelect: arg);
    } else {
      return SelectFollowingPage();
    }
  },
  PostDetailPage.routeName: (context) {
    final arg = ModalRoute.of(context).settings.arguments;
    if (arg == null || arg is! Post) return ParamErrorPage(arg);
    return PostDetailPage(arg);
  },
  UserPage.routeName: (context) {
    final arg = ModalRoute.of(context).settings.arguments;
    if (arg == null || arg is! String) return ParamErrorPage(arg);
    return UserPage(arg);
  },
};
