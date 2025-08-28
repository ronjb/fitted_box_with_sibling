import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Signature for a function that given the constraints and [boxSize] returns
/// the rects for the fitted box and its sibling.
typedef RectsForFittedBoxWithSibling =
    ({Rect boxRect, Rect siblingRect}) Function(BoxConstraints constraints, Size boxSize);

/// Scales and positions the first child (the "box") within itself according
/// to [fit], similar to [FittedBox]. The positioning of the box and the second
/// child is determined by [rectsForFittedBoxWithSibling], which is given the
/// overall constraints and the size returned by calling `layout` on the first
/// child (the "box").
///
/// See also:
///
/// * [FittedBox], which scales and positions its child within itself according
///   to [fit] and [alignment].
/// * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class FittedBoxWithSibling extends MultiChildRenderObjectWidget {
  const FittedBoxWithSibling({
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.textDirection,
    this.stackFit = StackFit.loose,
    this.clipBehavior = Clip.none,
    required this.rectsForFittedBoxWithSibling,
    super.children,
  });

  /// How to inscribe the first child into the space allocated during layout.
  final BoxFit fit;

  /// How to align the first child within the bounds alloted to it.
  ///
  /// An alignment of (-1.0, -1.0) aligns the child to the top-left corner of
  /// the bounds. An alignment of (1.0, 0.0) aligns the child to the middle
  /// of the right edge of the bounds.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// How to size the first child (i.e. the "box").
  ///
  /// The constraints passed into the [FittedBoxWithSibling] from its parent
  /// are either loosened ([StackFit.loose]) or tightened to their biggest size
  /// ([StackFit.expand]).
  final StackFit stackFit;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// A function that returns the rects for the fitted bix and its sibling.
  final RectsForFittedBoxWithSibling rectsForFittedBoxWithSibling;

  @override
  RenderFittedBoxWithSibling createRenderObject(BuildContext context) {
    assert(_debugCheckHasDirectionality(context));
    _checkHasTwoChildren();
    return RenderFittedBoxWithSibling(
      fit: fit,
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      stackFit: stackFit,
      clipBehavior: clipBehavior,
      rectsForFittedBoxWithSibling: rectsForFittedBoxWithSibling,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFittedBoxWithSibling renderObject) {
    assert(_debugCheckHasDirectionality(context));
    _checkHasTwoChildren();
    renderObject
      ..fit = fit
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..stackFit = stackFit
      ..clipBehavior = clipBehavior
      ..rectsForFittedBoxWithSibling = rectsForFittedBoxWithSibling;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<BoxFit>('fit', fit))
      ..add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null))
      ..add(EnumProperty<StackFit>('stackFit', stackFit))
      ..add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.hardEdge));
  }

  bool _debugCheckHasDirectionality(BuildContext context) {
    if (alignment is AlignmentDirectional && textDirection == null) {
      assert(
        debugCheckHasDirectionality(
          context,
          why: "to resolve the 'alignment' argument",
          hint: alignment == AlignmentDirectional.topStart
              ? "The default value for 'alignment' is AlignmentDirectional.topStart, which requires a text direction."
              : null,
          alternative:
              "Instead of providing a Directionality widget, another solution would be passing a non-directional 'alignment', or an explicit 'textDirection', to the $runtimeType.",
        ),
      );
    }
    return true;
  }

  bool _checkHasTwoChildren() {
    if (children.length != 2) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('FittedBoxWithSibling must have exactly two children.'),
        ErrorDescription(
          'The FittedBoxWithSibling widget is designed to have exactly two children: '
          'the first child is the box to be fitted, and the second child is the sibling '
          'whose position is determined by rectsForFittedBoxWithSibling.',
        ),
        ErrorHint('The number of children provided was ${children.length}.'),
      ]);
    }
    return true;
  }
}

/// The render object for [FittedBoxWithSibling].
class RenderFittedBoxWithSibling extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, StackParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  RenderFittedBoxWithSibling({
    List<RenderBox>? children,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = AlignmentDirectional.center,
    TextDirection? textDirection,
    StackFit stackFit = StackFit.loose,
    Clip clipBehavior = Clip.none,
    required RectsForFittedBoxWithSibling rectsForFittedBoxWithSibling,
  }) : _fit = fit,
       _alignment = alignment,
       _textDirection = textDirection,
       _stackFit = stackFit,
       _clipBehavior = clipBehavior,
       _rectForSibling = rectsForFittedBoxWithSibling {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData) {
      child.parentData = StackParentData();
    }
  }

  bool _fitAffectsLayout(BoxFit fit) {
    switch (fit) {
      case BoxFit.scaleDown:
        return true;
      case BoxFit.contain:
      case BoxFit.cover:
      case BoxFit.fill:
      case BoxFit.fitHeight:
      case BoxFit.fitWidth:
      case BoxFit.none:
        return false;
    }
  }

  /// How to inscribe the child into the space allocated during layout.
  BoxFit get fit => _fit;
  BoxFit _fit;
  set fit(BoxFit value) {
    if (_fit == value) {
      return;
    }
    final lastFit = _fit;
    _fit = value;
    if (_fitAffectsLayout(lastFit) || _fitAffectsLayout(value)) {
      markNeedsLayout();
    } else {
      _clearPaintData();
      markNeedsPaint();
    }
  }

  Alignment get _resolvedAlignment => _resolvedAlignmentCache ??= alignment.resolve(textDirection);
  Alignment? _resolvedAlignmentCache;

  bool? _hasVisualOverflow;
  Matrix4? _transform;

  void _markNeedResolution() {
    _resolvedAlignmentCache = null;
    markNeedsLayout();
  }

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    _markNeedResolution();
  }

  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  StackFit get stackFit => _stackFit;
  StackFit _stackFit;
  set stackFit(StackFit value) {
    if (_stackFit != value) {
      _stackFit = value;
      markNeedsLayout();
    }
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  void _clearPaintData() {
    _hasVisualOverflow = null;
    _transform = null;
  }

  void _updatePaintData() {
    if (_transform != null) {
      return;
    }

    if (firstChild == null) {
      _hasVisualOverflow = false;
      _transform = Matrix4.identity();
    } else {
      final Alignment resolvedAlignment = _resolvedAlignment;
      final Size childSize = firstChild!.size;
      final FittedSizes sizes = applyBoxFit(_fit, childSize, size);
      final double scaleX = sizes.destination.width / sizes.source.width;
      final double scaleY = sizes.destination.height / sizes.source.height;
      final Rect sourceRect = resolvedAlignment.inscribe(sizes.source, Offset.zero & childSize);
      final Rect destinationRect = resolvedAlignment.inscribe(
        sizes.destination,
        Offset.zero & size,
      );
      _hasVisualOverflow =
          sourceRect.width < childSize.width || sourceRect.height < childSize.height;
      assert(scaleX.isFinite && scaleY.isFinite);
      _transform = Matrix4.translationValues(destinationRect.left, destinationRect.top, 0.0)
        ..scaleByDouble(scaleX, scaleY, 1.0, 1)
        ..translateByDouble(-sourceRect.left, -sourceRect.top, 0, 1);
      assert(_transform!.storage.every((double value) => value.isFinite));
    }
  }

  RectsForFittedBoxWithSibling get rectsForFittedBoxWithSibling => _rectForSibling;
  RectsForFittedBoxWithSibling _rectForSibling;
  set rectsForFittedBoxWithSibling(RectsForFittedBoxWithSibling value) {
    if (_rectForSibling != value) {
      _rectForSibling = value;
      markNeedsLayout();
    }
  }

  static double getIntrinsicDimension(
    RenderBox? firstChild,
    double Function(RenderBox child) mainChildSizeGetter,
  ) {
    const extent = 0.0;
    // TODO(ron): ...
    /*  var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;
      if (!childParentData.isPositioned) {
        extent = math.max(extent, mainChildSizeGetter(child));
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    } */
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return getIntrinsicDimension(firstChild, (child) => child.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return getIntrinsicDimension(firstChild, (child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return getIntrinsicDimension(firstChild, (child) => child.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return getIntrinsicDimension(firstChild, (child) => child.getMaxIntrinsicHeight(width));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  static double? _baselineForChild(
    RenderBox child,
    Size stackSize,
    BoxConstraints nonPositionedChildConstraints,
    Alignment alignment,
    TextBaseline baseline,
  ) {
    final childParentData = child.parentData! as StackParentData;
    final childConstraints = childParentData.isPositioned
        ? childParentData.positionedChildConstraints(stackSize)
        : nonPositionedChildConstraints;
    final baselineOffset = child.getDryBaseline(childConstraints, baseline);
    if (baselineOffset == null) {
      return null;
    }
    final y = switch (childParentData) {
      StackParentData(:final double top?) => top,
      StackParentData(:final double bottom?) =>
        stackSize.height - bottom - child.getDryLayout(childConstraints).height,
      StackParentData() =>
        alignment.alongOffset(stackSize - child.getDryLayout(childConstraints) as Offset).dy,
    };
    return baselineOffset + y;
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    final nonPositionedChildConstraints = switch (stackFit) {
      StackFit.loose => constraints.loosen(),
      StackFit.expand => BoxConstraints.tight(constraints.biggest),
      StackFit.passthrough => constraints,
    };

    final alignment = _resolvedAlignment;
    final size = getDryLayout(constraints);

    var baselineOffset = BaselineOffset.noBaseline;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      baselineOffset = baselineOffset.minOf(
        BaselineOffset(
          _baselineForChild(child, size, nonPositionedChildConstraints, alignment, baseline),
        ),
      );
    }
    return baselineOffset.offset;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return _computeSize(constraints: constraints, layoutChild: ChildLayoutHelper.dryLayoutChild);
  }

  Size _computeSize({required BoxConstraints constraints, required ChildLayouter layoutChild}) {
    if (childCount == 0) {
      return constraints.biggest.isFinite ? constraints.biggest : constraints.smallest;
    }

    late Rect boxRect;
    late Rect siblingRect;

    final nonPositionedConstraints = switch (stackFit) {
      StackFit.loose => constraints.loosen(),
      StackFit.expand => BoxConstraints.tight(constraints.biggest),
      StackFit.passthrough => constraints,
    };

    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;

      if (childParentData.isPositioned) {
        throw UnimplementedError('Positioned children are not supported in FittedBoxWithSibling.');
      } else if (identical(child, firstChild)) {
        final childSize = layoutChild(child, const BoxConstraints());
        final result = rectsForFittedBoxWithSibling(nonPositionedConstraints, childSize);
        boxRect = result.boxRect;
        siblingRect = result.siblingRect;

        if (!boxRect.isFinite || !siblingRect.isFinite) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('The rects returned by rectsForFittedBoxWithSibling must be finite.'),
            ErrorDescription(
              'The rects returned were:\n'
              'boxRect: $boxRect\n'
              'siblingRect: $siblingRect\n'
              'The constraints passed to rectsForFittedBoxWithSibling were:\n'
              '$nonPositionedConstraints\n'
              'The size of the first child (the box) passed to rectsForFittedBoxWithSibling was:\n'
              '$childSize',
            ),
          ]);
        }
      } else {
        final siblingConstraints = stackFit == StackFit.loose
            ? BoxConstraints.loose(siblingRect.size)
            : BoxConstraints.tight(siblingRect.size);
        layoutChild(child, siblingConstraints);
        childParentData.offset = Offset(siblingRect.left, siblingRect.top);

        if (childParentData.nextSibling != null) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('FittedBoxWithSibling can only have two children.'),
            ErrorDescription(
              'The FittedBoxWithSibling widget is designed to have exactly two children: '
              'the first child is the box to be fitted, and the second child is the sibling.',
            ),
            ErrorHint('The number of children provided was greater than two.'),
          ]);
        }
      }

      child = childParentData.nextSibling;
    }

    final size = boxRect.expandToInclude(siblingRect).size;
    assert(size.isFinite);
    return size;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _hasVisualOverflow = false;

    size = _computeSize(constraints: constraints, layoutChild: ChildLayoutHelper.layoutChild);

    final resolvedAlignment = _resolvedAlignment;
    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;

      if (!childParentData.isPositioned) {
        childParentData.offset = resolvedAlignment.alongOffset(size - child.size as Offset);
      } else {
        throw UnimplementedError('Positioned children are not supported in FittedBoxWithSibling.');
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @protected
  void paintStack(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (clipBehavior != Clip.none && _hasVisualOverflow == true) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        paintStack,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      paintStack(context, offset);
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _hasVisualOverflow == true ? Offset.zero & size : null;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<BoxFit>('fit', fit))
      ..add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection))
      ..add(EnumProperty<StackFit>('stackFit', stackFit))
      ..add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.hardEdge));
  }
}
