import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:brain_game/utils/breakpoints.dart';
import 'package:brain_game/utils/game_assets.dart';

class AlarmClock extends StatefulWidget {
  const AlarmClock({
    Key? key,
    required this.width,
  }) : super(key: key);

  final double width;

  @override
  State<AlarmClock> createState() => AlarmClockState();
}

class AlarmClockState extends State<AlarmClock>
    with SingleTickerProviderStateMixin {
  late final Rx<int> _seconds;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _seconds = 0.obs;

    startClock();
  }

  @override
  void dispose() {
    _timer?.cancel();

    // Stop ticking sound when widget is destroyed.
    GameAssets.stopClockTicking();

    super.dispose();
  }

  // ============================================================
  // CANCEL CLOCK
  // ============================================================

  void cancelClock() {
    _timer?.cancel();

    _seconds.value = 0;

    // Stop ticking sound.
    GameAssets.stopClockTicking();
  }

  // ============================================================
  // START CLOCK
  // ============================================================

  void startClock() {
    // Prevent multiple timers from running simultaneously.
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) async {
        _seconds.value += 1;

        // Play clock ticking sound.
        //
        // On Windows this uses just_audio.
        // On Android/iOS this uses Soundpool.
        await GameAssets.playClockTicking();

        if (_seconds.value > 60) {
          _seconds.value = _seconds.value % 60;
        }
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: (widget.width >= Preakpoints.md)
          ? 0.23 * widget.width
          : 0.16 * widget.width,
      bottom: (widget.width >= Preakpoints.md)
          ? 0.4 * widget.width
          : 0.43 * widget.width,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 25,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ==================================================
            // ALARM CLOCK IMAGE
            // ==================================================

            SvgPicture.asset(
              GameAssets.alarm,
              width: (widget.width >= Preakpoints.md)
                  ? 0.08 * widget.width
                  : 0.1 * widget.width,
            ),

            // ==================================================
            // SECONDS HAND
            // ==================================================

            ObxValue<Rx<int>>(
              (newValue) {
                return Transform(
                  transform: Matrix4.identity()
                    ..rotateZ(
                      -pi / 2 + ((2 * newValue.value) * 5) / 60,
                    ),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    painter: SecondsHandPainter(),
                    size: Size(
                      (widget.width >= Preakpoints.md)
                          ? 0.08 * widget.width
                          : 0.1 * widget.width,
                      (widget.width >= Preakpoints.md)
                          ? 0.08 * widget.width
                          : 0.1 * widget.width,
                    ),
                  ),
                );
              },
              _seconds,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SECONDS HAND PAINTER
// ================================================================

class SecondsHandPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill
      ..strokeWidth = size.width / 30;

    final Offset startPoint = Offset(
      size.width / 2,
      size.height / 2,
    );

    final Offset endPoint = Offset(
      size.width - size.width * 0.24,
      size.height / 2,
    );

    canvas.drawLine(
      startPoint,
      endPoint,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return true;
  }
}
