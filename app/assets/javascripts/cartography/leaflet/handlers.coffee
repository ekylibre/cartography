((C) ->
  "use strict"

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
      C.Util.setOptions @, options
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

)(window.Cartography = window.Cartography || {})
