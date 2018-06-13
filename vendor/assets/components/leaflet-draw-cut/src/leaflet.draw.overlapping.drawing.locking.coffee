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

L.Draw.Feature.DrawMixin =
  _draw_initialize: ->
    @on 'enabled', @_draw_on_enabled, @
    @on 'disabled', @_draw_on_disabled, @

  _draw_on_enabled: ->
    return unless @options.overlapLayers and @options.overlapLayers.length

    @_mouseMarker.on 'mouseup', @_draw_on_click, @

  _draw_on_click: (e) ->
    marker = @_markers[..].pop()

    return unless marker
    coords = L.GeoJSON.latLngToCoords marker.getLatLng(), 5
    markerPoint = turf.point coords

    for layerGroup in @options.overlapLayers
      continue unless layerGroup.getLayers.constructor.name == 'Function'
      for layer in layerGroup.getLayers()
        polygon = layer.toTurfFeature()

        if turfBooleanPointInPolygon(markerPoint, polygon, ignoreBoundary: true)
          pos = marker.getLatLng()
          
          latlngs = @_poly.getLatLngs()
          latlngs.splice(-1, 1)
          @_poly.setLatLngs latlngs

          @_markers.splice(-1,1)
          @_markerGroup.removeLayer marker
          @_updateGuide(@_map.latLngToLayerPoint(pos))

  _draw_on_disabled: ->
    if @_mouseMarker
      @_mouseMarker.off 'mouseup', @_draw_on_click, @


L.Draw.Feature.include L.Draw.Feature.DrawMixin
L.Draw.Feature.addInitHook '_draw_initialize'

L.Draw.Polygon.include
  __shapeIsValid: L.Draw.Polygon::_shapeIsValid
  _shapeIsValid: () ->
    linestring = @_poly.toTurfFeature()
    poly = turfLineToPolygon(linestring, autoComplete: true, orderCoords: true)
    valid = true

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

