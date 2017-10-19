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

    remove: (id, control) ->
      @controls[id] = undefined

    get: (id) ->
      @controls[id]

  class C.Controls.Layers extends C.Controls
    constructor: ( control, map, options = {} ) ->
      super(map)

      L.Util.setOptions @, options

      @control = control || new L.Control.Layers()

      @layers = {}

    getLayers: ->
      @references.getLayers()

    getLayer: (name) ->
      @references.getLayers()[name]

    getControl: ->
      @control

  class C.Controls.BaseLayers extends C.Controls.Layers
    options:
      backgrounds: [
        'OpenStreetMap.HOT',
        'OpenStreetMap.Mapnik',
        'Thunderforest.Landscape',
        'Esri.WorldImagery'
      ]

    constructor: ( control, map, options = {} )->
      L.Util.setOptions @, options
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
      L.Util.setOptions @, options
      super(control, map)

      @references = new C.OverlayLayers(map, @options)
      @add(@options.overlays, 'tiles') unless !@options.overlays.length
      @add([@options.series, @options.layers], 'series') if @options.series?

    add: (layers, type) ->
      newLayers = @references.add(layers, type)

      for name, layer of newLayers
        @getControl().addOverlay(layer, name)

  class C.Controls.Scale extends C.Controls
    options:
      position: "bottomright"
      imperial: false
      maxWidth: 200

    constructor: ( map, options = {} ) ->
      super(map)
      L.Util.setOptions @, options
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
        polyline:
          guideLayers: []
          snapDistance: 5
        polygon:
          guideLayers: []
          snapDistance: 5

    constructor: ( map, options = {} ) ->
      super(map)
      L.Util.setOptions @, options

      @control = new L.Control.Draw(@options.draw)
      @control.setDrawingOptions(@options.snap)

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
          # edit:
            # color: "#A40"
            # popup: false
        snap:
          polyline:
            guideLayers: []
            snapDistance: 5
          polygon:
            guideLayers: []
            snapDistance: 5

    constructor: (map, options = {}) ->
      super(map)

      L.Util.setOptions @, options

      @editionLayer = L.geoJson()
      @options.featureGroup = @editionLayer

      map.addLayer @editionLayer

      @control = new L.Control.SnapEdit(@options)

      @initHooks()

    initHooks: ->
      @getMap().on "draw:editstart", (e) =>

    getControl: ->
      @control

    getLayer: ->
      @editionLayer

    addLayer: (layer) ->
      # @getLayer().addData layer.toGeoJSON()
      @getLayer().addLayer layer

    addTo: (control) ->
      control.addOverlay @getLayer(), @options.label


  class C.Controls.Edit.ReactiveMeasure extends C.Controls
    options:
      reactiveMeasure:
        position: 'bottomright'
        metric: true
        feet: false
        tooltip: true

    constructor: (map, control, options = {}) ->
      super(map)
      L.Util.setOptions @, options

      @control = new L.ReactiveMeasureControl(control.getLayer(), @options.reactiveMeasure)

      @initHooks()

    initHooks: (->)

    getControl: ->
      @control


  class L.Control.SnapEdit extends L.Control
    options:
      position: 'topleft'
      draw: {}
      edit: false

    constructor: (options) ->
      L.Util.setOptions @, options
      super options
      toolbar = undefined
      @_toolbar = {}
      if L.SnapEditToolbar
        @options.snap.guideLayers = @options.snap.polygon.guideLayers

        @_toolbar = new L.SnapEditToolbar @options
      L.toolbar = this
      return

    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-draw')
      topClassName = 'leaflet-draw-toolbar-top'
      toolbarContainer = @_toolbar.addToolbar(map)
      if toolbarContainer
        L.DomUtil.addClass toolbarContainer.childNodes[0], topClassName
        container.appendChild toolbarContainer
      container

    onRemove: ->
      @_toolbar.removeToolbar()


  class L.SnapEditToolbar extends L.EditToolbar
    @TYPE: 'snapedit'

    options:
      edit:
        selectedPathOptions:
          dashArray: '10, 10'
          fill: true
          fillColor: '#fe57a1'
          fillOpacity: 0.1
          maintainColor: false
      remove: {}
      poly: null
      featureGroup: null

    constructor: (options = {}) ->
      L.Util.setOptions @, options
      @type = @TYPE

      super @options
      @_selectedFeatureCount = 0
      this

    #Get mode handlers information
    getModeHandlers: (map) ->
      featureGroup = @options.featureGroup
      [
        {
          enabled: @options.edit
          handler: new L.EditToolbar.SnapEdit map,
            snapOptions: @options.snap
            featureGroup: featureGroup
            selectedPathOptions: @options.edit.selectedPathOptions
            poly: @options.poly

          title: L.drawLocal.edit.toolbar.buttons.edit
        },
        {
          enabled: @options.remove
          handler: new L.EditToolbar.Delete map,
            featureGroup: featureGroup

          title: L.drawLocal.edit.toolbar.buttons.remove
        }
      ]

    #Get actions information
    getActions: (handler) ->
      actions = [
        {
          title: L.drawLocal.edit.toolbar.actions.save.title
          text: L.drawLocal.edit.toolbar.actions.save.text
          callback: @_save
          context: @
        }
        {
          title: L.drawLocal.edit.toolbar.actions.cancel.title
          text: L.drawLocal.edit.toolbar.actions.cancel.text
          callback: @disable
          context: @
        }
      ]

      if handler.removeAllLayers
        actions.push({
          title: L.drawLocal.edit.toolbar.actions.clearAll.title
          text: L.drawLocal.edit.toolbar.actions.clearAll.text
          callback: @_clearAllLayers
          context: @ })

      actions

)(window.Cartography = window.Cartography || {}, jQuery)
