L = require 'leaflet'
_ = require 'lodash'

turf = require '@turf/helpers'
turfLineSlice = require '@turf/line-slice'
turfRewind = require '@turf/rewind'
turfBooleanPointInPolygon = require('@turf/boolean-point-in-polygon').default
turfLineToPolygon = require('@turf/line-to-polygon').default
turfKinks = require '@turf/kinks'
turfMeta = require '@turf/meta'
turfPolygonize = require '@turf/polygonize'
turfDifference = require('@turf/difference')
turfBuffer = require('@turf/buffer').default
# turfBooleanPointOnLine = require '@turf/boolean-point-on-line'
turfNearestPointOnLine = require '@turf/nearest-point-on-line'
turfLineIntersect = require '@turf/line-intersect'
turfLineSplit = require('@turf/line-split').default
turfTruncate = require('@turf/truncate').default
turfGetCoords = require('@turf/invariant').getCoords
require 'leaflet-geometryutil'

L.Cutting = {}
L.Cutting.Polyline = {}
L.Cutting.Polyline.Event = {}
L.Cutting.Polyline.Event.START = "cut:polyline:start"
L.Cutting.Polyline.Event.STOP = "cut:polyline:stop"
L.Cutting.Polyline.Event.SELECT = "cut:polyline:select"
L.Cutting.Polyline.Event.UNSELECT = "cut:polyline:unselect"
L.Cutting.Polyline.Event.CREATED = "cut:polyline:created"
L.Cutting.Polyline.Event.UPDATED = "cut:polyline:updated"
L.Cutting.Polyline.Event.SAVED = "cut:polyline:saved"
L.Cutting.Polyline.Event.CUTTING = "cut:polyline:cutting"

class L.Cut.Polyline extends L.Handler
  @TYPE: 'cut-polyline'

  constructor: (map, options) ->
    @type = @constructor.TYPE
    @_map = map
    super map
    @options = _.merge @options, options

    @_featureGroup = options.featureGroup
    @_uneditedLayerProps = []
    @_polygonSliceMarkers = new L.LayerGroup 

    if !(@_featureGroup instanceof L.FeatureGroup)
      throw new Error('options.featureGroup must be a L.FeatureGroup')

  enable: ->
    if @_enabled or !@_featureGroup.getLayers().length
      return

    @_availableLayers = new L.GeoJSON [], style: (feature) ->
      color: feature.properties.color

    @_activeLayer = undefined

    @fire 'enabled', handler: @type

    @_map.fire L.Cutting.Polyline.Event.START, handler: @type

    @_availableLayers.addTo @_map
    @_availableLayers.on 'layeradd', @_enableLayer, @
    @_availableLayers.on 'layerremove', @_disableLayer, @

    @_map.on L.Cutting.Polyline.Event.SELECT, @_cutMode, @

    @_map.on 'zoomend moveend', @refreshAvailableLayers, @

    @_map.on L.ReactiveMeasure.Draw.Event.MOVE, @_on_move_measure, @
    @_map.on L.ReactiveMeasure.Edit.Event.MOVE, @_on_move_measure, @

    @_polygonSliceMarkers.addTo @_map
    super

  disable: ->
    if !@_enabled
      return
    @_map.fire L.Cutting.Polyline.Event.STOP, handler: @type

    @_polygonSliceMarkers.clearLayers()
    @_map.removeLayer @_polygonSliceMarkers

    if @_activeLayer and @_activeLayer.cutting
      @_activeLayer.cutting.disable()

      if @_activeLayer.cutting._mouseMarker
        @_activeLayer.cutting._mouseMarker.off 'mouseup', @_on_click, @

      if @_activeLayer and @_activeLayer.cutting._poly
        @_map.removeLayer @_activeLayer.cutting._poly
        delete @_activeLayer.cutting._poly

      delete @_activeLayer.cutting

    if @_activeLayer and @_activeLayer.editing
      @_activeLayer.editing.disable()

      if @_activeLayer and @_activeLayer.editing._poly
        @_map.removeLayer @_activeLayer.editing._poly

    if @_activeLayer and @_activeLayer._polys
      @_activeLayer._polys.clearLayers()

      delete @_activeLayer._polys
      delete @_activeLayer.editing
      #delete @_activeLayer.glue
    unless @_featureGroup._map
      @_map.addLayer @_featureGroup

    @_availableLayers.eachLayer (l) =>
      @_map.removeLayer l
    @_availableLayers.length = 0

    #@_startPoint = null
    @_activeLayer = null

    #@_map.off L.Draw.Event.DRAWVERTEX, @_finishDrawing, @
    #@_map.off 'click', @_finishDrawing, @

    #@_map.off 'mousemove', @_selectLayer, @
    #@_map.off 'mousemove', @_cutMode, @


    @_availableLayers.off 'layeradd', @_enableLayer, @
    @_availableLayers.off 'layerremove', @_disableLayer, @
    @_map.off 'zoomend moveend', @refreshAvailableLayers, @

    @_map.off L.Cutting.Polyline.Event.SELECT, @_cutMode, @

    @_map.off L.ReactiveMeasure.Draw.Event.MOVE, @_on_move_measure, @
    @_map.off L.ReactiveMeasure.Edit.Event.MOVE, @_on_move_measure, @

    @fire 'disabled', handler: @type
    super
    return

  addHooks: ->

    @refreshAvailableLayers()

    @_map.removeLayer @_featureGroup

  refreshAvailableLayers: ->
    @_featureGroup.addTo @_map

    return unless @_featureGroup.getLayers().length

    #RTree
    if typeof @_featureGroup.search == 'function'
      newLayers = new L.FeatureGroup(@_featureGroup.search(@_map.getBounds()))

      removeList = @_availableLayers.getLayers().filter (layer) ->
        !newLayers.hasLayer layer

      if removeList.length
        for l in removeList
          @_availableLayers.removeLayer l

      addList = newLayers.getLayers().filter (layer) =>
        !@_availableLayers.hasUUIDLayer layer

      if addList.length
        for l in addList
          unless @_availableLayers.hasUUIDLayer l
            geojson = l.toGeoJSON()
            geojson.properties.color = l.options.color
            @_availableLayers.addData(geojson)

    else
      @_availableLayers = @_featureGroup

    @_availableLayers.bringToBack()
    @_map.removeLayer @_featureGroup

  removeHooks: ->
    @_availableLayers.eachLayer @_disableLayer, @

  save: ->
    newLayers = []

    @_map.addLayer @_featureGroup

    if @_activeLayer && @_activeLayer._polys
      @_activeLayer._polys.eachLayer (l) =>
        @_featureGroup.addData l.toGeoJSON()

      @_activeLayer._polys.clearLayers()
      delete @_activeLayer._polys

      newLayers = @_featureGroup.getLayers()[-2..-1]

      @_map.fire L.Cutting.Polyline.Event.SAVED, oldLayer: {uuid: @_activeLayer.feature.properties.uuid, type: @_activeLayer.feature.properties.type}, layers: newLayers

      @_map.removeLayer @_activeLayer
    return

  _enableLayer: (e) ->
    layer = e.layer or e.target or e

    layer.options.original = L.extend({}, layer.options)

    if @options.disabledPathOptions
      pathOptions = L.Util.extend {}, @options.disabledPathOptions

      # Use the existing color of the layer
      if pathOptions.maintainColor
        pathOptions.color = layer.options.color
        pathOptions.fillColor = layer.options.fillColor

      layer.options.disabled = pathOptions

    if @options.selectedPathOptions
      pathOptions = L.Util.extend {}, @options.selectedPathOptions

      # Use the existing color of the layer
      if pathOptions.maintainColor
        pathOptions.color = layer.options.color
        pathOptions.fillColor = layer.options.fillColor || pathOptions.color

      pathOptions.fillOpacity = layer.options.fillOpacity || pathOptions.fillOpacity

      layer.options.selected = pathOptions

    layer.setStyle layer.options.disabled

    layer.on 'click', @_selectLayer, @

  activate: (layerId) ->
    activateLayer = undefined
    @_availableLayers.eachLayer (layer) ->
      if layer.feature and layer.feature.properties.uuid == layerId
        activateLayer = layer
        return

    if activateLayer
      @_selectLayer activateLayer

  _selectLayer: (e) ->
    layer = e.layer or e.target or e

    if layer != @_activeLayer
      @_activate layer
    #
    #mouseLatLng = e.latlng
    #found = false

    #@_availableLayers.eachLayer (layer) =>
      #mousePoint = mouseLatLng.toTurfFeature()
      #polygon = layer.toTurfFeature()

      #if turfinside.default(mousePoint, polygon)
        #if layer != @_activeLayer
          #@_activate layer, mouseLatLng
        #found = true
        #return

    #return if found
    ##if @_activeLayer && !@_activeLayer.glue
      ##@_unselectLayer @_activeLayer

  _unselectLayer: (e) ->
    layer = e.layer or e.target or e
    layer.selected = false
    if @options.selectedPathOptions
      layer.setStyle layer.options.disabled

    if layer.cutting
      layer.cutting.disable()
      delete layer.cutting

    #@_map.on 'mousemove', @_selectLayer, @

    @_activeLayer = null

  _disableLayer: (e) ->
    layer = e.layer or e.target or e
    layer.selected = false
    # Reset layer styles to that of before select
    if @options.selectedPathOptions
      layer.setStyle layer.options.original

    layer.off 'click', @_selectLayer, @

    delete layer.options.disabled
    delete layer.options.selected
    delete layer.options.original

  _activate: (e) ->
    layer = e.target || e.layer || e

    if !layer.selected
      layer.selected = true
      layer.setStyle layer.options.selected
      if @_activeLayer
        @_unselectLayer @_activeLayer

      @_activeLayer = layer

      @_map.fire L.Cutting.Polyline.Event.SELECT, layer: @_activeLayer
    else
      layer.selected = false
      layer.setStyle(layer.options.disabled)

      @_activeLayer.cutting.disable()
      delete @_activeLayer.cutting

      @_activeLayer = null
      @_map.fire L.Cutting.Polyline.Event.UNSELECT, layer: layer

  _cutMode: ->
    return unless @_activeLayer

    if !@_activeLayer.cutting
      @_activeLayer.cutting = new L.Draw.Polyline(@_map, shapeOptions: @options.cuttingPathOptions)

      #opts = _.merge(@options.snap, guideLayers: [@_activeLayer])
      #@_activeLayer.cutting.setOptions(opts)

      #if @options.cuttingPathOptions
        #pathOptions = L.Util.extend {}, @options.cuttingPathOptions

        ## Use the existing color of the layer
        #if pathOptions.maintainColor
          #pathOptions.color = @_activeLayer.options.color
          #pathOptions.fillColor = @_activeLayer.options.fillColor

        #pathOptions.fillOpacity = 0.5
        #@_activeLayer.options.cutting = pathOptions

      @_activeLayer.cutting.enable()

      @_activeLayer.cutting._mouseMarker.on 'mouseup', @_on_click, @

  _on_move_measure: (e) =>
    @_map.fire L.Cutting.Polyline.Event.CUTTING, perimeter: e.measure.perimeter

  _on_click: (e) =>
    return unless @_activeLayer.cutting._markers.length


    marker = @_activeLayer.cutting._markers[@_activeLayer.cutting._markers.length - 1]

    markerPoint = marker._latlng.toTurfFeature()
    poly = turfLineToPolygon(@_activeLayer.outerRingAsTurfLineString())

    isInPolygon = turfBooleanPointInPolygon(markerPoint, poly, ignoreBoundary: false)

    if @_activeLayer.cutting._markers.length == 1

      # Removes marker since it is not valid
      if isInPolygon
        poly = @_activeLayer.cutting._poly
        latlngs = poly.getLatLngs()
        latlngs.splice(-1, 1)
        @_activeLayer.cutting._markers.splice(-1,1)
        @_activeLayer.cutting._markerGroup.removeLayer marker
    
    if @_activeLayer.cutting._markers.length > 1
      unless isInPolygon
        @_stopCutDrawing()


  _slice: (polygon, polyline) ->

    poly = polygon.toTurfFeature()
    splitter = polyline.toTurfFeature()

    poly = turfTruncate(poly, precision: 6)
    splitter = turfTruncate(splitter, precision: 6)

    turfPolygonsCollection = @_polygonSlice(poly, splitter)

    featureGroup = new L.FeatureGroup()

    if turfPolygonsCollection.features.length > 2
      buffered = turfBuffer(poly, 0.01)

    index = 0
    turfMeta.featureEach turfPolygonsCollection, (turfPolygon) ->

      if turfPolygonsCollection.features.length > 2
        diff = turfDifference(turfPolygon, buffered)
        return if diff?

      polygon = new L.polygon [], className: "leaflet-polygon-slice c-#{index}"

      polygon._polygonSliceIcon = new L.PolygonSliceIcon html: "#{index+1}"

      polygon.feature ||= {}
      polygon.feature.properties ||= {}

      polygon.feature.properties.num = index+1
      polygon.feature.properties.color = "c-#{index}"
      
      polygon.fromTurfFeature turfPolygon
      featureGroup.addLayer polygon
      index++

    featureGroup
      

  _innerLineStrings: (poly) ->
    results = []
    coords = turfGetCoords poly
    coords.slice(1, coords.length).forEach (coord) ->
      results.push turf.lineString(coord)

    turf.featureCollection(results)

  _polygonSlice: (poly, splitter) ->
    coords = turfGetCoords(poly)
    outerRing = turf.lineString(coords[0])
    innerRings = @_innerLineStrings(poly)

    outerLineStrings = []

    # split outers
    turfMeta.featureEach turfLineSplit(outerRing, splitter), (line) ->
      outerLineStrings.push line

    # split splitter
    turfMeta.featureEach turfLineSplit(splitter, poly), (line) ->
      outerLineStrings.push line

    outerLineStrings = turfTruncate(turf.featureCollection(outerLineStrings), precision: 6)

    polygons = turfPolygonize.default(outerLineStrings)

    if innerRings.features.length
      newPolygons = []

      turfMeta.featureEach polygons, (polygon) =>
        turfMeta.featureEach innerRings, (innerRing) =>
          innerPolygon = turfPolygonize.default(innerRing)
          if innerPolygon.features.length == 1
            polygon = turfDifference(polygon, innerPolygon.features[0])

        newPolygons.push polygon

      polygons = turf.featureCollection(newPolygons)

    polygons

  _stopCutDrawing: () ->

    try
      drawnPolyline = @_activeLayer.cutting._poly

      #splitter = L.polyline(drawnPolyline.getLatLngs())
      splitter = L.polyline drawnPolyline.getLatLngs(), @options.cuttingPathOptions

      layerGroup = @_slice @_activeLayer, drawnPolyline

      unless layerGroup && layerGroup.getLayers().length >= 2
        @_activeLayer.cutting.disable()
        @_unselectLayer @_activeLayer
        return

      @_activeLayer.cutting._mouseMarker.off 'mouseup', @_on_click, @

      @_map.removeLayer @_activeLayer

      @_activeLayer._polys = layerGroup
      @_activeLayer._polys.addTo @_map

      @_activeLayer._polys.bringToFront()
      drawnPolyline.bringToFront()

      @_polygonSliceMarkers.clearLayers()

      @_activeLayer._polys.eachLayer (layer) =>
        return unless layer._polygonSliceIcon
        @_polygonSliceMarkers.addLayer L.marker(layer.getCenter(), icon: layer._polygonSliceIcon)

      @_activeLayer.cutting.disable()

      @_map.fire L.Cutting.Polyline.Event.CREATED, layers: layerGroup.getLayers(), parent: @_activeLayer

      @_activeLayer.editing = new L.Edit.Poly splitter

      @_activeLayer.editing._poly.addTo(@_map)
      @_activeLayer.editing.enable()

      L.DomUtil.addClass @_activeLayer.editing._verticesHandlers[0]._markers[0]._icon, 'marker-origin'
      L.DomUtil.addClass @_activeLayer.editing._verticesHandlers[0]._markers[@_activeLayer.editing._verticesHandlers[0]._markers.length - 1]._icon, 'marker-origin'

      @_activeLayer.editing._poly.on 'editstart', (e) =>
        for marker in @_activeLayer.editing._verticesHandlers[0]._markers
          marker.on 'move', @_moveMarker, @
          marker.on 'click', @_moveMarker, @

    catch e
      @_activeLayer.cutting.disable()
      @_unselectLayer @_activeLayer

  #_rewind: (marker) ->
    #return unless marker && marker._oldLatLng
    #marker._latlng = marker._oldLatLng
    #marker.update()

  _moveMarker: (e) ->
    marker = e.marker || e.target || e

    try
      drawnPolyline = @_activeLayer.editing._poly

      layerGroup = @_slice @_activeLayer, drawnPolyline

      unless layerGroup && layerGroup.getLayers().length >= 2
        #@_rewind(marker)
        @disable()
        #@_activeLayer.editing.disable()
        #@_map.removeLayer @_activeLayer.editing._poly
        #@_unselectLayer @_activeLayer
        return

      @_activeLayer._polys.clearLayers()

      @_map.removeLayer @_activeLayer

      @_activeLayer._polys = layerGroup
      @_activeLayer._polys.addTo @_map

      @_activeLayer._polys.bringToFront()
      drawnPolyline.bringToFront()

      @_polygonSliceMarkers.clearLayers()

      @_activeLayer._polys.eachLayer (layer) =>
        return unless layer._polygonSliceIcon
        @_polygonSliceMarkers.addLayer L.marker(layer.getCenter(), icon: layer._polygonSliceIcon)


      marker._oldLatLng = marker._latlng
      
      @_map.fire L.Cutting.Polyline.Event.UPDATED, layers: layerGroup.getLayers(), parent: @_activeLayer

    catch e
      #@_rewind(marker)
      @disable()
      #@_activeLayer.editing.disable()
      #@_unselectLayer @_activeLayer


  _hasAvailableLayers: ->
    @_availableLayers.length != 0

L.Cut.Polyline.include L.Mixin.Events
