import 'dart:math';
import 'package:flutter/material.dart';

class PieChartWidget extends StatefulWidget {
  final double income;
  final double outlay;
  final List<Color> colors;
  final double size;

  const PieChartWidget({
    Key? key,
    required this.income,
    required this.outlay,
    required this.colors,
    this.size = 200,
  }) : super(key: key);

  @override
  _PieChartWidgetState createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool firstBuild = true; // 判斷是否第一次開場
  double oldIncome = 0;
  double oldOutlay = 0;

  late Tween<double> _incomeTween;
  late Tween<double> _outlayTween;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // 初始 Tween 從 0 → widget.income/outlay
    _incomeTween = Tween(begin: 0, end: widget.income);
    _outlayTween = Tween(begin: 0, end: widget.outlay);

    // 延遲一幀再觸發動畫，保證 build 完父 widget數值
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (firstBuild) {
        _controller.forward(from: 0).whenComplete(() {
          firstBuild = false; // 開場動畫完成
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant PieChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.income != widget.income || oldWidget.outlay != widget.outlay) {
      _incomeTween = Tween(begin: oldWidget.income, end: widget.income);
      _outlayTween = Tween(begin: oldWidget.outlay, end: widget.outlay);

      if (firstBuild) {
        // 開場動畫已由 initState 啟動，不重置
      } else {
        // 非開場更新，直接從當前值動畫到新值
        _controller.forward(from: 0);
      }

      oldIncome = widget.income;
      oldOutlay = widget.outlay;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentIncome = _incomeTween.evaluate(_animation);
        final currentOutlay = _outlayTween.evaluate(_animation);

        // 如果是第一次開場動畫，才套用 animationProgress
        final progress = firstBuild ? _animation.value : 1.0;

        return Container(
          width: widget.size,
          height: widget.size,
          color: Colors.transparent,   // ← 強制外框透明
          child: CustomPaint(
            painter: _PieChartPainter(
              income: currentIncome,
              outlay: currentOutlay,
              colors: widget.colors,
              animationProgress: progress,
            ),
          ),
        );

      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final double income;
  final double outlay;
  final List<Color> colors;
  final double animationProgress;

  _PieChartPainter({
    required this.income,
    required this.outlay,
    required this.colors,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = income + outlay;
    final radius = size.width / 2;
    final center = size.center(Offset.zero);
    final donutRadius = size.width / 4;

    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: donutRadius));

    // 真正的甜甜圈：外面 - 裡面
    final donutPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    if (total <= 0) {
      final fullPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.fill;

      canvas.drawPath(donutPath, fullPaint);
    } else {
      double startAngle = -pi / 2;

      final sweepIncome = (income / total) * 2 * pi * animationProgress;
      final sweepOutlay = (outlay / total) * 2 * pi * animationProgress;

      final paint = Paint()..style = PaintingStyle.stroke
        ..strokeWidth = radius - donutRadius; // ← 環的厚度

      // 支出
      paint.color = colors[1];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + donutRadius) / 2),
        startAngle,
        sweepOutlay,
        false,
        paint,
      );

      // 收入
      paint.color = colors[0];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + donutRadius) / 2),
        startAngle + sweepOutlay,
        sweepIncome,
        false,
        paint,
      );
    }

    // 中央文字（透明區域上）
    final animatedBalance = ((income - outlay) * animationProgress).toInt();

    final textSpan = TextSpan(
      text: "結餘:\n$animatedBalance",
      style: TextStyle(
        color: Colors.black,
        fontSize: donutRadius / 2.5,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool hitTest(Offset position) => false;
}
