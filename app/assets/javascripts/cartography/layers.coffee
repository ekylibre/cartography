((C, $) ->
  "use strict"

  class C.Layer extends C.BaseClass
    @LAYER_TYPES : {}
    constructor: (map, layer = undefined, data = undefined, options = {}) ->
      super(map)

      if layer and data and type = @constructor.LAYER_TYPES[layer.type]
        return new type(map, layer, data, options)

    @registerLayerType: (name, klass) ->
      @LAYER_TYPES[name] = klass

  class C.Layers extends C.Layer
    constructor: (map) ->
      super(map)
      @layers = {}

    getLayers: ->
      @layers

    getMainLayer: ->
      Object.values(@layers).filter((l) ->
        l.renderedLayer.layer.serie == "main")[0]

  class C.BaseLayers extends C.Layers
    options:
      backgrounds: []

    constructor: ( map, options = {} ) ->
      C.Util.setOptions @, options
      super(map)

    add: (layers) ->
      layers = [layers] unless layers.constructor.name is "Array"

      newLayers = {}
      providers = L.TileLayer.Provider.providers

      for layer in layers
        layerName = layer[0] || layer[1].name
        unless layer.constructor.name is "Array"
          newLayers[layer] = L.tileLayer.provider(layer)
          break

        unless layer[0]
          newLayers[layerName] = L.tileLayer(layer[1].url)
          break

        parts = layer[0].split('.')
        providerName = parts[0]
        variantName = parts[1]
        if providers[providerName]
          newLayers[layerName] = L.tileLayer.provider(layer[0], layer[1])
        else
          newLayers[layerName] = L.tileLayer(layer[1].url, layer[1])
                
      L.Util.extend(@layers, newLayers)
      newLayers

  class C.OverlayLayers extends C.Layers
    options:
      overlays: []
      series: {}
      properties:
        color: "#FAEBD7"
        fillOpacity: 0.35

    constructor: ( map, options = {} ) ->
      C.Util.setOptions @, options

      super(map)

    add: (layers, type) ->
      @["add#{type}"](layers)

    addtiles: (layers) ->
      layers = [layers] unless layers.constructor.name is "Array"

      newLayers = {}

      for layer in layers
        opts = {}
        opts.attribution = layer.attribution if layer.attribution?
        opts.minZoom = layer.minZoom || @options.minZoom
        opts.maxZoom = layer.maxZoom || @options.maxZoom
        opts.subdomains = layer.subdomains if layer.subdomains?
        opts.opacity = (layer.opacity / 100).toFixed(1) if layer.opacity? and !isNaN(layer.opacity)
        opts.tms = true if layer.tms
        newLayers[layer.name] =  L.tileLayer(layer.url, opts)
        newLayers[layer.name].addTo(@getMap())

      L.Util.extend(@layers, newLayers)
      newLayers

    addseries: (data) ->
      series = data[0]
      layers = data[1]

      newLayers = {}

      for layer in layers
        serie = series[layer.serie]
        renderedLayer = new C.Layer(@getMap(), layer, serie)

        if renderedLayer and renderedLayer.valid()
          layerGroup = renderedLayer.buildLayerGroup(@options.properties)
          layerGroup.name = layer.name
          layerGroup.renderedLayer = renderedLayer

          newLayers[layer.name] = layerGroup
          newLayers[layer.name].addTo(@getMap())

      L.Util.extend(@layers, newLayers)
      newLayers

    updateSerie: (layerGroup, serie) ->

      newLayers = new L.GeoJSON(serie)

      if layerGroup.getLayers().length
        removeList = layerGroup.getLayers().filter (layer) ->
          !newLayers.hasIDLayer layer

        if removeList.length
          for l in removeList
            layerGroup.removeLayer l

        updateList = newLayers.getLayers().filter (layer) ->
          !layerGroup.hasIDLayer layer

      else
        updateList = newLayers.getLayers()

      for layer in updateList
        layerGroup.addData(layer.toGeoJSON())


)(window.Cartography = window.Cartography || {}, jQuery)
