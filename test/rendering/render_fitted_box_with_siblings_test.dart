import 'package:fitted_box_with_siblings/fitted_box_with_siblings.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('RenderFittedBoxWithSiblings handles applying paint transform and '
      'hit-testing with empty size', () {
    final fittedBox = RenderFittedBoxWithSiblings(
      computeRects: (constraints, boxSize) => [
        Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
      ],
      children: <RenderBox>[
        RenderCustomPaint(painter: TestCallbackPainter(onPaint: () {})),
      ],
    );

    layout(fittedBox, phase: EnginePhase.flushSemantics);
    final transform = Matrix4.identity();
    fittedBox.applyPaintTransform(fittedBox.firstChild!, transform);
    expect(transform, Matrix4.zero());

    final hitTestResult = BoxHitTestResult();
    expect(
      fittedBox.hitTestChildren(hitTestResult, position: Offset.zero),
      isFalse,
    );
  });

  test('RenderFittedBoxWithSiblings does not paint with empty sizes', () {
    bool painted;
    RenderFittedBoxWithSiblings makeFittedBox(Size size) {
      return RenderFittedBoxWithSiblings(
        computeRects: (constraints, boxSize) => [
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
        ],
        children: <RenderBox>[
          RenderCustomPaint(
            preferredSize: size,
            painter: TestCallbackPainter(
              onPaint: () {
                painted = true;
              },
            ),
          ),
        ],
      );
    }

    // The RenderFittedBoxWithSiblings paints if both its size and its child's
    // size are nonempty.
    painted = false;
    layout(makeFittedBox(const Size(1, 1)), phase: EnginePhase.paint);
    expect(painted, equals(true));

    // The RenderFittedBoxWithSiblings should not paint if its child is
    // empty-sized.
    painted = false;
    layout(makeFittedBox(Size.zero), phase: EnginePhase.paint);
    expect(painted, equals(false));

    // The RenderFittedBoxWithSiblings should not paint if it is empty.
    painted = false;
    layout(
      makeFittedBox(const Size(1, 1)),
      constraints: BoxConstraints.tight(Size.zero),
      phase: EnginePhase.paint,
    );
    expect(painted, equals(false));
  });

  void testFittedBoxWithClipRectLayer() {
    _testLayerReuse<ClipRectLayer>(
      RenderFittedBoxWithSiblings(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        computeRects: (constraints, boxSize) => [
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
        ],
        children: <RenderBox>[
          // Inject opacity under the clip to force compositing.
          RenderRepaintBoundary(
            child: RenderSizedBox(const Size(100.0, 200.0)),
          ),
        ], // size doesn't matter
      ),
    );
  }

  void testFittedBoxWithTransformLayer() {
    _testLayerReuse<TransformLayer>(
      RenderFittedBoxWithSiblings(
        fit: BoxFit.fill,
        computeRects: (constraints, boxSize) => [
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
        ],
        children: <RenderBox>[
          // Inject opacity under the clip to force compositing.
          RenderRepaintBoundary(child: RenderSizedBox(const Size(1, 1))),
        ], // size doesn't matter
      ),
    );
  }

  test(
    'RenderFittedBoxWithSiblings reuses ClipRectLayer',
    testFittedBoxWithClipRectLayer,
  );

  test(
    'RenderFittedBoxWithSiblings reuses TransformLayer',
    testFittedBoxWithTransformLayer,
  );

  test('RenderFittedBoxWithSiblings switches between ClipRectLayer and '
      'TransformLayer, and reuses them', () {
    testFittedBoxWithClipRectLayer();

    // clip -> transform
    testFittedBoxWithTransformLayer();
    // transform -> clip
    testFittedBoxWithClipRectLayer();
  });

  test('RenderFittedBoxWithSiblings respects clipBehavior', () {
    const viewport = BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    for (final clip in <Clip?>[null, ...Clip.values]) {
      final context = TestClipPaintingContext();
      final RenderFittedBoxWithSiblings box;
      switch (clip) {
        case Clip.none:
        case Clip.hardEdge:
        case Clip.antiAlias:
        case Clip.antiAliasWithSaveLayer:
          box = RenderFittedBoxWithSiblings(
            computeRects: (constraints, boxSize) => [
              Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
            ],
            children: <RenderBox>[box200x200],
            fit: BoxFit.none,
            clipBehavior: clip!,
          );
        case null:
          box = RenderFittedBoxWithSiblings(
            computeRects: (constraints, boxSize) => [
              Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
            ],
            children: <RenderBox>[box200x200],
            fit: BoxFit.none,
          );
      }
      layout(
        box,
        constraints: viewport,
        phase: EnginePhase.composite,
        onErrors: expectNoFlutterErrors,
      );
      box.paint(context, Offset.zero);
      // By default, clipBehavior should be Clip.none
      expect(context.clipBehavior, equals(clip ?? Clip.none));
    }
  });

  test(
    'RenderFittedBoxWithSiblings can layout with top, right, bottom, left 0.0',
    () {
      final RenderBox size = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );

      final RenderBox red = RenderDecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFFF0000)),
        child: size,
      );

      final RenderBox green = RenderDecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF00FF00)),
      );

      final RenderBox stack = RenderFittedBoxWithSiblings(
        computeRects: (constraints, boxSize) {
          return [
            const Rect.fromLTWH(0, 0, 100.0, 100.0),
            const Rect.fromLTWH(0, 0, 100.0, 100.0),
          ];
        },
        textDirection: TextDirection.ltr,
        children: <RenderBox>[red, green],
      );
      // green.parentData! as StackParentData
      //   ..top = 0.0
      //   ..right = 0.0
      //   ..bottom = 0.0
      //   ..left = 0.0;

      layout(stack, constraints: const BoxConstraints());

      expect(stack.size.width, equals(100.0));
      expect(stack.size.height, equals(100.0));

      expect(red.size.width, equals(100.0));
      expect(red.size.height, equals(100.0));

      expect(green.size.width, equals(100.0));
      expect(green.size.height, equals(100.0));
    },
  );

  test('RenderFittedBoxWithSiblings can layout with no children', () {
    final RenderBox stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[],
    );

    layout(stack, constraints: BoxConstraints.tight(const Size(100.0, 100.0)));

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));
  });

  test('RenderFittedBoxWithSiblings has correct clipBehavior', () {
    const viewport = BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);

    for (final clip in <Clip?>[null, ...Clip.values]) {
      final context = TestClipPaintingContext();
      final RenderBox child = box200x200;
      final RenderStack stack;
      switch (clip) {
        case Clip.none:
        case Clip.hardEdge:
        case Clip.antiAlias:
        case Clip.antiAliasWithSaveLayer:
          stack = RenderStack(
            textDirection: TextDirection.ltr,
            children: <RenderBox>[child],
            clipBehavior: clip!,
          );
        case null:
          stack = RenderStack(
            textDirection: TextDirection.ltr,
            children: <RenderBox>[child],
          );
      }
      {
        // Make sure that the child is positioned so the stack will consider it
        // as overflowed.
        final parentData = child.parentData! as StackParentData;
        parentData.left = parentData.right = 0;
      }
      layout(
        stack,
        constraints: viewport,
        phase: EnginePhase.composite,
        onErrors: expectNoFlutterErrors,
      );
      context.paintChild(stack, Offset.zero);
      // By default, clipBehavior should be Clip.hardEdge
      expect(
        context.clipBehavior,
        equals(clip ?? Clip.hardEdge),
        reason: 'for $clip',
      );
    }
  });

  test('RenderFittedBoxWithSiblings in Flex can layout with no children', () {
    // Render an empty Stack in a Flex
    final flex = RenderFlex(
      textDirection: TextDirection.ltr,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <RenderBox>[
        RenderStack(textDirection: TextDirection.ltr, children: <RenderBox>[]),
      ],
    );

    var stackFlutterErrorThrown = false;
    layout(
      flex,
      constraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      onErrors: () {
        stackFlutterErrorThrown = true;
      },
    );

    expect(stackFlutterErrorThrown, false);
  });

  // More tests in ../widgets/stack_test.dart
}

// Forces two frames and checks that:
// - a layer is created on the first frame
// - the layer is reused on the second frame
void _testLayerReuse<L extends Layer>(RenderBox renderObject) {
  expect(L, isNot(Layer));
  expect(renderObject.debugLayer, null);
  layout(
    renderObject,
    phase: EnginePhase.paint,
    constraints: BoxConstraints.tight(const Size(10, 10)),
  );
  final Layer? layer = renderObject.debugLayer;
  expect(layer, isA<L>());
  expect(layer, isNotNull);

  // Mark for repaint otherwise pumpFrame is a noop.
  renderObject.markNeedsPaint();
  expect(renderObject.debugNeedsPaint, true);
  pumpFrame(phase: EnginePhase.paint);
  expect(renderObject.debugNeedsPaint, false);
  expect(renderObject.debugLayer, same(layer));
}
