# page_video

一个支持预加载、竖直/水平滑动、自动播放、倍速、播放结束自定义等功能的视频翻页组件，适用于短视频、Feed流等场景。

## 特性

- 支持本地文件、网络视频、assets 资源播放（自动识别 Uri scheme）
- 支持竖直或水平滑动切换视频
- 支持页面预加载，提升切换体验
- 支持自动播放、循环播放
- 支持自定义覆盖内容（如点赞、评论按钮等）
- 支持自定义播放结束时的 Widget
- 支持倍速播放与振动反馈
- 支持页面切换回调

## 快速开始

### 1. 添加依赖

在你的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  page_video: ^0.0.1
```

### 2. 使用示例

```dart
PageVideo(
  itemCount: videoList.length,
  buildUri: (index) => Uri.file(videoList[index]), // 支持 file/http/https/assets
  initialIndex: 0,
  child: (context, index) => MyOverlayWidget(index: index),
  buildPlayEndWidget: (context, index) => Center(child: Text('播放结束')),
  onPageChanged: (index) => print('切换到第$index页'),
  scrollDirection: Axis.vertical,
  preloadPagesCount: 3,
  loop: false,
)
```

## API 说明

| 参数名                | 说明                           |
|----------------------|-------------------------------|
| itemCount            | 视频数量                       |
| initialIndex         | 初始页索引                     |
| buildUri             | 构建视频资源 Uri 的方法         |
| child                | 构建覆盖内容的 Widget           |
| buildPlayEndWidget   | 构建播放结束时显示的 Widget     |
| onPageChanged        | 页面切换回调                   |
| scrollDirection      | 滑动方向（Axis.vertical/horizontal）|
| preloadPagesCount    | 预加载页面数量                 |
| loop                 | 是否循环播放                   |

## 进阶用法

- 支持自定义倍速、振动反馈
- 支持自定义播放结束 UI
- 支持 assets、file、http/https 多种资源类型

## 贡献与反馈

如有问题或建议，欢迎提 issue 或 PR。

更多信息请参考源码或 [Flutter 官方文档](https://flutter.dev/docs).
