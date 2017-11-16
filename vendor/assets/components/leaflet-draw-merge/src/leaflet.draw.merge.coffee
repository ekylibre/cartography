L = require 'leaflet'
_ = require 'lodash'

turf = require '@turf/helpers'
turfMeta = require '@turf/meta'
turfBooleanOverlap = require '@turf/boolean-overlap'
turfUnion = require '@turf/union'
booleanPointOnLine = require '@turf/boolean-point-on-line'
require 'leaflet-geometryutil'

L.Merging = {}
L.Merging = {}
L.Merging.Event = {}
L.Merging.Event.START = "merge:start"
L.Merging.Event.STOP = "merge:stop"
L.Merging.Event.SELECT = "merge:select"
L.Merging.Event.UNSELECT = "merge:unselect"
L.Merging.Event.MERGED = "merge:merged"

class L.Merge extends L.Handler
  @TYPE: 'merge'

  constructor: (map, options) ->
    @type = @constructor.TYPE
    @_map = map
    super map
    @options = _.merge @options, options

    @_featureGroup = options.featureGroup
    @_availableLayers = new L.FeatureGroup
    @_activeLayer = undefined
    @_uneditedLayerProps = []

    if !(@_featureGroup instanceof L.FeatureGroup)
      throw new Error('options.featureGroup must be a L.FeatureGroup')

  enable: ->
    if @_enabled or !@_featureGroup.getLayers().length
      return

    @fire 'enabled', handler: @type

    @_map.fire L.Merging.Event.START, handler: @type

    super

    @_availableLayers.on 'layeradd', @_enableLayer, @
    @_availableLayers.on 'layerremove', @_disableLayer, @

    @_featureGroup.on 'layeradd', @refreshAvailableLayers, @
    @_featureGroup.on 'layerremove', @refreshAvailableLayers, @

    @_map.on L.Merging.Event.SELECT, @_mergeMode, @

    @_map.on 'zoomend moveend', () =>
      @refreshAvailableLayers()

    # @_map.on 'mousemove', @_selectLayer, @
    # @_map.on 'mousemove', @_mergeMode, @

  disable: ->
    if !@_enabled
      return
    @_availableLayers.off 'layeradd', @_enableLayer, @
    @_availableLayers.off 'layerremove', @_disableLayer, @

    super

    @_map.fire L.Merging.Event.STOP, handler: @type

    @_map.off L.Merging.Event.SELECT, @_startCutDrawing, @


    @fire 'disabled', handler: @type
    return

  addHooks: ->

    @refreshAvailableLayers()

    @_availableLayers.eachLayer @_enableLayer, @

  refreshAvailableLayers: ->
    return unless @_featureGroup.getLayers().length

    #RTree
    if typeof @_featureGroup.search == 'function'
      newLayers = new L.LayerGroup(@_featureGroup.search(@_map.getBounds()))

      removeList = @_availableLayers.getLayers().filter (layer) ->
        !newLayers.hasLayer layer

      if removeList.length
        for l in removeList
          @_availableLayers.removeLayer l

      addList = newLayers.getLayers().filter (layer) =>
        !@_availableLayers.hasLayer layer

      if addList.length
        for l in addList
          @_availableLayers.addLayer(l)

    else
      @_availableLayers = @_featureGroup

  removeHooks: ->
    @_featureGroup.eachLayer @_disableLayer, @

  save: ->
    # mergeSelectedLayers = new L.LayerGroup
    # @_featureGroup.eachLayer (layer) ->
    #   if layer.mergeSelected
    #     mergeSelectedLayers.addLayer layer
    #     layer.mergeSelected = false
    # @_map.fire L.Merging.Event.SELECTED, layers: mergeSelectedLayers

    #TMP
    @_featureGroup.eachLayer (l) =>
      @_map.removeLayer(l)
    @_featureGroup.addLayer(@_activeLayer._poly)
    @_featureGroup.addTo(@_map)
    # @_map.removeLayer(@_activeLayer._poly)
    delete @_activeLayer._poly
    delete @_activeLayer
    return

  _enableLayer: (e) ->
    layer = e.layer or e.target or e
    console.error 'enabling'

    layer.options.original = L.extend({}, layer.options)

    if @options.disabledPathOptions
      pathOptions = L.Util.extend {}, @options.disabledPathOptions

      # Use the existing color of the layer
      if pathOptions.maintainColor
        pathOptions.color = layer.options.color
        pathOptions.fillColor = layer.options.fillColor

      layer.options.disabled = pathOptions

    if @options.mergeSelectedPathOptions
      pathOptions = L.Util.extend {}, @options.mergeSelectedPathOptions

      # Use the existing color of the layer
      if pathOptions.maintainColor
        pathOptions.color = layer.options.color
        pathOptions.fillColor = layer.options.fillColor

      layer.options.mergeSelected = pathOptions

    layer.setStyle layer.options.disabled

    layer.on 'click', @_activate, @
    #
    # poly1 = turf.polygon([[[0,0],[0,5],[5,5],[5,0],[0,0]]])
    # poly2 = turf.polygon([[[1,1],[1,6],[6,6],[6,1],[1,1]]])
    #
    # poly1Leaf = new L.Polygon []
    # poly1Leaf.fromTurfFeature(poly1)
    # poly1Leaf.addTo @_map
    #
    # poly2Leaf = new L.Polygon []
    # poly2Leaf.fromTurfFeature(poly2)
    # poly2Leaf.addTo @_map
    #
    # console.error turfBooleanOverlap(poly1, poly2)
    #
    # union = turfUnion.default(poly1, poly2)
    # poly3 = new L.Polygon [], color: 'red'
    # console.error union
    # poly3.fromTurfFeature(union)
    # poly3.addTo @_map


  _unselectLayer: (e) ->
    layer = e.layer or e.target or e
    layer.mergeSelected = false
    if @options.mergeSelectedPathOptions
      layer.setStyle layer.options.disabled

    # if layer.merging
      # layer.merging.disable()
      # delete layer.merging

    # @_map.on 'mousemove', @_selectLayer, @

    @_activeLayer = null

  _disableLayer: (e) ->
    layer = e.layer or e.target or e
    layer.mergeSelected = false
    # Reset layer styles to that of before select
    if @options.mergeSelectedPathOptions
      layer.setStyle layer.options.original

    delete layer.options.disabled
    delete layer.options.mergeSelected
    delete layer.options.original

  _activate: (e) ->
    layer = e.target || e.layer || e

    if !layer.mergeSelected
      layer.mergeSelected = true
      layer.setStyle layer.options.mergeSelected

      # if @_activeLayer
        # @_unselectLayer @_activeLayer
      if !@_activeLayer
        @_activeLayer = layer

      # @_availableLayers.eachLayer (layer) =>
        # layer.off 'click', @_activate, @

      @_map.fire L.Merging.Event.SELECT, layer: @_activeLayer
    else
      layer.mergeSelected = false
      layer.setStyle(layer.options.disabled)

      @_activeLayer = null
      @_map.fire L.Merging.Event.UNSELECT, layer: layer

  _mergeMode: ->

    i = 0
    k = 0

    # for p in @_activeLayer.getLatLngs()[0][0]
      # console.error p
      # L.marker(p).addTo @_map

    #find contiguous polygons
    @_availableLayers.eachLayer (layer) =>
      if L.stamp(layer) != L.stamp(@_activeLayer) && k == 0

        console.error "try:", L.stamp(layer)
        activePoly = @_activeLayer.toTurfFeature()
        turfLayer = layer.toTurfFeature()

        console.error activePoly, turfLayer

        overlap = turfBooleanOverlap(activePoly, turfLayer)

        console.error overlap

        if overlap
          console.error turfLayer.geometry.coordinates
          console.error 'overlap'

          layer.options.original = layer.options

          layer.on 'mouseover', (e) ->
            console.error 'mouseover'
            e.target.setStyle fillColor: "#000", opacity: 1, fillOpacity: 1

          layer.on 'mouseout', (e) ->
            console.error 'mouseout'
            e.target.setStyle layer.options.disabled

          layer.off 'click', @_enableLayer, @
          layer.on 'click', @_merge, @

        i++

  _merge: (e) ->
    layer = e.layer || e.target || e
    console.error layer, @_activeLayer

    L.marker(@_activeLayer.getCenter()).addTo @_map

    outerRing = @_activeLayer.outerRingAsTurfLineString()
    turfLayer = layer.toTurfFeature()

    activePoly = @_activeLayer.toTurfFeature()


    j = 0

    turfCoords = []

    for coord in turfLayer.geometry.coordinates[0]
      closest = undefined
      coord2 = undefined

      if j == 1 || j == 2
        closest = L.GeometryUtil.closest(@_map, @_activeLayer, L.latLng(coord[1], coord[0]))
        console.error "closest:", closest

      if closest
        coord2 = [closest.lng, closest.lat]
        console.error 'prev: ', coord, 'next:',coord2
        console.error 'retest', L.GeometryUtil.closest(@_map, @_activeLayer, L.latLng(coord2[1], coord2[0]))

      if coord2
        point = turf.point(coord2)
        pt = L.latLng(coord2[1], coord2[0])
        turfCoords.push coord2

      else
        point = turf.point(coord)
        pt = L.latLng(coord[1], coord[0])
        turfCoords.push coord

      console.error point
      # L.marker(pt).addTo @_map
      console.error 'on the line:',booleanPointOnLine.default(point, outerRing)
      j++

    turfPoly = turf.polygon([turfCoords])
    console.error turfPoly
    union = turfUnion.default(activePoly, turfPoly)
    poly3 = new L.Polygon [], color: '#AB47BC'
    # console.error union
    poly3.fromTurfFeature(union)
    poly3.addTo @_map

    k = 1

  _hasAvailableLayers: ->
    @_availableLayers.getLayers().length != 0

L.Merge.include L.Mixin.Events
