L = require 'leaflet'

turf = require '@turf/helpers'
turfDifference = require('@turf/difference')
turfUnion = require('@turf/union').default
turfTruncate = require('@turf/truncate').default

class L.Calculation

  @union: (polygons) ->
    turfPolygons = polygons.map (polygon) ->
      turf.feature(polygon)
    turfUnion(turfPolygons...)

  @difference: (polygon1, polygon2) ->
    polygon1 = turf.feature(polygon1)
    polygon2 = turf.feature(polygon2)
    polygon1 = turfTruncate(polygon1, precision: 6)
    polygon2 = turfTruncate(polygon2, precision: 6)
    turfDifference(polygon1, polygon2)
