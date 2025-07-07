import 'package:flutter/material.dart';

import 'enums.dart';
import 'utils.dart';

class TooltipPositionDelegate extends SingleChildLayoutDelegate {
  TooltipPositionDelegate({
    required this.snapsFarAwayVertically,
    required this.snapsFarAwayHorizontally,
    required this.preferredDirection,
    required this.constraints,
    required this.margin,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.target,
    // @required this.verticalOffset,
    required this.overlay,
  });
  // assert(verticalOffset != null);

  final bool snapsFarAwayVertically;
  final bool snapsFarAwayHorizontally;
  // TD: Make this EdgeInsets
  final double margin;
  final Offset target;
  // final double verticalOffset;
  final RenderBox? overlay;
  final BoxConstraints constraints;

  final TooltipDirection preferredDirection;
  final double? top, bottom, left, right;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    var newConstraints = constraints;

    // … (verticalConstraints / horizontalConstraints 계산 부분 그대로)

    // ───── NaN·Infinite 안전값 치환 ─────
    double safeMaxW = newConstraints.maxWidth;
    double safeMaxH = newConstraints.maxHeight;

    // overlay는 null일 수도 있으므로 화면 크기를 fallback 으로 사용
    Size screen = overlay?.size ??
        MediaQueryData.fromView(WidgetsBinding.instance.window).size;

    if (!safeMaxW.isFinite || safeMaxW.isNaN) {
      safeMaxW = screen.width - margin * 2; // 좌우 여백 보전
    }
    if (!safeMaxH.isFinite || safeMaxH.isNaN) {
      safeMaxH = screen.height - margin * 2; // 상하 여백 보전
    }

    final minW = newConstraints.minWidth;
    final minH = newConstraints.minHeight;

    return BoxConstraints(
      minWidth: minW > safeMaxW ? safeMaxW : minW,
      maxWidth: safeMaxW,
      minHeight: minH > safeMaxH ? safeMaxH : minH,
      maxHeight: safeMaxH,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double _finite(double v) => v.isFinite ? v : 0.0;
    double _clampX(double x) =>
        x.clamp(margin, size.width - childSize.width - margin);
    double _clampY(double y) =>
        y.clamp(margin, size.height - childSize.height - margin);

    switch (preferredDirection) {
      case TooltipDirection.up:
      case TooltipDirection.down:
        final rawTop = preferredDirection == TooltipDirection.up
            ? (top ?? target.dy - childSize.height)
            : target.dy;

        final rawLeft = SuperUtils.leftMostXtoTarget(
          childSize: childSize,
          left: left,
          margin: margin,
          right: right,
          size: size,
          target: target,
        );

        return Offset(
          _clampX(_finite(rawLeft)),
          _clampY(_finite(rawTop)),
        );

      case TooltipDirection.left:
      case TooltipDirection.right:
        final rawLeft = preferredDirection == TooltipDirection.left
            ? (left ?? target.dx - childSize.width)
            : target.dx;

        final rawTop = SuperUtils.topMostYtoTarget(
          bottom: bottom,
          childSize: childSize,
          margin: margin,
          size: size,
          target: target,
          top: top,
        );

        return Offset(
          _clampX(_finite(rawLeft)),
          _clampY(_finite(rawTop)),
        );

      default:
        throw ArgumentError(preferredDirection);
    }
  }

  @override
  bool shouldRelayout(TooltipPositionDelegate oldDelegate) => true;
}
