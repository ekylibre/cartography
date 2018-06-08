L = require 'leaflet'
_ = require 'lodash'

turf = require '@turf/helpers'
turfBooleanPointInPolygon = require('@turf/boolean-point-in-polygon').default

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
