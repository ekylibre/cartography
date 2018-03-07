class L.IndexedGeoJSON extends L.GeoJSON

  constructor: (geojson, options) ->
    @_onEachFeature = options.onEachFeature

    onEachFeature = (geojson, layer) ->
      layer.on 'add', =>
        @indexLayer layer
      layer.on 'remove', =>
        @unindexLayer layer

      if @_onEachFeature
        @_onEachFeature geojson, layer

      return

    options.onEachFeature = L.Util.bind onEachFeature, @

    super geojson, options

L.IndexedGeoJSON.include L.LayerIndexMixin

class L.GhostIcon extends L.DivIcon
  options:
    iconSize: [20, 20]
    className: "plus-ghost-icon"
    html: ""

L.LayerGroup.include
  getLayerUUID: (layer) ->
    layer.feature.properties.uuid

  hasUUIDLayer: (layer) ->
    if !!layer && layerUUID = @getLayerUUID(layer)
      for id, l of @_layers
        if @getLayerUUID(l) == layerUUID
          return true
    return false

  getLayerID: (layer) ->
    layer.feature.properties.id

  hasIDLayer: (layer) ->
    if !!layer && layerID = @getLayerID(layer)
      for id, l of @_layers
        if @getLayerID(l) == layerID
          return true

  bindInit: (event, callback) ->
    unless @initialized && @initialized[event]
      @on event, callback, @
      @initialized[event] = true

  unbind: (event, callback) ->
    @off event, callback, @
    @initialized[event] = false

L.LayerGroup.addInitHook ->
  @initialized = {}
