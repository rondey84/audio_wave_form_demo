import 'dart:math';
import 'package:flutter/material.dart';

enum WaveformAlignment { top, center, bottom }

class CustomAudioWaveformWidget extends StatefulWidget {
  final List<double> samples;
  final double height;
  final double width;
  final Color? activeColor;
  final Color? inactiveColor;
  final double borderWidth;
  final bool absolute;
  final bool invert;
  final bool isCentered;
  final Duration maxDuration;
  final Duration elapsedDuration;

  const CustomAudioWaveformWidget({
    Key? key,
    required this.samples,
    required this.height,
    required this.width,
    this.activeColor,
    this.inactiveColor,
    this.borderWidth = 1.0,
    this.absolute = false,
    this.invert = false,
    this.isCentered = false,
    required this.maxDuration,
    required this.elapsedDuration,
  })  : assert(
          borderWidth >= 0 && borderWidth <= 1.0,
          'BorderWidth must be between 0 and 1',
        ),
        waveformAlignment = absolute
            ? invert
                ? WaveformAlignment.top
                : WaveformAlignment.bottom
            : WaveformAlignment.center,
        super(key: key);

  @protected
  final WaveformAlignment waveformAlignment;

  @override
  CustomAudioWaveformState createState() => CustomAudioWaveformState();
}

class CustomAudioWaveformState extends State<CustomAudioWaveformWidget>
    with SingleTickerProviderStateMixin {
  List<double> processedSamples = [];
  double sampleWidth = 0;

  List<double> get samples => widget.samples;
  double get height => widget.height;
  double get width => widget.width;
  bool get isAbsolute => widget.absolute;
  bool get isInverted => widget.absolute ? !widget.invert : widget.invert;

  Color get activeColor => widget.activeColor ?? Colors.lightBlue;
  Color get inactiveColor => widget.inactiveColor ?? Colors.grey;

  late AnimationController controller;
  late Animation<Color?> animation1;
  late Animation<Color?> animation2;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    animation1 = ColorTween(
      begin: Colors.amber,
      end: Colors.green,
    ).animate(controller);

    animation2 = ColorTween(
      end: inactiveColor,
    ).animate(controller);

    controller.forward();

    controller.addListener(() {
      if (controller.status == AnimationStatus.completed) {
        controller.stop();
      } else if (controller.status == AnimationStatus.dismissed) {
        controller.forward();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (samples.isNotEmpty) {
      processedSamples = processSamples();
      calculateSampleWidth();
    }
    if (samples.isEmpty) {
      return SizedBox(
        height: height,
        width: width,
      );
    }
    return SizedBox(
      height: height,
      width: width,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: FractionalOffset.centerLeft,
            end: FractionalOffset.centerRight,
            colors: [
              activeColor,
              inactiveColor,
            ],
            stops: [
              widget.elapsedDuration.inMicroseconds /
                  widget.maxDuration.inMicroseconds,
              0
            ],
          ).createShader(bounds);
        },
        child: ClipPath(
          child: CustomPaint(
            size: Size(width, height),
            isComplex: true,
            painter: _CustomWaveFromPainter(
              samples: processedSamples,
              color: inactiveColor,
              waveformAlignment: widget.waveformAlignment,
              sampleWidth: sampleWidth,
              isCentered: widget.isCentered,
              borderWidth: widget.borderWidth,
            ),
          ),
        ),
      ),
    );
  }

  void calculateSampleWidth() {
    sampleWidth = width / (processedSamples.length);
  }

  List<double> processSamples() {
    final rawSamples = samples;

    var ps = rawSamples
        .map((e) => isAbsolute ? e.abs() * height : e * height)
        .toList();

    final maxNum = ps.reduce((a, b) => max(a.abs(), b.abs()));

    if (maxNum > 0) {
      final multiplier = pow(maxNum, -1).toDouble();
      final finalHeight = isAbsolute ? height : height / 2;
      final finalMultiplier = multiplier * finalHeight;

      return ps
          .map((e) => isInverted ? -e * finalMultiplier : e * finalMultiplier)
          .toList();
    }
    return ps;
  }
}

class _CustomWaveFromPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  final WaveformAlignment waveformAlignment;
  final double sampleWidth;
  final PaintingStyle style;
  final double borderWidth;
  final bool isCentered;

  _CustomWaveFromPainter({
    required this.samples,
    required this.color,
    required this.waveformAlignment,
    required this.sampleWidth,
    this.borderWidth = 0.0,
    required this.isCentered,
  }) : style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = style
      ..color = color;

    final alignPosition = waveformAlignment.getAlignPosition(size.height);
    final isAbsolute = waveformAlignment != WaveformAlignment.center;

    final isCenteredAndNotAbsolute = isCentered && !isAbsolute;

    for (var i = 0; i < samples.length; i++) {
      final x = sampleWidth * i - borderWidth;
      final y = isCenteredAndNotAbsolute ? samples[i] * 2 : samples[i];
      final positionFromTop =
          isCenteredAndNotAbsolute ? alignPosition - y / 2 : alignPosition;

      final rectangle =
          Rect.fromLTWH(x, positionFromTop, sampleWidth - borderWidth, y);

      //Draws the filled rectangles of the waveform.
      canvas.drawRect(
        rectangle,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CustomWaveFromPainter oldDelegate) {
    return true;
  }
}

extension WaveformAlignmentExtension on WaveformAlignment {
  ///Gets offset height based on waveform align
  double getAlignPosition(double height) {
    switch (this) {
      case WaveformAlignment.top:
        return 0;
      case WaveformAlignment.center:
        return height / 2;
      case WaveformAlignment.bottom:
        return height;
    }
  }
}
