import 'dart:io';

import 'package:flutter/material.dart';
import 'package:page_video/gen/assets.gen.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _PageVideoItem extends StatefulWidget {
  final Uri uri;
  final Widget? child;
  final int currentIndex;
  final int activeIndex;
  final Widget? playEnd;
  final bool loop;

  const _PageVideoItem({
    required this.uri,
    this.child,
    required this.currentIndex,
    required this.activeIndex,
    this.playEnd,
    this.loop = false,
  });

  @override
  State<StatefulWidget> createState() => _PageVideoItemState();
}

class _PageVideoItemState extends State<_PageVideoItem> {
  late final VideoPlayerController controller;
  bool isUserPause = false;
  double playSpeed = 1;
  bool isPlayend = false;

  Uri get uri => widget.uri;

  @override
  void initState() {
    super.initState();
    if (uri.scheme == "assets") {
      controller = VideoPlayerController.asset(uri.path);
    } else if (uri.scheme == "file") {
      controller = VideoPlayerController.file(File(uri.path));
    } else if (uri.scheme == "http" || uri.scheme == "https") {
      controller = VideoPlayerController.networkUrl(uri);
    }

    controller.initialize().then((e) {
      if (widget.activeIndex == widget.currentIndex) {
        controller.play();
      }
      setState(() {});
    });
    controller.setLooping(widget.loop);
    controller.addListener(controllerListener);
  }

  void controllerListener() {
    if (!widget.loop) {
      // 判断是否播放结束
      if (controller.value.isInitialized &&
          controller.value.position >= controller.value.duration &&
          !controller.value.isPlaying) {
        if (!isPlayend) {
          isPlayend = true;
          setState(() {});
          // 这里可以做播放结束后的处理，比如显示播放结束UI
        }
      } else {
        if (isPlayend) {
          isPlayend = false;
          setState(() {});
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant _PageVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.activeIndex != widget.activeIndex) {
      // 切换了
      if (widget.activeIndex == widget.currentIndex) {
        controller.play();
      } else {
        controller.pause();
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(controllerListener);
    controller.dispose();
    super.dispose();
  }

  void onVideoTap() {
    if (controller.value.isPlaying) {
      controller.pause();
      isUserPause = true;
    } else {
      controller.play();
      isUserPause = false;
    }
    setState(() {});
  }

  void setPlaySpeed(double speed) async {
    controller.setPlaybackSpeed(speed);
    playSpeed = speed;
    if (speed > 1 && await Vibration.hasVibrator()) {
      Vibration.vibrate();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if ((widget.activeIndex - widget.currentIndex).abs() > 1) {
      return Container();
    }
    return Stack(
      children: [
        Container(color: Colors.black),
        if (controller.value.isInitialized && !isPlayend)
          VisibilityDetector(
            key: ValueKey(widget.currentIndex),
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            onVisibilityChanged: (e) {
              if (e.visibleFraction <= 0) {
                controller.pause();
              }
            },
          ),
        if (widget.playEnd != null && isPlayend) widget.playEnd!,
        if (widget.child != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: onVideoTap,
              onLongPressStart: (e) => setPlaySpeed(2),
              onLongPressEnd: (e) => setPlaySpeed(1),
              child: widget.child!,
            ),
          ),
        if (isUserPause)
          GestureDetector(
            onTap: onVideoTap,
            child: Center(
              child: Assets.icons.play.svg(width: 80, package: "page_video"),
            ),
          ),
        if (playSpeed != 1)
          Positioned(
            top: kToolbarHeight,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  "倍速中",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PageVideo extends StatefulWidget {
  const PageVideo({
    super.key,
    required this.itemCount,
    this.initialIndex,
    required this.buildUri,
    this.child,
    this.buildPlayEndWidget,
    this.onPageChanged,
    this.scrollDirection = Axis.vertical,
    this.preloadPagesCount = 3,
    this.loop = false,
  });
  final int itemCount;
  final int? initialIndex;
  final Uri Function(int index) buildUri;
  final Widget Function(BuildContext context, int index)? child;
  final Widget Function(BuildContext context, int index)? buildPlayEndWidget;
  final ValueChanged? onPageChanged;
  final Axis scrollDirection;
  final int preloadPagesCount;
  final bool loop;

  @override
  State<StatefulWidget> createState() => _PageVideoStte();
}

class _PageVideoStte extends State<PageVideo> {
  int _activeIndex = 0;
  late final PreloadPageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PreloadPageController(
      initialPage: widget.initialIndex ?? 0,
    );
    _pageController.addListener(pageListener);
  }

  void pageListener() {}

  @override
  void didUpdateWidget(covariant PageVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _pageController.jumpToPage(widget.initialIndex ?? 0);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(pageListener);
    _pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int newPage) {
    if (_pageController.page != null && _pageController.page != _activeIndex) {
      _activeIndex = _pageController.page!.round();
    }
    widget.onPageChanged?.call(newPage);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        return false;
      },
      child: PreloadPageView.builder(
        controller: _pageController,
        preloadPagesCount: widget.preloadPagesCount,
        scrollDirection: widget.scrollDirection,
        itemCount: widget.itemCount,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          return _PageVideoItem(
            currentIndex: index,
            activeIndex: _activeIndex,
            uri: widget.buildUri(index),
            playEnd: widget.buildPlayEndWidget?.call(context, index),
            loop: widget.loop,
            child: widget.child?.call(context, index),
          );
        },
      ),
    );
  }
}
