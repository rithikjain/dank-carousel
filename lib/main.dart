import 'dart:math';

import 'package:dank_carousel/utils.dart';
import 'package:flutter/material.dart';
import 'package:indexed/indexed.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: DankCarousel(),
        ),
      ),
    );
  }
}

class DankCarousel extends StatefulWidget {
  const DankCarousel({super.key});

  @override
  State<DankCarousel> createState() => _DankCarouselState();
}

class _DankCarouselState extends State<DankCarousel> {
  final _circleRadius = 100.0;
  final _imageUrlList = <String>[];
  final _itemCount = 18;

  late VideoPlayerController _controller;

  double _dx = 0;
  double _dy = 0;

  @override
  void initState() {
    super.initState();

    // generate random images for all the cards
    for (int i = 0; i < _itemCount; i++) {
      _imageUrlList.add("https://picsum.photos/seed/${Random().nextInt(100000)}/120/150");
    }

    _controller = VideoPlayerController.asset('assets/bg.mp4');

    _controller.setLooping(true);
    _controller.initialize();
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// compute x translation according to the progress: 0.0 - 1.0
  double getX(double progress) {
    if (progress <= 0.25) {
      return normalisedLerp(begin: 0, end: -_circleRadius, tEnd: 0.25, t: progress);
    } else if (progress > 0.25 && progress <= 0.75) {
      return normalisedLerp(begin: -_circleRadius, end: _circleRadius, tBegin: 0.25, tEnd: 0.75, t: progress);
    } else {
      return normalisedLerp(begin: _circleRadius, end: 0, tBegin: 0.75, tEnd: 1, t: progress);
    }
  }

  /// compute z translation according to the progress: 0.0 - 1.0
  double getZ(double progress) {
    if (progress < 0.5) {
      return normalisedLerp(begin: 0, end: 2 * _circleRadius, tEnd: 0.5, t: progress);
    } else {
      return normalisedLerp(begin: 2 * _circleRadius, end: 0, tBegin: 0.5, tEnd: 1, t: progress);
    }
  }

  /// compute y rotation according to the progress: 0.0 - 1.0
  double getYRotation(double progress) {
    if (progress <= 0.25) {
      return normalisedLerp(begin: pi / 2, end: pi, tEnd: 0.25, t: progress, curve: Curves.linear);
    } else if (progress > 0.25 && progress <= 0.5) {
      return normalisedLerp(begin: pi, end: 3 * pi / 2, tBegin: 0.25, tEnd: 0.5, t: progress, curve: Curves.linear);
    } else if (progress > 0.5 && progress <= 0.75) {
      return normalisedLerp(begin: 3 * pi / 2, end: 2 * pi, tBegin: 0.5, tEnd: 0.75, t: progress, curve: Curves.linear);
    } else {
      return normalisedLerp(begin: 2 * pi, end: 5 * pi / 2, tBegin: 0.75, tEnd: 1, t: progress, curve: Curves.linear);
    }
  }

  /// returns the stack index of the items according to how they appear in the z axis
  int getStackIndex(double progress) {
    if (progress > 0.5) {
      return (progress * 1000000).toInt();
    } else {
      return ((1 - progress) * 1000000).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // gradient video
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.black.withOpacity(0.99), Colors.black.withOpacity(0.6)],
                    stops: const [0, 0.2, 0.6],
                    transform: const GradientRotation(pi / 2),
                  ),
                ),
              ),
            ],
          ),
        ),

        // carousel
        GestureDetector(
          onPanUpdate: (details) {
            final dy = _dy + details.delta.dy * 4;
            setState(() {
              _dx -= details.delta.dx / 600;
              if (dy < 300 && dy > -300) {
                _dy = dy;
              }
            });
          },
          child: Container(
            alignment: Alignment.center,
            width: 500,
            height: 300,
            color: Colors.transparent,
            child: Transform.translate(
              offset: Offset(120 / 2, -_dy),
              child: Indexer(
                children: List.generate(_itemCount, (index) {
                  final initialOffset = ((1 / _itemCount) * index) + 0.001;

                  final offset = (initialOffset + _dx);

                  // the progress will always go from 0.0 - 1.0
                  double progress;
                  if (offset > 0) {
                    progress = offset - offset.truncate();
                  } else {
                    final abs = offset.abs();
                    progress = 1 - (abs - abs.truncate());
                  }

                  final stackIndex = getStackIndex(progress);

                  return Indexed(
                    index: stackIndex,
                    child: Container(
                      transformAlignment: Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015) // gives perspective to the transforms
                        ..translate(getX(progress), _dy, getZ(progress))
                        ..rotateY(getYRotation(progress)),
                      height: 150,
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _imageUrlList[index],
                          key: ObjectKey(index),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        const Positioned(
          left: 24,
          top: 40,
          child: Text(
            "The\nDank\nCarousel.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        const Positioned(
          right: 24,
          bottom: 20,
          child: Text(
            "Rithik Jain",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.05,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
