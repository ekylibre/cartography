L = require 'leaflet'

turf = require '@turf/helpers'
turfDifference = require('@turf/difference')
turfUnion = require('@turf/union').default
turfTruncate = require('@turf/truncate').default
turfBearing = require('@turf/bearing').default
turfArea = require("@turf/area").default
polygonClipping = require("polygon-clipping")

class L.Calculation
  @PRECISION: 6

  @union: (polygons) ->
    turfFeatures = polygons.map (polygon) ->
      turf.feature(polygon)
    turfFeatures.reduce (poly1, poly2) ->
      turfUnion(poly1, poly2)

  @cleanCoords: (coordinates) ->
    coordinates.filter (coords) ->
      coords != undefined

  @findPrevPoint: (array, currentIndex) ->
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

  @findNextPoint: (array, currentIndex) ->
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

  @cleanPolygon: (polygon) ->
    type = polygon.geometry.type

    if type == 'MultiPolygon'
      for poly, index in polygon.geometry.coordinates
        realPolygon = turf.polygon(poly)
        area = turfArea(realPolygon)
        polygon.geometry.coordinates.splice(index, 1) if area < 10**-@PRECISION

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
          roundedCoord = [Math.floor(coords[0] * 10**@PRECISION) / 10**@PRECISION, Math.floor(coords[1] * 10**@PRECISION) / 10**@PRECISION]
          roundedNextCoord = [Math.floor(nextCoord[0] * 10**@PRECISION) / 10**@PRECISION, Math.floor(nextCoord[1] * 10**@PRECISION) / 10**@PRECISION]
          if JSON.stringify(roundedCoord) == JSON.stringify(roundedNextCoord)
            delete realCoords[index]
            if index == 0
              realCoords.splice(realCoords.length - 1, 1)
              realCoords[0] = realCoords[realCoords.length - 1]
            pointRemoved = true

        realCoords = @cleanCoords realCoords

        for point, pointIndex in realCoords
          continue unless point
          prevPoint = @findPrevPoint realCoords, pointIndex
          nextPoint = @findNextPoint realCoords, pointIndex
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

        realCoords = @cleanCoords realCoords

      if type == 'Polygon'
        newPolygons.push newCoordinates
      else if type == 'MultiPolygon'
        newPolygons.push [newCoordinates]

    polygon.geometry.coordinates = newPolygons
    polygon

  @difference: (feature1, feature2) ->
    p1 = turfTruncate(feature1, precision: 10).geometry
    p2 = turfTruncate(feature2, precision: 10).geometry
    diffCoordinates = polygonClipping.difference(p1.coordinates, p2.coordinates)

    cleanPolygons = @cleanPolygon turf.multiPolygon(diffCoordinates)
    cleanPolygons
   
    
