L = require 'leaflet'

turf = require '@turf/helpers'
turfDifference = require('@turf/difference')
turfUnion = require('@turf/union').default
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
