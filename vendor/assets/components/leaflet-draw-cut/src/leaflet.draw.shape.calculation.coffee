L = require 'leaflet'

turf = require '@turf/helpers'
turfDifference = require('@turf/difference')
turfUnion = require('@turf/union').default
turfTruncate = require('@turf/truncate').default
turfBearing = require('@turf/bearing').default
turfArea = require("@turf/area").default
turfBuffer = require("@turf/buffer").default
turfContains = require("@turf/boolean-contains").default
turfIntersect = require("@turf/intersect").default
polygonClipping = require("polygon-clipping")

class L.Calculation
  @PRECISION: 6
  @AREA_PRECISION: 2
  @PERCENTAGE: 0.5

  @contains: (poly1, poly2) ->
    # Might need a small buffer on poly1 since a common border would return false
    poly1 = turf.feature poly1 unless poly1.type == 'Feature'
    poly2 = turf.feature poly2 unless poly2.type == 'Feature'
    turfContains poly1, poly2

  @roundCoord: (c, precision = @PRECISION) ->
    Math.floor(c * 10**precision) / 10**precision

  @union: (polygons) ->
    adjustPoints = (poly) =>
      polygonsCoordinates = if poly.geometry.type == 'Polygon'
                              [poly.geometry.coordinates]
                            else if poly.geometry.type == 'MultiPolygon'
                              poly.geometry.coordinates

      for polygon, polyIndex in polygonsCoordinates
        pointChanged = true
        while pointChanged
          pointChanged = false
          for ring, ringIndex in polygon
            for coord, coordIndex in ring
              continue if (coordIndex == 0) || (coordIndex == ring.length - 1)
              ringMinusCoord = ring.filter (coordinate, index) ->
                                 JSON.stringify(coordinate) == JSON.stringify(coord)
              if ringMinusCoord.length > 1
                newCoords = coord.map (latlng) =>
                              newLatlng = @roundCoord latlng, 10
                              newLatlng += coordIndex * (10**-10)
                polygonsCoordinates[polyIndex][ringIndex][coordIndex] = newCoords
                pointChanged = true

    polygonUnion = (poly1, poly2) =>
      allCoordinates = []
      if poly1
        switch poly1.geometry.type
          when 'Polygon'      then allCoordinates.push poly1.geometry.coordinates
          when 'MultiPolygon' then for coords in poly1.geometry.coordinates
                                   allCoordinates.push coords

      uniqCoordinates = []
      for coords in allCoordinates
        for points in coords
          for point in points
            roundedUniqCoords = uniqCoordinates.map (coord) =>
                                  [@roundCoord(coord[0]), @roundCoord(coord[1])]
            roundedPoint = [@roundCoord(point[0]), @roundCoord(point[1])]
            uniqCoordinates.push point unless JSON.stringify(roundedUniqCoords).includes JSON.stringify(roundedPoint)

      poly2Coordinates = if poly2.geometry.type == 'Polygon'
                           [poly2.geometry.coordinates]
                         else if poly2.geometry.type == 'MultiPolygon'
                           poly2.geometry.coordinates

      for coords, coordsIndex in poly2Coordinates
        for points, pointsIndex in coords
          for point, pointIndex in points
            for uniqCoord in uniqCoordinates
              roundedPoint = [@roundCoord(point[0]), @roundCoord(point[1])]
              roundedUniqCoord = [@roundCoord(uniqCoord[0]), @roundCoord(uniqCoord[1])]
              poly2Coordinates[coordsIndex][pointsIndex][pointIndex] = uniqCoord if (JSON.stringify(roundedPoint) == JSON.stringify(roundedUniqCoord)) && (JSON.stringify(point) != JSON.stringify(uniqCoord))

      return poly2 unless poly1

      for poly in [poly1, poly2]
        adjustPoints(poly)

      try
        turf.multiPolygon polygonClipping.union(poly1.geometry.coordinates, turfBuffer(poly2, 0.0001).geometry.coordinates)
      catch e
        turfUnion(poly1, turfBuffer(poly2, 0.0001))

    turfFeatures = polygons.map (polygon) ->
                     turf.feature(polygon)
    turfFeatures.reduce polygonUnion, false

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

      polys = polygon.geometry.coordinates.map (polyCoords) =>
        newPolyCoords = []
        for polyCoord in polyCoords
          poly = turf.polygon([polyCoord])
          area = turfArea(poly)
          continue if area < 10**-@AREA_PRECISION
          newPolyCoords.push polyCoord

        return unless newPolyCoords.length
        newPoly = turf.polygon(newPolyCoords)
        @cleanPolygon(newPoly).geometry.coordinates

      return turf.multiPolygon polys.filter (e) ->
        e

    poly = polygon.geometry.coordinates.map (ring) =>
      pointRemoved = true

      while pointRemoved
        newCoordinates = []
        pointRemoved = false

        index = 0
        while index < ring.length
          coord = ring[index]
          nextCoord = ring[index + 1]
          break unless nextCoord

          roundedCoord = coord.map (c) =>
            @roundCoord c
          roundedNextCoord = nextCoord.map (c) =>
            @roundCoord c

          if JSON.stringify(roundedCoord) == JSON.stringify(roundedNextCoord)
            ring.splice(index, 1)
            if index == 0
              ring.pop()
              ring.unshift ring[..].pop()
            pointRemoved = true
            ring = ring.filter (e) ->
                     e
          else
            index += 1

        index = 0

        while index < ring.length
          coord = ring[index]
          prevCoord = @findPrevPoint ring, index
          nextCoord = @findNextPoint ring, index
          roundedBearing1 = turf.bearingToAngle(turfBearing(coord, prevCoord))
          roundedBearing2 = turf.bearingToAngle(turfBearing(coord, nextCoord))
          angleDiff = 180 - Math.abs(Math.abs(roundedBearing1 - roundedBearing2) - 180)

          if angleDiff <= 0.05
            ring.splice(index, 1)
            if index == 0
              ring.pop()
              ring.unshift ring[..].pop()
            pointRemoved = true
            ring = ring.filter (e) ->
                     e
          else
            index += 1

      if ring.length then ring else undefined

    poly = poly.filter (e) ->
             e
    if poly.length then turf.polygon(poly) else null

  @difference: (feature1, feature2) ->
    try
      diffCoordinates = polygonClipping.difference(feature1.geometry.coordinates, feature2.geometry.coordinates)
      if diffCoordinates.length then @cleanPolygon turf.multiPolygon(diffCoordinates) else null
    catch e
      difference = turfDifference(feature1, feature2)
      if difference then @cleanPolygon difference else null

  @intersect: (feature1, feature2, percentage = @PERCENTAGE) ->
    try
      intersectionCoords = polygonClipping.intersection(feature1.coordinates, feature2.coordinates)
      intersection = turf.multiPolygon(intersectionCoords)
    catch e
      feature1 = turf.feature feature1
      feature2 = turf.feature feature2
      intersection = turfIntersect(feature1, feature2)

    return false unless intersection
    poly1Area = turfArea feature1
    intersectionArea = turfArea intersection
    ((intersectionArea / poly1Area) * 100) >= percentage
