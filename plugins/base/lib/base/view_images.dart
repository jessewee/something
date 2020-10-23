import 'dart:async';

import 'package:base/base/pub.dart';
import 'package:flutter/material.dart';

import 'widgets.dart';

// 浏览图片
Future viewImages(BuildContext context, List<String> imageUrls,
    [int curIndex = 0]) {
  return showGeneralDialog(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) => ViewImages(imageUrls, curIndex),
      );
    },
  );
}

class ViewImages extends StatefulWidget {
  final List<String> imageUrls;
  final int curIndex;

  const ViewImages(this.imageUrls, [this.curIndex = 0]);

  @override
  _ViewImagesState createState() => _ViewImagesState();
}

class _ViewImagesState extends State<ViewImages>
    with SingleTickerProviderStateMixin {
  TabController _controller;
  StreamControllerWithData<int> _pageChanged;

  @override
  void initState() {
    _controller = TabController(
      length: widget.imageUrls.length,
      vsync: this,
      initialIndex: widget.curIndex,
    );
    _pageChanged = StreamControllerWithData(widget.curIndex);
    _controller.addListener(() {
      _pageChanged.add(_controller.index, ignoreIfSameValue: true);
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageChanged.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgets = widget.imageUrls.map((e) {
      return InteractiveViewer(child: ImageWithUrl(e, fit: BoxFit.contain));
    }).toList();
    final textStyle =
        Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white);
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          TabBarView(children: widgets, controller: _controller),
          Positioned(
            right: 10.0,
            bottom: 10.0,
            child: StreamBuilder<int>(
                initialData: widget.curIndex,
                stream: _pageChanged.stream,
                builder: (context, snapshot) {
                  return Text(
                    '${snapshot.data} / ${_controller.length}',
                    style: textStyle,
                  );
                }),
          ),
        ],
      ),
    );
  }
}
