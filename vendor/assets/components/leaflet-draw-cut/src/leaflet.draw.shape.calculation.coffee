L = require 'leaflet'

turf = require '@turf/helpers'
turfDifference = require('@turf/difference')
turfUnion = require('@turf/union').default
turfTruncate = require('@turf/truncate').default
turfFlip = require '@turf/flip'
turfBooleanPointInPolygon = require('@turf/boolean-point-in-polygon').default
turfBearing = require('@turf/bearing').default
turfInvariant = require("@turf/invariant")
martinez = require "martinez-polygon-clipping"
turfArea = require("@turf/area").default
turfMeta = require("@turf/meta")
turfArea = require("@turf/area").default
polygonClipping = require("polygon-clipping")

class L.Calculation

  @union: (polygons) ->
    turfPolygons = polygons.map (polygon) ->
      turf.feature(polygon)
    turfPolygons.reduce (poly1, poly2) ->
      turfUnion(poly1, poly2)

  @difference: (polygon1, polygon2) ->
    diffCoordinates = polygonClipping.difference(polygon1.coordinates, polygon2.coordinates)
    turf.multiPolygon(diffCoordinates)
