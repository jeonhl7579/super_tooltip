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
    // verticalOffset 생략
    required this.overlaySize, // ← RenderBox 대신 Size
  });

  // ───────────────────────── stored data ─────────────────────────
  final bool snapsFarAwayVertically;
  final bool snapsFarAwayHorizontally;
  final double margin;
  final Offset target;
  final Size overlaySize; // ← 화면·오버레이 크기
  final BoxConstraints constraints;
  final TooltipDirection preferredDirection;
  final double? top, bottom, left, right;

  // ─────────────────────── constraints 계산 ──────────────────────
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    var newConstraints = constraints;

    switch (preferredDirection) {
      case TooltipDirection.up:
      case TooltipDirection.down:
        newConstraints = SuperUtils.verticalConstraints(
          constraints: newConstraints,
          margin: margin,
          bottom: bottom,
          isUp: preferredDirection == TooltipDirection.up,
          target: target,
          top: top,
          left: left,
          right: right,
        );
        break;
      case TooltipDirection.right:
      case TooltipDirection.left:
        newConstraints = SuperUtils.horizontalConstraints(
          constraints: newConstraints,
          margin: margin,
          bottom: bottom,
          isRight: preferredDirection == TooltipDirection.right,
          target: target,
          top: top,
          left: left,
          right: right,
        );
        break;
    }

    // NaN·∞ 안전값 치환 ────────────────────────────────
    double safeMaxW = newConstraints.maxWidth;
    double safeMaxH = newConstraints.maxHeight;

    if (!safeMaxW.isFinite || safeMaxW.isNaN) {
      safeMaxW = overlaySize.width - margin * 2;
    }
    if (!safeMaxH.isFinite || safeMaxH.isNaN) {
      safeMaxH = overlaySize.height - margin * 2;
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

  // ─────────────────────── 위치 계산 ─────────────────────────────
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double _finite(double v) => v.isFinite ? v : 0.0;
    double _clampX(double x) =>
        x.clamp(margin, overlaySize.width - childSize.width - margin);
    double _clampY(double y) =>
        y.clamp(margin, overlaySize.height - childSize.height - margin);

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
