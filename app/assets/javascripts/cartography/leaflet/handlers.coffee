((C) ->
  "use strict"

  L.Selectable = {}
  L.Selectable.Event = {}
  L.Selectable.Event.START = "layerSelection:start"
  L.Selectable.Event.STOP = "layerSelection:stop"
  L.Selectable.Event.SELECT = "layerSelection:select"
  L.Selectable.Event.UNSELECT = "layerSelection:unselect"
  L.Selectable.Event.SELECTED = "layerSelection:selected"


  L.SnapEditing = {}
  L.SnapEditing = {}
  L.SnapEditing.Event = {}
  L.SnapEditing.Event.START = "snapedit:start"
  L.SnapEditing.Event.STOP = "snapedit:stop"
  L.SnapEditing.Event.SELECT = "snapedit:select"
  L.SnapEditing.Event.UNSELECT = "snapedit:unselect"
  L.SnapEditing.Event.EDITED = "snapedit:edited"
  L.SnapEditing.Event.CHANGE = "snapedit:change"

  class L.LayerSelection extends L.Handler
    @TYPE: 'LayerSelection'

    options:
      selectedPathOptions:
        dashArray: '10, 10'
        fill: true
        fillColor: '#fe57a1'
        fillOpacity: 0.7
        maintainColor: false

    constructor: (map, options) ->
      @type = @constructor.TYPE
      @_map = map
      super map
      C.Util.setOptions @, options
      # Store the selectable layer group for ease of access
      @_featureGroup = options.featureGroup

      if !(@_featureGroup instanceof L.FeatureGroup)
        throw new Error('options.featureGroup must be a L.FeatureGroup')

    enable: ->
      if @_enabled
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

    _onClick: (e) =>
      layer = e.target

      if !layer.selected
        layer.selected = true
        if @options.selectedPathOptions
          pathOptions = L.Util.extend {}, @options.selectedPathOptions
          # Use the existing color of the layer
          if pathOptions.maintainColor
            pathOptions.color = layer.options.color
            pathOptions.fillColor = layer.options.fillColor
          layer.options.original = L.extend({}, layer.options)
          layer.options.selecting = pathOptions

        layer.setStyle(layer.options.selecting)
        @_map.fire L.Selectable.Event.SELECT, layer: layer
      else
        layer.selected = false

        layer.setStyle(layer.options.original)
        @_map.fire L.Selectable.Event.UNSELECT, layer: layer

    _hasAvailableLayers: ->
      @_featureGroup.getLayers().length != 0

  L.LayerSelection.include(L.Mixin.Events)


  class L.EditToolbar.SelectableSnapEdit extends L.EditToolbar.SnapEdit
    options:
      snapOptions:
        snapDistance: 15
        snapVertices: true

    constructor: (map, options) ->
      C.Util.setOptions @, options
      super map, options

      @featureGroup = @options.featureGroup

      # @featureGroup.on 'layeradd', @_enableLayer, @
      # @featureGroup.on 'layerremove', @_removeLayer, @
      @_activeLayer = undefined


      if @options.snapOptions
        L.Util.extend @snapOptions, @options.snapOptions

      if Array.isArray(@snapOptions.guideLayers)
        @_guideLayers = @snapOptions.guideLayers

      else if @options.guideLayers instanceof L.LayerGroup
        @_guideLayers = @snapOptions.guideLayers.getLayers()
      else
        @_guideLayers = []
      return

    # edit: (layer) ->
    #   @featureGroup = [layer]

    enable: ->
      @featureGroup.on 'layeradd', @_enableLayer, @
      @featureGroup.on 'layerremove', @_disableLayer, @

      @featureGroup.eachLayer (l) =>
        @_enableLayer(l)

      @_map.on L.SnapEditing.Event.SELECT, @_editMode, @
      #
  		# if (this._enabled || !this._hasAvailableLayers()) {
  		# 	return;
  		# }
  		# this.fire('enabled', { handler: this.type });
  		# //this disable other handlers
      #
  		# this._map.fire(L.Draw.Event.EDITSTART, { handler: this.type });
  		# //allow drawLayer to be updated before beginning edition.
      #
  		# L.Handler.prototype.enable.call(this);
  		# this._featureGroup
  		# 	.on('layeradd', this._enableLayerEdit, this)
      # 	.on('layerremove', this._disableLayerEdit, this)


    _enableLayer: (e) ->
      layer = e.layer or e.target or e

      layer.options.original = L.extend({}, layer.options)

      if @options.disabledPathOptions
        pathOptions = L.Util.extend {}, @options.disabledPathOptions

        # Use the existing color of the layer
        if pathOptions.maintainColor
          pathOptions.color = layer.options.color
          pathOptions.fillColor = layer.options.fillColor

        layer.options.disabled = pathOptions

      if @options.selectedPathOptions
        pathOptions = L.Util.extend {}, @options.selectedPathOptions

        # Use the existing color of the layer
        if pathOptions.maintainColor
          pathOptions.color = layer.options.color
          pathOptions.fillColor = layer.options.fillColor

        layer.options.snapSelected = pathOptions

      layer.setStyle layer.options.disabled

      layer.on 'click', @_activate, @

    _activate: (e) ->
      layer = e.target || e.layer || e

      if !layer.snapSelected
        layer.snapSelected = true
        layer.setStyle layer.options.snapSelected

        if @_activeLayer
          @_unselectLayer @_activeLayer

        @_activeLayer = layer

        @_map.fire L.SnapEditing.Event.SELECT, layer: @_activeLayer
      else
        layer.snapSelected = false
        layer.setStyle(layer.options.disabled)

        @_activeLayer = null
        @_map.fire L.SnapEditing.Event.UNSELECT, layer: layer

    _unselectLayer: (e) ->
      layer = e.layer or e.target or e
      layer.snapSelected = false
      if @options.selectedPathOptions
        layer.setStyle layer.options.disabled

      # if layer.merging
        # layer.merging.disable()
        # delete layer.merging

      # @_map.on 'mousemove', @_selectLayer, @

      @_activeLayer = null

    _disableLayer: (e) ->
      layer = e.layer or e.target or e
      layer.snapSelected = false
      # Reset layer styles to that of before select
      if @options.selectedPathOptions
        layer.setStyle layer.options.original

      delete layer.options.disabled
      delete layer.options.selected
      delete layer.options.original

    _editMode: (e) ->
      layer = e.layer
      if(layer.editing)
        if layer.editing._poly.editing._verticesHandlers
          layer.editing._poly.editing._verticesHandlers[0]._markerGroup.clearLayers()
        delete layer.editing
      layer.editing = layer.snapediting = new L.Handler.PolylineSnap(layer._map, layer, @options.snapOptions)
      layer.editing.enable()

      layer.editing._poly.on 'editdrag', (e) ->
        layer = e.target
        layer._map.fire L.SnapEditing.Event.CHANGE, layer: layer


      # @_enableLayerEdit(e)

    #
    # addGuideLayer: (layer) ->
    #   index = @_guideLayers.findIndex((guideLayer) ->
    #     L.stamp(layer) == L.stamp(guideLayer)
    #   )
    #   if index == -1
    #     @_guideLayers.push layer
    #     @_featureGroup.eachLayer (layer) ->
    #       if layer.snapediting
    #         layer.snapediting._guides.push layer
    #       return
    #   return
    # removeGuideLayer: (layer) ->
    #   index = @_guideLayers.findIndex((guideLayer) ->
    #     L.stamp(layer) == L.stamp(guideLayer)
    #   )
    #   if index != -1
    #     @_guideLayers.splice index, 1
    #     @_featureGroup.eachLayer (layer) ->
    #       if layer.snapediting
    #         layer.snapediting._guides.splice index, 1
    #       return
    #   return
    # clearGuideLayers: ->
    #   @_guideLayers = []
    #   @_featureGroup.eachLayer (layer) ->
    #     if layer.snapediting
    #       layer.snapediting._guides = []
    #     return
    #   return
    #
    # _enableLayerEdit: (e) ->
    #   super e
    #
    #   layer = e.layer or e.target or e
    #
    #   if !layer.snapediting
    #     if layer.hasOwnProperty('_mRadius')
    #       if layer.editing
    #         layer.editing._markerGroup.clearLayers()
    #         delete layer.editing
    #       layer.editing = layer.snapediting = new (L.Handler.CircleSnap)(layer._map, layer, @snapOptions)
    #     else if layer.getLatLng
    #       layer.snapediting = new (L.Handler.MarkerSnap)(layer._map, layer, @snapOptions)
    #     else
    #       if layer.editing
    #         if layer.editing.hasOwnProperty('_shape')
    #           layer.editing._markerGroup.clearLayers()
    #           if layer.editing._shape instanceof L.Rectangle
    #             delete layer.editing
    #             layer.editing = layer.snapediting = new (L.Handler.RectangleSnap)(layer._map, layer, @snapOptions)
    #           else if layer.editing._shape instanceof L.FeatureGroup
    #             delete layer.editing
    #             layer.editing = layer.snapediting = new (L.Handler.FeatureGroupSnap)(layer._map, layer, @snapOptions)
    #           else
    #             delete layer.editing
    #             layer.editing = layer.snapediting = new (L.Handler.CircleSnap)(layer._map, layer, @snapOptions)
    #         else
    #           # layer.editing._markerGroup.clearLayers();
    #           # layer.editing._verticesHandlers[0]._markerGroup.clearLayers();
    #           layer.editing._poly.editing._verticesHandlers[0]._markerGroup.clearLayers()
    #           delete layer.editing
    #           layer.editing = layer.snapediting = new (L.Handler.PolylineSnap)(layer._map, layer, @snapOptions)
    #       else
    #         layer.editing = layer.snapediting = new (L.Handler.PolylineSnap)(layer._map, layer, @snapOptions)
    #     i = 0
    #     n = @_guideLayers.length
    #     while i < n
    #       layer.snapediting.addGuideLayer @_guideLayers[i]
    #       i++
    #   layer.snapediting.enable()
    #   return

)(window.Cartography = window.Cartography || {})
