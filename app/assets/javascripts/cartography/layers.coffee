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

  class C.BaseLayers extends C.Layers
    @options:
      backgrounds: []

    constructor: ( map, options = {} ) ->
      L.Util.setOptions @, options
      super(map)

    add: (layers) ->
      layers = [layers] unless layers.constructor.name is "Array"

      newLayers = {}

      for layer in layers
        newLayers[layer] = L.tileLayer.provider(layer)

      L.Util.extend(@layers, newLayers)
      newLayers

  class C.OverlayLayers extends C.Layers
    @options:
      overlays: []
      series: {}

    constructor: ( map, options = {} ) ->
      L.Util.setOptions @, options
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
          layerGroup = renderedLayer.buildLayerGroup(@options)
          layerGroup.name = layer.name
          layerGroup.renderedLayer = renderedLayer

          newLayers[layer.label] = layerGroup
          newLayers[layer.label].addTo(@getMap())

      newLayers

)(window.Cartography = window.Cartography || {}, jQuery)
