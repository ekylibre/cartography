((C) ->
  "use strict"

  class L.Control.Home extends L.Control
    options:
      position: 'topleft'
      featureGroup: null

    constructor: (options) ->
      C.Util.setOptions @, options
      super options

      if L.HomeToolbar && !@_toolbar
        @_toolbar = new L.HomeToolbar @options

    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-draw leaflet-control-cut')
      topClassName = 'leaflet-draw-toolbar-top'
      toolbarContainer = @_toolbar.addToolbar(map)
      if toolbarContainer
        L.DomUtil.addClass toolbarContainer.childNodes[0], topClassName
      container.appendChild toolbarContainer
      container

    onRemove: ->
      @_toolbar.removeToolbar()

  class L.Control.SnapEdit extends L.Control
    options:
      position: 'topleft'
      draw: {}
      edit:
        panel:
          position: 'bottomleft'

    constructor: (options) ->
      C.Util.setOptions @, options
      super options
      toolbar = undefined
      @_toolbar = {}
      if L.SnapEditToolbar
        @options.snap.guideLayers = @options.snap.polygon.guideLayers

        @_toolbar = new L.SnapEditToolbar @options

      if @options.edit.panel
        new L.Control.ControlPanel.SnapEdit @_toolbar, @options.edit.panel

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

  class L.Control.ControlPanel.SnapEdit extends L.Control.ControlPanel
    constructor: (options) ->
      C.Util.setOptions @, options
      super

    onAdd: (map) ->
      super map

      @_container

    addProperties: ->
      super
      @_addEditPolygon()

    _addEditPolygon: ->
      container = L.DomUtil.create 'div', 'property', @_propertiesContainer

      containerTitle = L.DomUtil.create 'div', 'property-title', container
      containerTitle.innerHTML = @options.surfaceProperty

      @_areaContainer = L.DomUtil.create 'div', 'property-content', container

      @_onEditingPolygon()
      @_map.on L.ReactiveMeasure.Edit.Event.MOVE, @_onEditingPolygon, @

    _onEditingPolygon: (e) ->
      area = if e and e.measure then e.measure.area else 0

      L.DomUtil.empty(@_areaContainer)

      surface = L.DomUtil.create 'div', 'surface-row', @_areaContainer
      surface.innerHTML = L.GeometryUtil.readableArea(area, true)

  class L.Control.LayerSelection extends L.Control
    @_toolbar: {}

    options:
      position: 'topleft'
      featureGroup: undefined

    constructor: (map, options) ->
      C.Util.setOptions @, options
      super options

      @_handler = new L.LayerSelection map, featureGroup: @options.featureGroup

      return

    enable: ->
      @_handler.enable()

  class L.Control.LayerLocking extends L.Control
    @_toolbar: {}

    options:
      position: 'topleft'
      featureGroup: undefined

    constructor: (map, options) ->
      C.Util.setOptions @, options
      super options

      @_handler = new L.LayerLocking map, featureGroup: @options.featureGroup

      return

    enable: ->
      @_handler.enable()

  class L.Control.Cut extends L.Control
    @_toolbar: {}

    options:
      position: 'topleft'
      featureGroup: undefined
      panel:
        position: 'bottomleft'

    constructor: (options) ->
      C.Util.setOptions @, options
      super options

      if L.CutToolbar && !@_toolbar
        @_toolbar = new L.CutToolbar @options

      if @options.panel
        new L.Control.ControlPanel.Cut @_toolbar, @options.panel

    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-draw leaflet-control-cut')
      topClassName = 'leaflet-draw-toolbar-top'
      toolbarContainer = @_toolbar.addToolbar(map)
      if toolbarContainer
        L.DomUtil.addClass toolbarContainer.childNodes[0], topClassName
      container.appendChild toolbarContainer
      container

    onRemove: ->
      @_toolbar.removeToolbar()

  class L.Control.ControlPanel.Cut extends L.Control.ControlPanel
    constructor: (options) ->
      C.Util.setOptions @, options
      super

    onAdd: (map) ->
      super map
      @_container

    addProperties: ->
      @_addSubtitle() if @options.subtitleProperty
      super
      @_map.on L.Cutting.Polyline.Event.CREATED, @_addCreatedPolygons, @

    _addSubtitle: ->
      container = L.DomUtil.create 'div', 'property', @_propertiesContainer
      containerTitle = L.DomUtil.create 'div', 'property-title', container
      containerTitle.innerHTML = @options.subtitleProperty

    _addCreatedPolygons: (e) ->

      container = L.DomUtil.create 'div', 'property', @_propertiesContainer

      containerTitle = L.DomUtil.create 'div', 'property-title', container
      containerTitle.innerHTML = @options.surfacesProperty

      @_areaContainer = L.DomUtil.create 'div', 'property-content', container

      @_onUpdateArea(e)

      @_map.on L.Cutting.Polyline.Event.UPDATED, @_onUpdateArea, @

    _onUpdateArea: (e) ->
      layers = e.layers

      L.DomUtil.empty(@_areaContainer)

      for layer in layers
        if layer
          legendRow = L.DomUtil.create 'div', 'legend-row', @_areaContainer
          legend = L.DomUtil.create 'div', 'legend', legendRow
          area = L.DomUtil.create("div", 'legend-area', legendRow)
          # layer.options.fillColor

          if typeof layer.getLatLngs is 'function'
            legend.style.backgroundColor = layer.options.fillColor
            latlngs = layer.getLatLngs()
          else
            legend.style.backgroundColor = layer.getLayers()[0].options.fillColor
            latlngs = layer.getLayers()[0].getLatLngs()

          area.innerHTML = L.GeometryUtil.readableArea(L.GeometryUtil.geodesicArea(latlngs[0]), true)


  class L.Control.ControlPanel.Draw extends L.Control.ControlPanel
    constructor: (options) ->
      C.Util.setOptions @, options
      super

    onAdd: (map) ->
      super map
      @_container

    addProperties: ->
      super
      @_addDrawingPolygon()

    _addDrawingPolygon: ->

      container = L.DomUtil.create 'div', 'property', @_propertiesContainer

      containerTitle = L.DomUtil.create 'div', 'property-title', container
      containerTitle.innerHTML = "Surface"

      @_areaContainer = L.DomUtil.create 'div', 'property-content', container

      @_onDrawingPolygon()
      @_map.on L.ReactiveMeasure.Draw.Event.MOVE, @_onDrawingPolygon, @

    _onDrawingPolygon: (e) ->
      area = if e and e.measure then e.measure.area else 0

      L.DomUtil.empty(@_areaContainer)

      surface = L.DomUtil.create 'div', 'surface-row', @_areaContainer
      surface.innerHTML = L.GeometryUtil.readableArea(area, true)

  class L.Control.Merge extends L.Control
    @_toolbar: {}

    options:
      position: 'topleft'
      featureGroup: undefined
      panel:
        position: 'bottomleft'

    constructor: (options) ->
      C.Util.setOptions @, options
      super options

      if L.MergeToolbar && !@_toolbar
        @_toolbar = new L.MergeToolbar @options

      if @options.panel
        new L.Control.ControlPanel.Merge @_toolbar, @options.panel

    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-draw leaflet-control-merge')
      topClassName = 'leaflet-draw-toolbar-top'
      toolbarContainer = @_toolbar.addToolbar(map)
      if toolbarContainer
        L.DomUtil.addClass toolbarContainer.childNodes[0], topClassName
      container.appendChild toolbarContainer
      container

    onRemove: ->
      @_toolbar.removeToolbar()


  class L.Control.ControlPanel.Merge extends L.Control.ControlPanel
    constructor: (options) ->
      C.Util.setOptions @, options
      super

    onAdd: (map) ->
      super map
      @_container

    addProperties: ->
      super
      # @_map.on L.Cutting.Polyline.Event.CREATED, @_addCreatedPolygons, @

    _addCreatedPolygons: (e) ->

      container = L.DomUtil.create 'div', 'property', @_propertiesContainer

      containerTitle = L.DomUtil.create 'div', 'property-title', container
      containerTitle.innerHTML = "Surfaces"

      @_areaContainer = L.DomUtil.create 'div', 'property-content', container

      @_onUpdateArea(e)

      @_map.on L.Cutting.Polyline.Event.UPDATED, @_onUpdateArea, @

    _onUpdateArea: (e) ->
      layers = e.layers

      L.DomUtil.empty(@_areaContainer)

      for layer in layers
        legendRow = L.DomUtil.create 'div', 'legend-row', @_areaContainer
        legend = L.DomUtil.create 'div', 'legend', legendRow
        area = L.DomUtil.create("div", 'legend-area', legendRow)
        # layer.options.fillColor

        if typeof layer.getLatLngs is 'function'
          legend.style.backgroundColor = layer.options.fillColor
          latlngs = layer.getLatLngs()
        else
          legend.style.backgroundColor = layer.getLayers()[0].options.fillColor
          latlngs = layer.getLayers()[0].getLatLngs()

        area.innerHTML = L.GeometryUtil.readableArea(L.GeometryUtil.geodesicArea(latlngs[0]), true)


  class L.Control.ShapeDraw extends L.Control
    options:
      featureGroup: undefined
      snapDistance: 15
      shapeOptions:
        color: '#FF6226'
        className: 'leaflet-polygon-drawer'

    constructor: (map, options) ->
      C.Util.setOptions @, options
      super options

      @_handler = new L.Draw.Polygon map, @options

      @_map = map
      return

    _onDrawVertex: (e) ->
      @_map.fire C.Events.shapeDraw.start
      @_map.off "draw:drawvertex", @_onDrawVertex, @

    _onDrawingPolygon: (e) ->
      measure = {
        area: e.measure.extrapolatedArea,
        perimeter: if @_handler._poly.getLatLngs().length == 1 then e.measure.perimeter else e.measure.extrapolatedPerimeter
      }
      @_map.fire C.Events.shapeDraw.draw, data: { measure: measure }

    _onInvalidDrawingPolygon: (e) ->
      @_map.fire C.Events.shapeDraw.warn, data: { message: e.error }

    enable: ->
      @_map.on "draw:drawvertex", @_onDrawVertex, @
      @_map.on L.ReactiveMeasure.Draw.Event.MOVE, @_onDrawingPolygon, @
      @_map.on L.Draw.Event.INVALIDATED, @_onInvalidDrawingPolygon, @
      @_handler.enable()

    disable: ->
      @_map.off "draw:drawvertex", @_onDrawVertex, @
      @_map.off L.ReactiveMeasure.Draw.Event.MOVE, @_onDrawingPolygon, @
      @_map.off L.Draw.Event.INVALIDATED, @_onInvalidDrawingPolygon, @
      @_handler.disable()

  class L.Control.ShapeCut extends L.Control
    options:
      featureGroup: undefined
      disabledPathOptions:
        dashArray: null
        fill: true
        color: '#263238'
        fillColor: '#263238'
        opacity: 1
        fillOpacity: 0.4
        maintainColor: false
      editablePathOptions:
        dashArray: null
        fill: true
        color: '#1195F5'
        fillColor: '#1195F5'
        opacity: 1
        fillOpacity: 0.35
        maintainColor: false
      selectedPathOptions:
        dashArray: null
        fill: true
        fillColor: '#fe57a1'
        opacity: 1
        fillOpacity: 1
        maintainColor: true
        weight: 3
      cuttingPathOptions:
        color: '#FF6226'
        className: 'leaflet-polygon-splitter'
      cycling: 2

    constructor: (map, options) ->
      C.Util.setOptions @, options
      super options

      @_handler = new L.Cut.Polyline map, @options

      @_map = map
      return

    enable: ->
      @_handler.enable()

    disable: ->
      @_handler.disable()

)(window.Cartography = window.Cartography || {})
