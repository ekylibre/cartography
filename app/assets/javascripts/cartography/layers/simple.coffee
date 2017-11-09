#= require cartography/layers

((C, $) ->
  "use strict"

  class C.Layer.Simple extends C.Layer
    constructor: (map, @layer, @data, @options = {}) ->
      super(map)

    buildLayerGroup: (style = {}) ->
      klass = if @layer.index then L.IndexedGeoJSON else L.GeoJSON

      new klass @data,
        style: (feature) ->
          C.Util.extend style, feature.properties

        onEachFeature: (feature, layer) ->
          feature.properties ||= {}
          feature.properties.uuid ||= new UUID(4).format()
          layer.feature.properties = feature.properties

          # icon = new L.GhostIcon
          # L.marker([50.505, 30.57], {icon: icon}).addTo layer._map
          layer._ghostIcon = new L.GhostIcon

          


    valid: () ->  true

  C.Layer.registerLayerType("simple", C.Layer.Simple)


)(window.Cartography = window.Cartography || {}, jQuery)
