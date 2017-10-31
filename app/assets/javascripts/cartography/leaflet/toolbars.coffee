((C) ->
  "use strict"

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
      C.Util.setOptions @, options
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
      C.Util.setOptions @, options
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


  class L.CutToolbar extends L.Toolbar
    @TYPE: 'cut'

    options:
      position: 'topleft'
      featureGroup: undefined
      # color: "#A40"
      disabledPathOptions:
        dashArray: null
        fill: true
        fillColor: '#fe57a1'
        fillOpacity: 0.1
        maintainColor: true
      selectedPathOptions:
        dashArray: null
        fill: true
        fillColor: '#fe57a1'
        fillOpacity: 0.9
        maintainColor: true
      cuttingPathOptions:
        dashArray: '10, 10'
        fill: true
        color: '#3f51b5'
        # fillOpacity: 0.9
        maintainColor: false
      snap:
        guideLayers: []
        snapDistance: 30
        allowIntersection: false
        guidelineDistance: 8
        shapeOptions:
          dashArray: '8, 8'
          fill: false
          color: '#FF5722'
          opacity: 1

    constructor: (options = {}) ->
      C.Util.setOptions @, options
      @type = @constructor.TYPE
      @_toolbarClass = 'leaflet-cut-polyline'

      super @options
      this

    #Get mode handlers information
    getModeHandlers: (map) ->
      [
        {
          enabled: true
          handler: new L.Cut.Polyline map, @options

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
      button = this._modes[L.Cut.Polyline.TYPE].button

      if hasLayers
        L.DomUtil.removeClass button, 'leaflet-disabled'
      else
        L.DomUtil.addClass button, 'leaflet-disabled'

      title = if hasLayers then L.drawLocal.edit.toolbar.buttons.edit else L.drawLocal.edit.toolbar.buttons.editDisabled

      button.setAttribute 'title', title

)(window.Cartography = window.Cartography || {})
