import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nvmms_page_video/gen/assets.gen.dart';
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
  final Color? backgroundColor;

  const _PageVideoItem({
    required this.uri,
    this.child,
    required this.currentIndex,
    required this.activeIndex,
    this.playEnd,
    this.loop = false,
    this.backgroundColor,
  });

  @override
  State<StatefulWidget> createState() => _PageVideoItemState();
}

class _PageVideoItemState extends State<_PageVideoItem> {
  late final VideoPlayerController controller;
  bool isUserPause = false;
  double playSpeed = 1;
  bool isPlayend = false;
  bool isPlaying = false;
  double videoTotal = 0.0;
  ValueNotifier<double> videoPosition = ValueNotifier(0.0);
  ValueNotifier<bool> isDragSlider = ValueNotifier(false);

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
      videoTotal = controller.value.duration.inMicroseconds.toDouble();
      if (widget.activeIndex == widget.currentIndex) {
        controller.play();
      }
      setState(() {});
    });
    controller.setLooping(widget.loop);
    controller.addListener(controllerListener);
  }

  void controllerListener() {
    if (!isDragSlider.value) {
      videoPosition.value = controller.value.position.inMicroseconds.toDouble();
    }
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
    if (controller.value.isPlaying != isPlaying) {
      isPlaying = controller.value.isPlaying;
      setState(() {});
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
      Vibration.vibrate(duration: 103);
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
        /// 占位背景
        Container(
          // color: Colors.amber,
          color: widget.backgroundColor ??
              ThemeData.dark().bottomNavigationBarTheme.backgroundColor ??
              ThemeData.dark().colorScheme.surface,
        ),

        /// 视频播放器
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

        /// 播放结束组件
        if (widget.playEnd != null && isPlayend) widget.playEnd!,

        /// 内容组件，兼具暂停、播放、倍速功能
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            child: GestureDetector(
              onTap: onVideoTap,
              onLongPressStart: (e) => setPlaySpeed(2),
              onLongPressEnd: (e) => setPlaySpeed(1),
              child: ValueListenableBuilder(
                valueListenable: isDragSlider,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: value ? 0 : 1,
                    duration: Duration(milliseconds: 100),
                    child: widget.child,
                  );
                },
              ),
            ),
          ),
        ),

        /// 底部进度条
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 2,
          child: ValueListenableBuilder(
            valueListenable: videoPosition,
            builder: (context, value, child) {
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 2,
                  ), // 默认 6
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 0.0),
                  trackHeight: 2.0,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  min: 0,
                  max: videoTotal,
                  value: value,
                  onChangeStart: (e) {
                    isDragSlider.value = true;
                  },
                  onChangeEnd: (e) {
                    isDragSlider.value = false;
                    controller.seekTo(Duration(microseconds: e.toInt()));
                  },
                  onChanged: (e) {
                    videoPosition.value = e;
                  },
                ),
              );
            },
          ),
        ),

        /// 暂停图标
        if (isUserPause)
          GestureDetector(
            onTap: onVideoTap,
            child: Center(
              child:
                  Assets.icons.play.svg(width: 68, package: "nvmms_page_video"),
            ),
          ),

        /// 倍速播放倍率组件
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
  final ValueChanged<int>? onPageChanged;
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
