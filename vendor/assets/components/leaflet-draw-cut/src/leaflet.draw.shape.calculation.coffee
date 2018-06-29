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


removeEmptyPolygon = (geom) ->
  switch (geom.type)
    when 'Polygon'
      return geom if (turfArea(geom) > 1)
      return null
    when 'MultiPolygon'
      coordinates = []
      meta.flattenEach geom, (feature) ->
        coordinates.push(feature.geometry.coordinates) if (turfArea(feature) > 1)
      return {type: 'MultiPolygon', coordinates: coordinates} if (coordinates.length)

customDifference = (polygon1, polygon2) ->
  geom1 = turfInvariant.getGeom(polygon1)
  geom2 = turfInvariant.getGeom(polygon2)
  properties = polygon1.properties || {}

  geom1 = removeEmptyPolygon(geom1)
  geom2 = removeEmptyPolygon(geom2)
  return null if (!geom1)
  return turf.feature(geom1, properties) if (!geom2)

  differenced = martinez.diff(geom1.coordinates, geom2.coordinates)
  for contour in differenced
    for polygon in contour
      polygon.push polygon[0] unless JSON.stringify(polygon[polygon.length - 1]) == JSON.stringify(polygon[0])
  return null if (differenced.length == 0)
  return turf.polygon(differenced[0], properties) if (differenced.length == 1)
  turf.multiPolygon(differenced, properties)



class L.Calculation

  @union: (polygons) ->
    turfPolygons = polygons.map (polygon) ->
      turf.feature(polygon)
    turfUnion(turfPolygons...)

  @difference: (polygon1, polygon2) ->
    polygon1 = turf.feature(polygon1)
    polygon2 = turf.feature(polygon2)
    difference = customDifference(polygon1, polygon2)

    newPolygons = []
    coordinates = difference.geometry.coordinates
    for points, polyIndex in coordinates
      newCoordinates = []
      for point, pointIndex in points
        if pointIndex == 0
          prevPoint = points[coordinates[polyIndex].length - 1 - 1]
        else
          prevPoint = points[pointIndex - 1]
          # In case the previous point has been deleted in a previous iteration because it is irrelevant
          prevPoint ||= points[pointIndex - 2]
        nextPoint = points[pointIndex + 1]
        # For the last point of the coordinates array, which is also the first
        nextPoint ||= points[1]
        bearing1 = turfBearing(point, prevPoint)
        bearing2 = turfBearing(point, nextPoint)
        roundedBearing1 = Math.floor(bearing1 * 100) / 100
        roundedBearing2 = Math.floor(bearing2 * 100) / 100
        if roundedBearing1 == roundedBearing2
          delete coordinates[polyIndex][pointIndex]
        else
          newCoordinates.push point
      newPolygons.push newCoordinates

    difference.geometry.coordinates = newPolygons
    difference


