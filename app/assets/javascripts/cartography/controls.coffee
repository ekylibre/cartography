((C, $) ->
  "use strict"

  class C.Control extends C.BaseClass
    constructor: (map) ->
      super(map)

  class C.Controls extends C.Control
    constructor: (map) ->
      @controls = {}

      super(map)

    add: (id, control, addToMap = true) ->
      @controls[id] = control
      @getMap().addControl control.getControl() unless !addToMap

    remove: (id) ->
      if control = @get(id)
        @getMap().removeControl control.getControl()
      @controls[id] = undefined

    get: (id) ->
      @controls[id]

  class C.Controls.Layers extends C.Controls
    options:
      position: 'topleft'
    constructor: ( control, map, options = {} ) ->
      super(map)

      C.Util.setOptions @, options

      @control = control || new L.Control.Layers(undefined, undefined, @options)

      @layers = {}

    getLayers: ->
      @references.getLayers()

    getMainLayer: ->
      @references.getMainLayer()

    getLayer: (name) ->
      @references.getLayers()[name]

    getControl: ->
      @control

  class C.Controls.BaseLayers extends C.Controls.Layers
    options:
      backgrounds: [
        'Esri.WorldImagery'
        'OpenStreetMap.Mapnik',
        'OpenStreetMap.HOT',
        'Thunderforest.Landscape',
      ]

    constructor: ( control, map, options = {} )->
      C.Util.setOptions @, options
      super(control, map)

      @references = new C.BaseLayers(map, @options)
      @add(@options.backgrounds)

      @setActive(0)

    add: (layers) ->
      newLayers = @references.add(layers)

      for name, layer of newLayers
        @getControl().addBaseLayer(layer, name)

    setActive: (index) ->
      @getMap().addLayer(@getLayers()[Object.keys(@getLayers())[index]])

  class C.Controls.OverlayLayers extends C.Controls.Layers
    options:
      minZoom: 0
      maxZoom: 25
      overlays: []
      series: {}

    constructor: ( control, map, options = {} )->
      C.Util.setOptions @, options
      super(control, map)

      @references = new C.OverlayLayers(map, @options)
      @add(@options.overlays, 'tiles') unless !@options.overlays.length
      @add([@options.series, @options.layers], 'series') if @options.series?

    #TODO: refactoring
    add: (layers, type) ->
      [series, propertiesCollection, ...] = layers

      propertiesCollection ||= []

      if !propertiesCollection.length
        newLayers = @references.add(layers, type)

        for name, layer of newLayers
          @getControl().addOverlay(layer, name)

      for properties in propertiesCollection
        if @references.getLayers()[properties.name] is undefined
          newLayers = @references.add(layers, type)

          for name, layer of newLayers
            @getControl().addOverlay(layer, name)
        else
          @references.updateSerie(@references.getLayers()[properties.name], series[properties.name])

    remove: (name) ->
      layer = @getLayer name
      @getControl().removeLayer layer
      layer.eachLayer (l) =>
        @getMap().removeLayer l

      @getMap().removeLayer layer
      delete @references.layers[name]


  class C.Controls.Scale extends C.Controls
    options:
      position: "bottomright"
      imperial: false
      maxWidth: 200

    constructor: ( map, options = {} ) ->
      super(map)
      C.Util.setOptions @, options
      @control = new L.Control.Scale(@options)

    getControl: ->
      @control

  class C.Controls.Draw extends C.Controls
    options:
      draw:
        edit: false
        draw:
          marker: false
          circlemarker: false
          polyline: false
          rectangle: false
          circle: false
          polygon:
            allowIntersection: false
            showArea: false
      snap:
        polygon:
          guideLayers: []
          snapDistance: 15
          snapOriginDistance: 30
          allowIntersection: false
          guidelineDistance: 8
          shapeOptions:
            dashArray: '8, 8'
            fill: false
            color: '#FF5722'
            opacity: 1

    constructor: ( map, options = {} ) ->
      super(map)
      C.Util.setOptions @, options

      @control = new L.Control.Draw(@options.draw)
      @control.setDrawingOptions(@options.snap)

      @toolbar = @control._toolbars['draw']
      if @options.draw.panel
        new L.Control.ControlPanel.Draw @toolbar, @options.draw.panel

      @initHooks()

    initHooks: (->)

    getControl: ->
      @control

  class C.Controls.Edit extends C.Controls
    options:
      edit:
        label: undefined
        reactiveMeasure: true
        featureGroup: undefined
        remove: false
        shapeOptions:
          color: "#3498db"
          fillOpacity: 0.8
          popup: false
      snap:
        polyline:
          guideLayers: []
          snapDistance: 5
        polygon:
          guideLayers: []
          snapDistance: 5
    constructor: (map, options = {}) ->
      super(map)

      C.Util.setOptions @, options

      @editionLayer = L.geoJson(undefined,
        style: (feature) =>
          C.Util.extend @options.edit.shapeOptions, feature.properties)

      @control = new L.Control.SnapEdit(@options)

      @initHooks()

    initHooks: ->
      @getMap().on "draw:editstart", (e) =>

    getControl: ->
      @control

    getLayer: ->
      @editionLayer

    addLayer: (layer) ->
      @getLayer().addData layer.toGeoJSON()
      # @getLayer().addLayer layer

    addTo: (control) ->
      control.addOverlay @getLayer(), @options.label


  class C.Controls.Edit.ReactiveMeasure extends C.Controls
    options:
      reactiveMeasure:
        position: 'bottomright'
        metric: true
        feet: false
        tooltip: false

    constructor: (map, control, options = {}) ->
      super(map)
      C.Util.setOptions @, options

      @control = new L.ReactiveMeasureControl(control.getLayer(), @options.reactiveMeasure)

      @initHooks()

    initHooks: (->)

    getControl: ->
      @control

  class C.Controls.LayerSelection extends C.Controls
    options:
      layerSelection:
        featureGroup: undefined

    constructor: (map, options = {}) ->
      super(map)

      C.Util.setOptions @, options

      @control = new L.Control.LayerSelection(@options.layerSelection)

      @initHooks()

    initHooks: ->
      # @getMap().on "draw:editstart", (e) =>

    getControl: ->
      @control

  class C.Controls.Cut extends C.Controls
    options:
      cut:
        featureGroup: undefined

    constructor: (map, options = {}) ->
      super(map)

      C.Util.setOptions @, options

      @control = new L.Control.Cut(@options.cut)

      @initHooks()

    initHooks: ->
      # @getMap().on "draw:editstart", (e) =>

    getControl: ->
      @control

  class C.Controls.Merge extends C.Controls
    options:
      merge:
        featureGroup: undefined

    constructor: (map, options = {}) ->
      super(map)

      C.Util.setOptions @, options

      @control = new L.Control.Merge(@options.merge)

      @initHooks()

    initHooks: (->)

    getControl: ->
      @control

)(window.Cartography = window.Cartography || {}, jQuery)
