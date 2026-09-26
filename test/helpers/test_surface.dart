import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Give a widget test a surface tall enough to lay out a whole screen at once.
///
/// The takeover screens are `ListView`s, and a `ListView` builds lazily: a
/// widget below the fold does not exist in the tree, so a finder reports zero
/// matches. On the default 800x600 test surface that is indistinguishable from
/// the widget being genuinely absent.
///
/// That difference matters. A `findsNothing` expectation passes either way, so
/// a test can keep passing while the thing it guards has silently stopped
/// rendering. This happened here: the incident screen's floor plan drew nothing
/// while the mock data described a facility whose rooms the active plan did not
/// contain, and every test still passed.
///
/// A tall surface makes the whole screen real, so presence and absence mean what
/// they say. Scrolling to each widget is the alternative, but it only fixes the
/// expectations someone remembered to scroll for.
void useTallSurface(
  WidgetTester tester, {
  Size size = const Size(1080, 3000),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Turn off animations so `pumpAndSettle` does not wait on them.
void disableAnimations(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}
