L = require 'leaflet'
_ = require 'lodash'

turf = require '@turf/helpers'
turfBooleanPointInPolygon = require('@turf/boolean-point-in-polygon').default
turfBooleanPointOnLine = require('@turf/boolean-point-on-line').default
turfBooleanOverlap = require('@turf/boolean-overlap').default
turfBooleanDisjoint = require('@turf/boolean-disjoint').default
turfBooleanWithin = require('@turf/boolean-within').default
turfLineToPolygon = require('@turf/line-to-polygon').default
turfMeta = require '@turf/meta'
turfGetCoords = require('@turf/invariant').getCoords

L.Draw.Event.INVALIDATED = 'draw:invalidated'

L.Draw.Feature.DrawMixinn =
  _drawInitialize: ->
    @on 'enabled', @_drawOnEnabled, @
    @on 'disabled', @_drawOnDisabled, @

  _drawOnEnabled: ->
    return unless @options.overlapLayers and @options.overlapLayers.length

    @_mouseMarker.on 'mouseup', @_drawOnClick, @

  _drawOnClick: (e) ->
    marker = @_markers[..].pop()

    return unless marker

    ex = {
      'target':marker
    }
    
    coords = L.GeoJSON.latLngToCoords marker.getLatLng(), 6
    markerPoint = turf.point coords

    for layerGroup in @options.overlapLayers
      continue unless layerGroup.getLayers.constructor.name == 'Function'
      for layer in layerGroup.getLayers()
        polygon = layer.toTurfFeature()

        if turfBooleanPointInPolygon(markerPoint, polygon, ignoreBoundary: true)

          if L.Snap && L.Snap.snapMarker.constructor.name == 'Function'
            closest = L.Snap.snapMarker(ex, @options.overlapLayers, @_map, @options, 0)
            return true if closest.layer && closest.latlng

          pos = marker.getLatLng()
          
          latlngs = @_poly.getLatLngs()
          latlngs.splice(-1, 1)
          @_poly.setLatLngs latlngs

          @_markers.splice(-1,1)
          @_markerGroup.removeLayer marker
          @_updateGuide(@_map.latLngToLayerPoint(pos))


  _drawOnDisabled: ->
    if @_mouseMarker
      @_mouseMarker.off 'mouseup', @_drawOnClick, @


L.Draw.Feature.include L.Draw.Feature.DrawMixinn
L.Draw.Feature.addInitHook '_drawInitialize'

L.Draw.Polygon.include
  __shapeIsValid: L.Draw.Polygon::_shapeIsValid
  _shapeIsValid: () ->
    linestring = @_poly.toTurfFeature()
    poly = turfLineToPolygon(linestring, autoComplete: true, orderCoords: true)
    valid = true

    unless @options.allowOverlap
      for layerGroup in @options.overlapLayers
        continue unless layerGroup.getLayers.constructor.name == 'Function'
        for layer in layerGroup.getLayers()
          polygon = layer.toTurfFeature()
          valid = turfBooleanDisjoint(polygon, poly)
          unless valid
            valid = @_shapeOverlapPolygon(linestring, polygon)

            unless valid
              valid = @_shapeTouchingPolygon(poly, polygon)

          break unless valid
        break unless valid

    valid &&= @__shapeIsValid.apply @, arguments

    unless valid
      @_map.fire L.Draw.Event.INVALIDATED, error: 'overlapping'

    valid

  _shapeOverlapPolygon: (linestring, polygon) ->
    outerRing = turf.lineString(turfGetCoords(polygon)[0])
    turfBooleanOverlap(linestring, outerRing)

  _shapeTouchingPolygon: (poly, polygon) ->
    touch = false
    outerRing = turf.lineString(turfGetCoords(polygon)[0])
    coords = turfGetCoords(poly)[0]

    for coord in coords
      markerPoint = turf.point coord

      touch = turfBooleanPointOnLine(markerPoint, outerRing)
      break if touch
    touch

