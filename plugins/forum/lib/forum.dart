library forum;

import 'package:flutter/widgets.dart';

import 'view/select_following_page.dart';
import 'view/select_post_label_page.dart';
import 'view/forum_page.dart';
import 'view/search_content_page.dart';

final Map<String, WidgetBuilder> forumRoutes = {
  ForumPage.routeName: (_) => ForumPage(),
  SearchContentPage.routeName: (_) => SearchContentPage(),
  SelectPostLabelPage.routeName: (_) => SelectPostLabelPage(),
  SelectFollowingPage.routeName: (_) => SelectFollowingPage(),
};
