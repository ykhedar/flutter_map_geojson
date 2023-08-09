import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'tappable_polygon.dart';
import 'tappable_polyline.dart';

typedef MarkerCreationCallback = Marker Function(
    LatLng point, Map<String, dynamic> properties);
typedef TaggedPolylineCreationCallback = TaggedPolyline Function(
    List<LatLng> points, Map<String, dynamic> properties);
typedef TaggedPolygonCreationCallback = TaggedPolygon Function(
    List<LatLng> points,
    List<List<LatLng>>? holePointsList,
    Map<String, dynamic> properties);

/// GeoJsonParser parses the GeoJson and fills three lists of parsed objects
/// which are defined in flutter_map package
/// - list of [Marker]s
/// - list of [TaggedPolyline]s
/// - list of [TaggedPolygon]s
///
/// One should pass these lists when creating adequate layers in flutter_map.
/// For details see example.
///
/// Currently GeoJson parser supports only FeatureCollection and not GeometryCollection.
/// See the GeoJson Format specification at: https://www.rfc-editor.org/rfc/rfc7946
///
/// For creation of [Marker], [TaggedPolyline] and [TaggedPolygon] objects the default callback functions
/// are provided which are used in case when no user-defined callback function is provided.
/// To fully customize the  [Marker], [TaggedPolyline] and [TaggedPolygon] creation one has to write his own
/// callback functions. As a template the default callback functions can be used.
///
class GeoJsonParser {
  /// list of [Marker] objects created as result of parsing
  final List<Marker> markers = [];

  /// list of [TaggedPolyline] objects created as result of parsing
  final List<TaggedPolyline> polylines = [];

  /// list of [TaggedPolygon] objects created as result of parsing
  final List<TaggedPolygon> polygons = [];

  /// user defined callback function that creates a [Marker] object
  MarkerCreationCallback? markerCreationCallback;

  /// user defined callback function that creates a [TaggedPolyline] object
  TaggedPolylineCreationCallback? polyLineCreationCallback;

  /// user defined callback function that creates a [TaggedPolygon] object
  TaggedPolygonCreationCallback? polygonCreationCallback;

  /// default [Marker] color
  Color? defaultMarkerColor;

  /// default [Marker] icon
  IconData? defaultMarkerIcon;

  /// default [TaggedPolyline] color
  Color? defaultTaggedPolylineColor;

  /// default [TaggedPolyline] stroke
  double? defaultTaggedPolylineStroke;

  /// default [TaggedPolygon] border color
  Color? defaultTaggedPolygonBorderColor;

  /// default [TaggedPolygon] fill color
  Color? defaultTaggedPolygonFillColor;

  /// default [TaggedPolygon] border stroke
  double? defaultTaggedPolygonBorderStroke;

  /// default flag if [TaggedPolygon] is filled (default is true)
  bool? defaultTaggedPolygonIsFilled;

  /// user defined callback function called when the [Marker] is tapped
  void Function(Map<String, dynamic>)? onMarkerTapCallback;

  /// default constructor - all parameters are optional and can be set later with setters
  GeoJsonParser(
      {this.markerCreationCallback,
      this.polyLineCreationCallback,
      this.polygonCreationCallback,
      this.defaultMarkerColor,
      this.defaultMarkerIcon,
      this.onMarkerTapCallback,
      this.defaultTaggedPolylineColor,
      this.defaultTaggedPolylineStroke,
      this.defaultTaggedPolygonBorderColor,
      this.defaultTaggedPolygonFillColor,
      this.defaultTaggedPolygonBorderStroke,
      this.defaultTaggedPolygonIsFilled});

  /// parse GeJson in [String] format
  void parseGeoJsonAsString(String g) {
    return parseGeoJson(jsonDecode(g) as Map<String, dynamic>);
  }

  /// set default [Marker] color
  set setDefaultMarkerColor(Color color) {
    defaultMarkerColor = color;
  }

  /// set default [Marker] icon
  set setDefaultMarkerIcon(IconData ic) {
    defaultMarkerIcon = ic;
  }

  /// set default [Marker] tap callback function
  void setDefaultMarkerTapCallback(
      Function(Map<String, dynamic> f) onTapFunction) {
    onMarkerTapCallback = onTapFunction;
  }

  /// set default [TaggedPolyline] color
  set setDefaultTaggedPolylineColor(Color color) {
    defaultTaggedPolylineColor = color;
  }

  /// set default [TaggedPolyline] stroke
  set setDefaultTaggedPolylineStroke(double stroke) {
    defaultTaggedPolylineStroke = stroke;
  }

  /// set default [TaggedPolygon] fill color
  set setDefaultTaggedPolygonFillColor(Color color) {
    defaultTaggedPolygonFillColor = color;
  }

  /// set default [TaggedPolygon] border stroke
  set setDefaultTaggedPolygonBorderStroke(double stroke) {
    defaultTaggedPolygonBorderStroke = stroke;
  }

  /// set default [TaggedPolygon] border color
  set setDefaultTaggedPolygonBorderColorStroke(Color color) {
    defaultTaggedPolygonBorderColor = color;
  }

  /// set default [TaggedPolygon] setting whether polygon is filled
  set setDefaultTaggedPolygonIsFilled(bool filled) {
    defaultTaggedPolygonIsFilled = filled;
  }

  /// main GeoJson parsing function
  void parseGeoJson(Map<String, dynamic> g) {
    // set default values if they are not specified by constructor
    final stopwatch = Stopwatch()..start();
    markerCreationCallback ??= createDefaultMarker;
    polyLineCreationCallback ??= createDefaultTaggedPolyline;
    polygonCreationCallback ??= createDefaultTaggedPolygon;
    defaultMarkerColor ??= Colors.red.withOpacity(0.8);
    defaultMarkerIcon ??= Icons.location_pin;
    defaultTaggedPolylineColor ??= Colors.blue.withOpacity(0.8);
    defaultTaggedPolylineStroke ??= 3.0;
    defaultTaggedPolygonBorderColor ??= Colors.black.withOpacity(0.8);
    defaultTaggedPolygonFillColor ??= Colors.black.withOpacity(0.1);
    defaultTaggedPolygonIsFilled ??= true;
    defaultTaggedPolygonBorderStroke ??= 1.0;

    // loop through the GeoJson Map and parse it
    for (Map f in g['features'] as List) {
      String geometryType = f['geometry']['type'].toString();
      //debugPrint("geometryType: $geometryType");
      switch (geometryType) {
        case 'Point':
          {
            markers.add(
              markerCreationCallback!(
                  LatLng(f['geometry']['coordinates'][1] as double,
                      f['geometry']['coordinates'][0] as double),
                  f['properties'] as Map<String, dynamic>),
            );
          }
          break;
        case 'MultiPoint':
          {
            for (final point in f['geometry']['coordinates'] as List) {
              markers.add(
                markerCreationCallback!(
                    LatLng(point[1] as double, point[0] as double),
                    f['properties'] as Map<String, dynamic>),
              );
            }
          }
          break;
        case 'LineString':
          {
            final List<LatLng> lineString = [];
            for (final coords in f['geometry']['coordinates'] as List) {
              lineString.add(LatLng(coords[1] as double, coords[0] as double));
            }
            polylines.add(polyLineCreationCallback!(
                lineString, f['properties'] as Map<String, dynamic>));
          }
          break;
        case 'MultiLineString':
          {
            for (final line in f['geometry']['coordinates'] as List) {
              final List<LatLng> lineString = [];
              for (final coords in line as List) {
                lineString
                    .add(LatLng(coords[1] as double, coords[0] as double));
              }
              polylines.add(polyLineCreationCallback!(
                  lineString, f['properties'] as Map<String, dynamic>));
            }
          }
          break;
        case 'Polygon':
          {
            final List<LatLng> outerRing = [];
            final List<List<LatLng>> holesList = [];
            int pathIndex = 0;
            for (final path in f['geometry']['coordinates'] as List) {
              final List<LatLng> hole = [];
              for (final coords in path as List<dynamic>) {
                if (pathIndex == 0) {
                  // add to polygon's outer ring
                  outerRing
                      .add(LatLng(coords[1] as double, coords[0] as double));
                } else {
                  // add it to current hole
                  hole.add(LatLng(coords[1] as double, coords[0] as double));
                }
              }
              if (pathIndex > 0) {
                // add hole to the polygon's list of holes
                holesList.add(hole);
              }
              pathIndex++;
            }
            polygons.add(polygonCreationCallback!(
                outerRing, holesList, f['properties'] as Map<String, dynamic>));
          }
          break;
        case 'MultiPolygon':
          {
            for (final polygon in f['geometry']['coordinates'] as List) {
              final List<LatLng> outerRing = [];
              final List<List<LatLng>> holesList = [];
              int pathIndex = 0;
              for (final path in polygon as List) {
                List<LatLng> hole = [];
                for (final coords in path as List<dynamic>) {
                  if (pathIndex == 0) {
                    // add to polygon's outer ring
                    outerRing
                        .add(LatLng(coords[1] as double, coords[0] as double));
                  } else {
                    // add it to a hole
                    hole.add(LatLng(coords[1] as double, coords[0] as double));
                  }
                }
                if (pathIndex > 0) {
                  // add to polygon's list of holes
                  holesList.add(hole);
                }
                pathIndex++;
              }
              polygons.add(polygonCreationCallback!(outerRing, holesList,
                  f['properties'] as Map<String, dynamic>));
            }
          }
          break;
      }
    }
    debugPrint(
        'parseGeoJson() executed in ${stopwatch.elapsed.inMilliseconds}');
    return;
  }

  /// default function for creating tappable [Marker]
  Widget defaultTappableMarker(Map<String, dynamic> properties,
      void Function(Map<String, dynamic>) onMarkerTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onMarkerTap(properties);
        },
        child: Icon(defaultMarkerIcon, color: defaultMarkerColor),
      ),
    );
  }

  /// default callback function for creating [Marker]
  Marker createDefaultMarker(LatLng point, Map<String, dynamic> properties) {
    return Marker(
      point: point,
      builder: (context) => defaultTappableMarker(properties, markerTapped),
    );
  }

  /// default callback function for creating [TaggedPolyline]
  TaggedPolyline createDefaultTaggedPolyline(
      List<LatLng> points, Map<String, dynamic> properties) {
    return TaggedPolyline(
        points: points,
        color: defaultTaggedPolylineColor!,
        strokeWidth: defaultTaggedPolylineStroke!);
  }

  /// default callback function for creating [TaggedPolygon]
  TaggedPolygon createDefaultTaggedPolygon(List<LatLng> outerRing,
      List<List<LatLng>>? holesList, Map<String, dynamic> properties) {
    return TaggedPolygon(
      points: outerRing,
      holePointsList: holesList,
      borderColor: defaultTaggedPolygonBorderColor!,
      color: defaultTaggedPolygonFillColor!,
      isFilled: defaultTaggedPolygonIsFilled!,
      borderStrokeWidth: defaultTaggedPolygonBorderStroke!,
    );
  }

  /// default callback function called when tappable [Marker] is tapped
  void markerTapped(Map<String, dynamic> map) {
    if (onMarkerTapCallback != null) {
      onMarkerTapCallback!(map);
    }
  }
}
