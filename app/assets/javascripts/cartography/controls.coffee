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
      @type = @constructor.TYPE


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

  class C.Controls.LayerSelection extends C.Controls
    options:
      layerSelection:
        featureGroup: undefined

    constructor: (map, options = {}) ->
      super(map)

      L.Util.setOptions @, options

      @control = new L.Control.LayerSelection(@options.layerSelection)

      @initHooks()

    initHooks: ->
      # @getMap().on "draw:editstart", (e) =>

    getControl: ->
      @control

  class L.Control.LayerSelection extends L.Control
    @_toolbar: {}

    options:
      position: 'topleft'
      featureGroup: undefined

    constructor: (options) ->
      L.Util.setOptions @, options
      super options

      if L.LayerSelectionToolbar && !@_toolbar
        @_toolbar = new L.LayerSelectionToolbar @options

      return

    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-draw leaflet-control-layer-selection')
      topClassName = 'leaflet-draw-toolbar-top'
      toolbarContainer = @_toolbar.addToolbar(map)
      if toolbarContainer
        L.DomUtil.addClass toolbarContainer.childNodes[0], topClassName
      container.appendChild toolbarContainer
      container

    onRemove: ->
      @_toolbar.removeToolbar()

  class L.LayerSelectionToolbar extends L.Toolbar
    @TYPE: 'layerSelection'

    options:
      position: 'topleft'
      featureGroup: undefined
      # color: "#A40"
      selectedPathOptions:
        dashArray: '10, 10'
        fill: true
        fillColor: '#fe57a1'
        fillOpacity: 0.1
        maintainColor: false

    constructor: (options = {}) ->
      L.Util.setOptions @, options
      @type = @constructor.TYPE

      super @options
      this

    #Get mode handlers information
    getModeHandlers: (map) ->
      featureGroup = @options.featureGroup
      [
        {
          enabled: true
          handler: new L.LayerSelection map,
            featureGroup: featureGroup
            selectedPathOptions: @options.selectedPathOptions

          title: L.drawLocal.edit.toolbar.buttons.edit
        }
      ]

    #Get actions information
    getActions: (handler) ->
      [
        {
          title: L.drawLocal.edit.toolbar.actions.save.title
          text: L.drawLocal.edit.toolbar.actions.save.text
          callback: @_save
          context: @
        },
        {
          title: L.drawLocal.edit.toolbar.actions.cancel.title
          text: L.drawLocal.edit.toolbar.actions.cancel.text
          callback: @disable
          context: @
        }
      ]

    addToolbar: (map) ->
      container = super map

      @_checkDisabled()

      @options.featureGroup.on 'layeradd layerremove', @_checkDisabled, @

      container

    removeToolbar: ->
      @options.featureGroup.off 'layeradd layerremove', @_checkDisabled, @
      super

    disable: ->
      if !@.enabled()
        return

      super

    _save: ->
      @_activeMode.handler.save()

      if @_activeMode
        @_activeMode.handler.disable()

    _checkDisabled: ->
      featureGroup = @options.featureGroup
      hasLayers = featureGroup.getLayers().length != 0
      button = this._modes[L.LayerSelection.TYPE].button

      if hasLayers
        L.DomUtil.removeClass button, 'leaflet-disabled'
      else
        L.DomUtil.addClass button, 'leaflet-disabled'

      title = if hasLayers then L.drawLocal.edit.toolbar.buttons.edit else L.drawLocal.edit.toolbar.buttons.editDisabled

      button.setAttribute 'title', title

  L.Selectable = {}
  L.Selectable.Event = {}
  L.Selectable.Event.START = "layerSelection:start"
  L.Selectable.Event.STOP = "layerSelection:stop"
  L.Selectable.Event.SELECT = "layerSelection:select"
  L.Selectable.Event.UNSELECT = "layerSelection:unselect"
  L.Selectable.Event.SELECTED = "layerSelection:selected"

  class L.LayerSelection extends L.Handler
    @TYPE: 'LayerSelection'

    constructor: (map, options) ->
      @type = @constructor.TYPE
      @_map = map
      super map
      L.setOptions @, options
      # Store the selectable layer group for ease of access
      @_featureGroup = options.featureGroup

      if !(@_featureGroup instanceof L.FeatureGroup)
        throw new Error('options.featureGroup must be a L.FeatureGroup')

    enable: ->
      if @_enabled or !@_hasAvailableLayers()
        return

      @fire 'enabled', handler: @type

      @_map.fire L.Selectable.Event.START, handler: @type

      super

      @_featureGroup.on 'layeradd', @_enableLayerSelection, @
      @_featureGroup.on 'layerremove', @_disableLayerSelection, @
      return

    disable: ->
      if !@_enabled
        return
      @_featureGroup.off 'layeradd', @_enableLayerSelection, @
      @_featureGroup.off 'layerremove', @_disableLayerSelection, @

      super

      @_map.fire L.Selectable.Event.STOP, handler: @type

      @fire 'disabled', handler: @type
      return

    addHooks: ->
      @_featureGroup.eachLayer @_enableLayerSelection, @

    removeHooks: ->
      @_featureGroup.eachLayer @_disableLayerSelection, @

    save: ->
      selectedLayers = new L.LayerGroup
      @_featureGroup.eachLayer (layer) ->
        if layer.selected
          selectedLayers.addLayer layer
          layer.selected = false
      @_map.fire L.Selectable.Event.SELECTED, layers: selectedLayers
      return

    _enableLayerSelection: (e) ->
      layer = e.layer or e.target or e
      if @options.selectedPathOptions
        pathOptions = L.Util.extend {}, @options.selectedPathOptions
        # Use the existing color of the layer
        if pathOptions.maintainColor
          pathOptions.color = layer.options.color
          pathOptions.fillColor = layer.options.fillColor
        layer.options.original = L.extend({}, layer.options)
        layer.options.selecting = pathOptions

      layer.on('click', @_onClick)
      layer.on('touchstart', @_onClick, this)

    _disableLayerSelection: (e) ->
      layer = e.layer or e.target or e
      layer.selected = false
      # Reset layer styles to that of before select
      if @options.selectedPathOptions
        layer.setStyle layer.options.original

      layer.off('click', @_onClick)
      layer.off('touchstart', @_onClick, this)

      delete layer.options.selecting
      delete layer.options.original

    _onClick: (e) ->
      layer = e.target

      if !layer.selected
        layer.selected = true
        layer.setStyle(layer.options.selecting)
        @_map.fire L.Selectable.Event.SELECT, layer: layer
      else
        layer.selected = false
        layer.setStyle(layer.options.original)
        @_map.fire L.Selectable.Event.UNSELECT, layer: layer

    _hasAvailableLayers: ->
      @_featureGroup.getLayers().length != 0

  L.LayerSelection.include(L.Mixin.Events)

)(window.Cartography = window.Cartography || {}, jQuery)
