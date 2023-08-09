import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'util.dart';

/// A polygon with a tag
class TaggedPolygon extends Polygon {
  /// The name of the polygon
  final String? tag;

  //final List<Offset> _offsets = [];

  TaggedPolygon({
    required super.points,
    super.holePointsList,
    super.color = const Color(0xFF00FF00),
    super.borderStrokeWidth = 0.0,
    super.borderColor = const Color(0xFFFFFF00),
    super.disableHolesBorder = false,
    super.isDotted = false,
    super.isFilled = false,
    super.strokeCap = StrokeCap.round,
    super.strokeJoin = StrokeJoin.round,
    super.label,
    super.labelStyle = const TextStyle(),
    super.labelPlacement = PolygonLabelPlacement.centroid,
    super.rotateLabel = false,
    this.tag,
  });
}

class TappablePolygonLayer extends PolygonLayer {
  /// The list of [TaggedPolygon] which could be tapped
  @override
  final List<TaggedPolygon> polygons;

  /// The tolerated distance between pointer and user tap to trigger the [onTap] callback
  final double pointerDistanceTolerance;

  /// The callback to call when a polygon was hit by the tap
  final void Function(List<TaggedPolygon>, TapUpDetails tapPosition)? onTap;

  /// The optional callback to call when no polygon was hit by the tap
  final void Function(TapUpDetails tapPosition)? onMiss;

  TappablePolygonLayer({
    this.polygons = const [],
    this.onTap,
    this.onMiss,
    this.pointerDistanceTolerance = 15,
    super.polygonCulling = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final map = FlutterMapState.of(context);
    final size = Size(map.size.x, map.size.y);

    return _build(
      context,
      size,
      polygonCulling
          ? polygons
              .where((p) => p.boundingBox.isOverlapping(map.bounds))
              .toList()
          : polygons,
    );
  }

  Widget _build(BuildContext context, Size size, List<TaggedPolygon> pgons) {
    FlutterMapState mapState = FlutterMapState.maybeOf(context)!;

    return Container(
      // TODO: Need this here?
      child: GestureDetector(
        onDoubleTap: () {
          // For some strange reason i have to add this callback for the onDoubleTapDown callback to be called.
        },
        onDoubleTapDown: (TapDownDetails details) {
          _zoomMap(details, context, mapState);
        },
        onTap: () {
          debugPrint("OnTap");
          // debugPrint("Doing something,");
          // _forwardCallToMapOptions(details, context, mapState);
          // var tap = details.localPosition;
          // LatLng tapLatLng = _offsetToCrs(tap, mapState);
          // _handlePolygonTap(tapLatLng, onTap, onMiss);
        },
        onTapUp: (TapUpDetails details) {
          debugPrint("OnTapUp Doing something,");
          _forwardCallToMapOptions(details, context, mapState);
          var tap = details.localPosition;
          LatLng tapLatLng = _offsetToCrs(tap, mapState);
          _handlePolygonTap(tapLatLng, onTap, onMiss);
        },
        child: Stack(
          //TODO: Need Stack here?
          children: [
            CustomPaint(
              painter: PolygonPainter(pgons, mapState),
              size: size,
            ),
          ],
        ),
      ),
    );
  }

  bool pointInPolygon(LatLng pt, List<LatLng> poly) {
    final ptList =
        poly.map((e) => Point(x: e.longitude, y: e.latitude)).toList();
    return Poly.isPointInPolygon(
        Point(x: pt.longitude, y: pt.latitude), ptList);
  }

  void _handlePolygonTap(LatLng ptLatLng, Function? onTap, Function? onMiss) {
    // We might hit close to multiple polygons. We will therefore keep a reference to these in this map.
    List<TaggedPolygon> candidates = [];

    for (TaggedPolygon currentPolygon in polygons) {
      if (pointInPolygon(ptLatLng, currentPolygon.points)) {
        candidates.add(currentPolygon);
      }
    }

    if (candidates.isEmpty) onMiss?.call(ptLatLng);

    onTap!(candidates, ptLatLng);
  }

  void _forwardCallToMapOptions(
      TapUpDetails details, BuildContext context, FlutterMapState mapState) {
    final latlng = _offsetToLatLng(details.localPosition, context.size!.width,
        context.size!.height, mapState);

    final tapPosition =
        TapPosition(details.globalPosition, details.localPosition);

    // Forward the onTap call to map.options so that we won't break onTap
    mapState.options.onTap?.call(tapPosition, latlng);
  }

  void _zoomMap(
      TapDownDetails details, BuildContext context, FlutterMapState mapState) {
    var newCenter = _offsetToLatLng(details.localPosition, context.size!.width,
        context.size!.height, mapState);
    mapState.move(newCenter, mapState.zoom + 0.5,
        source: MapEventSource.doubleTap);
  }

  LatLng _offsetToLatLng(
      Offset offset, double width, double height, FlutterMapState mapState) {
    var localPoint = CustomPoint(offset.dx, offset.dy);
    var localPointCenterDistance =
        CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = mapState.project(mapState.center);
    var point = mapCenter - localPointCenterDistance;
    return mapState.unproject(point);
  }

  CustomPoint<double> _offsetToPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }

  LatLng _offsetToCrs(Offset offset, FlutterMapState mapState, [double? zoom]) {
    final focalStartPt =
        mapState.project(mapState.center, zoom ?? mapState.zoom);
    final point = (_offsetToPoint(offset) - (mapState.nonrotatedSize / 2.0))
        .rotate(mapState.rotationRad);

    final newCenterPt = focalStartPt + point;
    return mapState.unproject(newCenterPt, zoom ?? mapState.zoom);
  }
}
