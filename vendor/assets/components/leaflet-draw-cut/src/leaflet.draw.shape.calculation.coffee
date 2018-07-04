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


removeEmptyPolygon = (geom) ->
  switch (geom.type)
    when 'Polygon'
      return geom if (turfArea(geom) > 1)
      return null
    when 'MultiPolygon'
      coordinates = []
      turfMeta.flattenEach geom, (feature) ->
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

findPrevPoint = (array, currentIndex) ->
  if currentIndex == 0
    prevIndex = array.length - 1 - 1
    prevPoint = array[prevIndex]
    while !prevPoint && (prevIndex > currentIndex + 1)
      prevIndex -= 1
      prevPoint = array[prevIndex]
  else
    prevIndex = currentIndex - 1
    prevPoint = array[prevIndex]
    while !prevPoint && (prevIndex > 0)
      prevIndex -= 1
      prevPoint = array[prevIndex]

  prevPoint

findNextPoint = (array, currentIndex) ->
  if currentIndex == array.length - 1
    nextIndex = 1
    nextPoint = array[nextIndex]
    while !nextPoint && (nextIndex < currentIndex - 1)
      nextIndex += 1
      nextPoint = array[nextIndex]
  else
    nextIndex = currentIndex + 1
    nextPoint = array[nextIndex]
    while !nextPoint && (nextIndex < array.length - 1 - 1)
      nextIndex += 1
      nextPoint = array[nextIndex]

  nextPoint

cleanCoords = (coordinates) ->
  coordinates.filter (coords) ->
    coords != undefined

cleanPolygon = (polygon) ->
  type = polygon.geometry.type

  if type == 'MultiPolygon'
    for poly, index in polygon.geometry.coordinates
      realPolygon = turf.polygon(poly)
      area = turfArea(realPolygon)
      polygon.geometry.coordinates.splice(index, 1) if area < 0.000001

  newPolygons = []
  coordinates = polygon.geometry.coordinates
  for points, polyIndex in coordinates
    realCoords = if type == 'Polygon'
                   points
                 else if type == 'MultiPolygon'
                   points[0]

    pointRemoved = true

    while pointRemoved
      newCoordinates = []
      pointRemoved = false

      for coords, index in realCoords
        continue unless coords && (nextCoord = realCoords[index + 1])
        roundedCoord = [Math.floor(coords[0] * 1000000) / 1000000, Math.floor(coords[1] * 1000000) / 1000000]
        roundedNextCoord = [Math.floor(nextCoord[0] * 1000000) / 1000000, Math.floor(nextCoord[1] * 1000000) / 1000000]
        if JSON.stringify(roundedCoord) == JSON.stringify(roundedNextCoord)
          delete realCoords[index]
          if index == 0
            realCoords.splice(realCoords.length - 1, 1)
            realCoords[0] = realCoords[realCoords.length - 1]
          pointRemoved = true

      realCoords = cleanCoords realCoords

      for point, pointIndex in realCoords
        continue unless point
        prevPoint = findPrevPoint realCoords, pointIndex
        nextPoint = findNextPoint realCoords, pointIndex
        bearing1 = turfBearing(point, prevPoint)
        bearing2 = turfBearing(point, nextPoint)
        roundedBearing1 = Math.floor(bearing1 * 100) / 100
        roundedBearing2 = Math.floor(bearing2 * 100) / 100
        if roundedBearing1 == roundedBearing2
          delete realCoords[pointIndex]
          if pointIndex == 0
            realCoords.splice(realCoords.length - 1, 1)
            realCoords[0] = realCoords[realCoords.length - 1]
          pointRemoved = true
        else
          newCoordinates.push point

      realCoords = cleanCoords realCoords

    if type == 'Polygon'
      newPolygons.push newCoordinates
    else if type == 'MultiPolygon'
      newPolygons.push [newCoordinates]

  polygon.geometry.coordinates = newPolygons
  polygon


class L.Calculation

  @union: (polygons) ->
    turfPolygons = polygons.map (polygon) ->
      turf.feature(polygon)
    turfPolygons.reduce (poly1, poly2) ->
      turfUnion(poly1, poly2)

  @difference: (polygon1, polygon2) ->
    polygon1 = turf.feature(polygon1)
    polygon2 = turf.feature(polygon2)
    diffCoordinates = polygonClipping.difference(polygon1.geometry.coordinates, polygon2.geometry.coordinates)
    turf.multiPolygon(diffCoordinates)
    # difference = customDifference(polygon1, polygon2)
    # difference = cleanPolygon difference
    # diffCoords = difference.geometry.coordinates if difference
    # if difference && difference.geometry.type == 'Polygon' && diffCoords.length > 1
    #   difference = diffCoords.reduce (coords1, coords2) ->
    #     wholePolygon = if coords1.hasOwnProperty('type') then coords1 else turf.polygon([coords1])
    #     polygonHole = turf.polygon([coords2])
    #     diff = customDifference(wholePolygon, polygonHole)
    #     cleanPolygon diff
    # difference
