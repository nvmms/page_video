import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:nvmms_page_video/page_video.dart';

void main() {
  testWidgets('PageVideo basic usage smoke test', (WidgetTester tester) async {
    final uris = [
      Uri.parse(
        'https://www.sample-videos.com/video123/mp4/240/big_buck_bunny_240p_1mb.mp4',
      ),
      Uri.parse(
        'https://www.sample-videos.com/video123/mp4/240/big_buck_bunny_240p_2mb.mp4',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageVideo(
            itemCount: uris.length,
            buildUri: (index) => uris[index],
            child: (context, index) => Center(child: Text('Overlay $index')),
            buildPlayEndWidget: (context, index) =>
                Center(child: Text('播放结束 $index')),
            onPageChanged: (index) {},
            scrollDirection: Axis.vertical,
            preloadPagesCount: 1,
            loop: false,
          ),
        ),
      ),
    );

    // 检查第一页 overlay 是否显示
    expect(find.text('Overlay 0'), findsOneWidget);

    // 滑动到第二页
    await tester.drag(find.byType(PageVideo), const Offset(0, -500));
    await tester.pumpAndSettle();

    // 检查第二页 overlay 是否显示
    expect(find.text('Overlay 1'), findsOneWidget);
  });
}
