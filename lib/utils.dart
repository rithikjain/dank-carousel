import 'package:flutter/material.dart';

/// will linearly interpolate the values between [begin] and [end]
/// considering the beginning and ending range of [t]
double normalisedLerp({
  required double begin,
  required double end,
  double tBegin = 0,
  double tEnd = 1,
  required double t,
  Curve curve = Curves.linear,
}) {
  // will give a value between 0 to 1 of t
  final normalisedT = curve.transform((t - tBegin) / (tEnd - tBegin));
  return begin * (1.0 - normalisedT) + end * normalisedT;
}
