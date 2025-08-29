import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test(
    'RenderFittedBox handles applying paint transform and hit-testing with empty size',
    () {
      final fittedBox = RenderFittedBox(
        child: RenderCustomPaint(painter: TestCallbackPainter(onPaint: () {})),
      );

      layout(fittedBox, phase: EnginePhase.flushSemantics);
      final transform = Matrix4.identity();
      fittedBox.applyPaintTransform(fittedBox.child!, transform);
      expect(transform, Matrix4.zero());

      final hitTestResult = BoxHitTestResult();
      expect(
        fittedBox.hitTestChildren(hitTestResult, position: Offset.zero),
        isFalse,
      );
    },
  );

  test('RenderFittedBox does not paint with empty sizes', () {
    bool painted;
    RenderFittedBox makeFittedBox(Size size) {
      return RenderFittedBox(
        child: RenderCustomPaint(
          preferredSize: size,
          painter: TestCallbackPainter(
            onPaint: () {
              painted = true;
            },
          ),
        ),
      );
    }

    // The RenderFittedBox paints if both its size and its child's size are nonempty.
    painted = false;
    layout(makeFittedBox(const Size(1, 1)), phase: EnginePhase.paint);
    expect(painted, equals(true));

    // The RenderFittedBox should not paint if its child is empty-sized.
    painted = false;
    layout(makeFittedBox(Size.zero), phase: EnginePhase.paint);
    expect(painted, equals(false));

    // The RenderFittedBox should not paint if it is empty.
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
      RenderFittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        // Inject opacity under the clip to force compositing.
        child: RenderRepaintBoundary(
          child: RenderSizedBox(const Size(100.0, 200.0)),
        ), // size doesn't matter
      ),
    );
  }

  void testFittedBoxWithTransformLayer() {
    _testLayerReuse<TransformLayer>(
      RenderFittedBox(
        fit: BoxFit.fill,
        // Inject opacity under the clip to force compositing.
        child: RenderRepaintBoundary(
          child: RenderSizedBox(const Size(1, 1)),
        ), // size doesn't matter
      ),
    );
  }

  test('RenderFittedBox reuses ClipRectLayer', testFittedBoxWithClipRectLayer);

  test(
    'RenderFittedBox reuses TransformLayer',
    testFittedBoxWithTransformLayer,
  );

  test(
    'RenderFittedBox switches between ClipRectLayer and TransformLayer, and reuses them',
    () {
      testFittedBoxWithClipRectLayer();

      // clip -> transform
      testFittedBoxWithTransformLayer();
      // transform -> clip
      testFittedBoxWithClipRectLayer();
    },
  );

  test('RenderFittedBox respects clipBehavior', () {
    const viewport = BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    for (final clip in <Clip?>[null, ...Clip.values]) {
      final context = TestClipPaintingContext();
      final RenderFittedBox box;
      switch (clip) {
        case Clip.none:
        case Clip.hardEdge:
        case Clip.antiAlias:
        case Clip.antiAliasWithSaveLayer:
          box = RenderFittedBox(
            child: box200x200,
            fit: BoxFit.none,
            clipBehavior: clip!,
          );
        case null:
          box = RenderFittedBox(child: box200x200, fit: BoxFit.none);
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

  test('Stack can layout with top, right, bottom, left 0.0', () {
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

    final RenderBox stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[red, green],
    );
    green.parentData! as StackParentData
      ..top = 0.0
      ..right = 0.0
      ..bottom = 0.0
      ..left = 0.0;

    layout(stack, constraints: const BoxConstraints());

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));

    expect(red.size.width, equals(100.0));
    expect(red.size.height, equals(100.0));

    expect(green.size.width, equals(100.0));
    expect(green.size.height, equals(100.0));
  });

  test('Stack can layout with no children', () {
    final RenderBox stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[],
    );

    layout(stack, constraints: BoxConstraints.tight(const Size(100.0, 100.0)));

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));
  });

  test('Stack has correct clipBehavior', () {
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
        // Make sure that the child is positioned so the stack will consider it as overflowed.
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

  group('RenderIndexedStack', () {
    test('visitChildrenForSemantics only visits displayed child', () {
      final RenderBox child1 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox child2 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox child3 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox stack = RenderIndexedStack(
        index: 1,
        textDirection: TextDirection.ltr,
        children: <RenderBox>[child1, child2, child3],
      );

      final visitedChildren = <RenderObject>[];
      void visitor(RenderObject child) {
        visitedChildren.add(child);
      }

      layout(stack);
      stack.visitChildrenForSemantics(visitor);

      expect(visitedChildren, hasLength(1));
      expect(visitedChildren.first, child2);
    });

    test('debugDescribeChildren marks invisible children as offstage', () {
      final RenderBox child1 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox child2 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox child3 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );

      final RenderBox stack = RenderIndexedStack(
        index: 2,
        children: <RenderBox>[child1, child2, child3],
      );

      final diagnosticNodes = stack.debugDescribeChildren();

      expect(diagnosticNodes[0].name, 'child 1');
      expect(diagnosticNodes[0].style, DiagnosticsTreeStyle.offstage);

      expect(diagnosticNodes[1].name, 'child 2');
      expect(diagnosticNodes[1].style, DiagnosticsTreeStyle.offstage);

      expect(diagnosticNodes[2].name, 'child 3');
      expect(diagnosticNodes[2].style, DiagnosticsTreeStyle.sparse);
    });

    test('debugDescribeChildren handles a null index', () {
      final RenderBox child1 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox child2 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );
      final RenderBox child3 = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );

      final RenderBox stack = RenderIndexedStack(
        index: null,
        children: <RenderBox>[child1, child2, child3],
      );

      final diagnosticNodes = stack.debugDescribeChildren();

      expect(diagnosticNodes[0].name, 'child 1');
      expect(diagnosticNodes[0].style, DiagnosticsTreeStyle.offstage);

      expect(diagnosticNodes[1].name, 'child 2');
      expect(diagnosticNodes[1].style, DiagnosticsTreeStyle.offstage);

      expect(diagnosticNodes[2].name, 'child 3');
      expect(diagnosticNodes[2].style, DiagnosticsTreeStyle.offstage);
    });
  });

  test('Stack in Flex can layout with no children', () {
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
