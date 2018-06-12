L = require 'leaflet'
_ = require 'lodash'

turf = require '@turf/helpers'
turfBooleanPointInPolygon = require('@turf/boolean-point-in-polygon').default
#turfBooleanOverlap = require('@turf/boolean-overlap').default
turfBooleanDisjoint = require('@turf/boolean-disjoint').default
turfBooleanWithin = require('@turf/boolean-within').default
turfLineToPolygon = require('@turf/line-to-polygon').default

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
    console.log 'shapeIsValid'
    disjoint = false
    #within = false
    poly = turfLineToPolygon(@_poly.toTurfFeature(), autoComplete: true, orderCoords: true)
    console.log poly

    for layerGroup in @options.overlapLayers
      continue unless layerGroup.getLayers.constructor.name == 'Function'
      for layer in layerGroup.getLayers()
        polygon = layer.toTurfFeature()
        disjoint = turfBooleanDisjoint(polygon, poly)
        #within = turfBooleanWithin(polygon, poly)
        #console.log disjoint, within
        #break if !disjoint || within
        break if !disjoint

    superClass = @__shapeIsValid.apply @, arguments
    console.log disjoint
    #return (disjoint && !within) && superClass
    valid = disjoint && superClass

    unless valid
      @_map.fire L.Draw.Event.INVALIDATED, error: 'overlapping'

    valid
