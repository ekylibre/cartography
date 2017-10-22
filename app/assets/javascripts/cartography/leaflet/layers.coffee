class L.IndexedGeoJSON extends L.GeoJSON

  constructor: (geojson, options) ->
    @_onEachFeature = options.onEachFeature

    onEachFeature = (geojson, layer) ->
      @indexLayer layer
      if @_onEachFeature
        @_onEachFeature geojson, layer
      return

    options.onEachFeature = L.Util.bind onEachFeature, @

    super geojson, options

L.IndexedGeoJSON.include L.LayerIndexMixin
