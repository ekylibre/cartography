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
        poly = turf.polygon(polyCoords)
        area = turfArea(poly)
        return if area < 10**-@PRECISION

        @cleanPolygon(poly).geometry.coordinates

      return turf.multiPolygon polys

    roundCoord = (c) =>
      Math.floor(c * 10**@PRECISION) / 10**@PRECISION

    poly = polygon.geometry.coordinates.map (ring) =>
      pointRemoved = true

      while pointRemoved
        newCoordinates = []
        pointRemoved = false

        for coord, index in ring
          continue unless coord && (nextCoord = ring[index + 1])

          roundedCoord = coord.map(roundCoord)
          roundedNextCoord = nextCoord.map(roundCoord)

          if JSON.stringify(roundedCoord) == JSON.stringify(roundedNextCoord)
            ring.splice(index, 1)
            if index == 0
              ring.pop()
              ring.unshift ring[..].pop()
            pointRemoved = true

        for coord, index in ring
          prevCoord = @findPrevPoint ring, index
          nextCoord = @findNextPoint ring, index
          roundedBearing1 = Math.floor(turfBearing(coord, prevCoord) * 100) / 100
          roundedBearing2 = Math.floor(turfBearing(coord, nextCoord) * 100) / 100

          if roundedBearing1 == roundedBearing2
            ring.splice(index, 1)
            if index == 0
              ring.pop()
              ring.unshift ring[..].pop()
            pointRemoved = true

      ring
    turf.polygon(poly)

  @difference: (feature1, feature2) ->
    diffCoordinates = polygonClipping.difference(feature1.geometry.coordinates, feature2.geometry.coordinates)

    @cleanPolygon turf.multiPolygon(diffCoordinates)
    
