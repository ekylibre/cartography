#= require cartography/layers

((C, $) ->
  "use strict"

  class C.Layer.Simple extends C.Layer
    constructor: (map, @layer, @data, @options = {}) ->
      super(map)

    buildLayerGroup: (style = {}) ->
      klass = if @layer.index then L.IndexedGeoJSON else L.GeoJSON

      new klass @data,
        style: (feature) =>
          if @layer.style and typeof(@layer.style) == "function"
            @layer.style.apply @, arguments
          else if @layer.style
            @layer.style
          else
            C.Util.extend style, feature.properties

        onEachFeature: (feature, layer) =>
          feature.properties ||= {}

          feature.properties.uuid ||= new UUID(4).format()

          layer.feature.properties = feature.properties

          if @layer.onEachFeature
            @layer.onEachFeature.apply @, arguments



    valid: () ->  true

  C.Layer.registerLayerType("simple", C.Layer.Simple)


)(window.Cartography = window.Cartography || {}, jQuery)
