#= require cartography/layers

((C, $) ->
  "use strict"

  class C.Layer.Simple extends C.Layer
    constructor: (map, @layer, @data, @options = {}) ->
      super(map)

    buildLayerGroup: (style = {}) ->
      L.geoJson @data,
        style: (feature) ->
          C.Util.extend style, feature.properties

    valid: () ->  true

  C.Layer.registerLayerType("simple", C.Layer.Simple)


)(window.Cartography = window.Cartography || {}, jQuery)
