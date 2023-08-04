import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

const drawerWidth = 300.0;
const drawerEdgeWidth = 100.0;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: PageWithDrawer(),
      ),
    );
  }
}

class PageWithDrawer extends StatefulWidget {
  const PageWithDrawer({
    super.key,
  });

  @override
  State<PageWithDrawer> createState() => _PageWithDrawerState();
}

class _PageWithDrawerState extends State<PageWithDrawer>
    with TickerProviderStateMixin {
  double dragStartDy = 0;
  double lastDragDx = 0;

  late final animCtrl = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  late final curtainAnimCtrl = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  final impactPointNotifier = ValueNotifier<double>(0.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      debugPrint('position: ${-(1 - animCtrl.value) * drawerWidth}');
      return ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Stack(
          children: [
            Positioned.fill(
              child: buildPage(),
            ),
            AnimatedBuilder(
              animation: animCtrl,
              builder: (context, child) {
                return Positioned(
                  bottom: 0,
                  top: 0,
                  width: 300 + drawerEdgeWidth,
                  left: -(1 - animCtrl.value) * drawerWidth,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints.expand(),
                    child: GestureDetector(
                      onHorizontalDragStart: (details) {
                        dragStartDy = details.globalPosition.dy;
                        lastDragDx = details.globalPosition.dx;
                      },
                      onHorizontalDragUpdate: (details) {
                        final dragDistance =
                            lastDragDx - details.globalPosition.dx;
                        lastDragDx = details.globalPosition.dx;
                        final animChange = -dragDistance / drawerWidth;

                        if (animCtrl.isCompleted) {
                          curtainAnimCtrl.value -= animChange;
                          impactPointNotifier.value = details.localPosition.dy;
                        } else {
                          animCtrl.value += animChange;
                        }
                      },
                      onHorizontalDragEnd: (details) async {
                        if (animCtrl.isCompleted) {
                          if (curtainAnimCtrl.value > 0.5) {
                            await animCtrl.fling(velocity: -1);
                            curtainAnimCtrl.value = 0;
                          } else {
                            curtainAnimCtrl.value = 0;
                            // curtainAnimCtrl.fling(velocity: -1);
                          }
                        } else {
                          animCtrl.fling(
                            velocity: switch (details.primaryVelocity ?? 0) {
                              > 0.0 => 1.0,
                              _ => -1.0,
                            },
                          );
                        }
                      },
                      child: CurtainDrawer(
                        horizontalProgress: curtainAnimCtrl,
                        impactPointNotifier: impactPointNotifier,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget buildPage() {
    return Container(
      color: Colors.white,
      child: const Placeholder(
        color: Colors.black,
      ),
    );
  }
}

class CurtainDrawer extends StatelessWidget {
  const CurtainDrawer({
    required this.horizontalProgress,
    required this.impactPointNotifier,
    super.key,
  });

  final Animation<double> horizontalProgress;
  final ValueNotifier<double> impactPointNotifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(right: drawerEdgeWidth),
      child: ShaderBuilder(
        (context, shader, child) {
          return AnimatedBuilder(
            animation: Listenable.merge([
              horizontalProgress,
              impactPointNotifier,
            ]),
            // animation: horizontalProgress,
            builder: (context, child) {
              debugPrint('animating curtain: ${horizontalProgress.value}');
              return AnimatedSampler(
                (image, size, canvas) {
                  int i = 0;
                  shader
                    ..setFloat(i++, size.width)
                    ..setFloat(i++, size.height)
                    ..setFloat(i++, horizontalProgress.value)
                    ..setFloat(i++, impactPointNotifier.value / size.height)
                    ..setImageSampler(0, image);

                  canvas.drawRect(
                    Offset.zero & size,
                    Paint()..shader = shader,
                  );
                },
                child: buildContents(),
              );
            },
          );
        },
        assetKey: 'assets/shaders/curtain.frag',
      ),
    );
  }

  Widget buildContents() {
    return Container(
      color: Colors.blue,
      alignment: Alignment.center,
      child: Text(
        'shaders ' * 100,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
