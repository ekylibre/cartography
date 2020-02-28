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
        disabledPathOptions:
          dashArray: null
          fill: true
          fillColor: '#fe57a1'
          fillOpacity: 0.1
          maintainColor: true
      remove: {}
      poly: null
      featureGroup: null

    constructor: (options = {}) ->
      C.Util.setOptions @, options
      @type = @constructor.TYPE

      # fallback for toolbar
      @options.featureGroup = @options.edit.featureGroup


      super @options
      @_selectedFeatureCount = 0
      this

    #Get mode handlers information
    getModeHandlers: (map) ->
      featureGroup = @options.featureGroup
      [
        {
          enabled: @options.edit
          handler: new L.EditToolbar.SelectableSnapEdit map,
            snapOptions: @options.snap
            featureGroup: featureGroup
            selectedPathOptions: @options.edit.selectedPathOptions
            disabledPathOptions: @options.edit.disabledPathOptions
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

  class L.HomeToolbar extends L.Toolbar
    @TYPE: 'home'

    options:
      position: 'topleft'
      featureGroup: null

    constructor: (options = {}) ->
      C.Util.setOptions @, options
      @type = @constructor.TYPE
      @_toolbarClass = 'leaflet-home'

      super @options
      this

    #Get mode handlers information
    getModeHandlers: (map) ->
      [
        {
          enabled: true
          handler: new L.Home map, @options
          title: L.drawLocal.home.toolbar.buttons.home
        }
      ]

    #Get actions information
    getActions: (handler) ->
      []

    addToolbar: (map) ->
      container = super map

      @_checkDisabled()

      @options.featureGroup.on 'layeradd layerremove', @_checkDisabled, @

      container

    removeToolbar: ->
      @options.featureGroup.off 'layeradd layerremove', @_checkDisabled, @
      super

    _checkDisabled: ->
      featureGroup = @options.featureGroup
      hasLayers = featureGroup.getLayers().length != 0
      button = this._modes[L.Home.TYPE].button

      if hasLayers
        L.DomUtil.removeClass button, 'leaflet-hidden'
      else
        L.DomUtil.addClass button, 'leaflet-hidden'

  class L.CutToolbar extends L.Toolbar
    @TYPE: 'cut'

    options:
      position: 'topleft'
      featureGroup: undefined
      # color: "#A40"
      disabledPathOptions:
        dashArray: null
        fill: true
        color: '#263238'
        fillColor: '#263238'
        opacity: 1
        fillOpacity: 0.4
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
        #dashArray: '10, 10'
        #fill: true
        # color: '#3f51b5'
        # fillOpacity: 0.9
        #maintainColor: true
      #snap:
        #guideLayers: []
        #snapDistance: 30
        #allowIntersection: false
        #guidelineDistance: 8
        #shapeOptions:
          #dashArray: '8, 8'
          #fill: false
          #color: '#FF5722'
          #opacity: 1

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

          title: L.drawLocal.split.toolbar.buttons.cutPolyline
        }
      ]

    #Get actions information
    getActions: (handler) ->
      [
        {
          title: L.drawLocal.split.toolbar.actions.save.title
          text: L.drawLocal.split.toolbar.actions.save.text
          callback: @_save
          context: @
        },
        {
          title: L.drawLocal.split.toolbar.actions.cancel.title
          text: L.drawLocal.split.toolbar.actions.cancel.text
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
      if !@enabled()
        return

      @_activeMode.handler.disable()

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

      title = if hasLayers then L.drawLocal.split.toolbar.buttons.cutPolyline else L.drawLocal.edit.toolbar.buttons.editDisabled

      button.setAttribute 'title', title


  class L.MergeToolbar extends L.Toolbar
    @TYPE: 'merge'

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
      mergingPathOptions:
        dashArray: '10, 10'
        fill: true
        color: '#3f51b5'
        # fillOpacity: 0.9
        maintainColor: false

    constructor: (options = {}) ->
      C.Util.setOptions @, options
      @type = @constructor.TYPE
      @_toolbarClass = 'leaflet-merge'

      super @options
      this

    #Get mode handlers information
    getModeHandlers: (map) ->
      [
        {
          enabled: true
          handler: new L.Merge map, @options

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
      button = this._modes[L.Merge.TYPE].button

      if hasLayers
        L.DomUtil.removeClass button, 'leaflet-disabled'
      else
        L.DomUtil.addClass button, 'leaflet-disabled'

      title = if hasLayers then L.drawLocal.edit.toolbar.buttons.edit else L.drawLocal.edit.toolbar.buttons.editDisabled

      button.setAttribute 'title', title

  class L.OffsetPolygonToolbar extends L.Toolbar
    @TYPE: 'offsetPolygon'

    options:
      position: 'topleft'
      featureGroup: undefined
      # color: "#A40"
      className:"hello"
      disabledPathOptions:
        dashArray: null
        fill: true
        color: '#263238'
        fillColor: '#263238'
        opacity: 1
        fillOpacity: 0.4
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
        #dashArray: '10, 10'
        #fill: true
        # color: '#3f51b5'
        # fillOpacity: 0.9
        #maintainColor: true
      #snap:
        #guideLayers: []
        #snapDistance: 30
        #allowIntersection: false
        #guidelineDistance: 8
        #shapeOptions:
          #dashArray: '8, 8'
          #fill: false
          #color: '#FF5722'
          #opacity: 1

    constructor: (options = {}) ->
      C.Util.setOptions @, options
      @type = @constructor.TYPE
      @_toolbarClass = 'leaflet-toolbar'

      super @options
      this

    #Get mode handlers information
    getModeHandlers: (map) ->
      [
        {
          enabled: true
          handler: new L.Edit.OffsetPolygon map, @options

          title: "Editer les tournières"
        }
      ]

    #Get actions information
    getActions: (handler) ->
      [
        {
          type: "handlerAction"
          title: L.drawLocal.split.toolbar.actions.save.title
          text: L.drawLocal.split.toolbar.actions.save.text
          callback: @_save
          context: @
        },
        {
          type: "handlerAction"
          title: L.drawLocal.split.toolbar.actions.cancel.title
          text: L.drawLocal.split.toolbar.actions.cancel.text
          callback: @disable
          context: @
        },
        {
          type: "handlerFormAction"
          title: "update"
          text:  "update"
          callback: @_updateSegmentsOffset
          context: @
        },
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
      if !@enabled()
        return

      @_activeMode.handler.disable()

    _save: ->
      @_activeMode.handler.save()

      if @_activeMode
        @_activeMode.handler.disable()
    
    _updateSegmentsOffset: (e) ->
      e.preventDefault();
      offsetValue = parseFloat($(e.srcElement).parent().find('input')[0].value)
      @_activeMode.handler.updateSegmentsOffset(offsetValue)

    _checkDisabled: ->
      featureGroup = @options.featureGroup
      hasLayers = featureGroup.getLayers().length != 0
      button = this._modes['offsetPolygon'].button

      if hasLayers
        L.DomUtil.removeClass button, 'leaflet-disabled'
      else
        L.DomUtil.addClass button, 'leaflet-disabled'

      title = if hasLayers then L.drawLocal.split.toolbar.buttons.cutPolyline else L.drawLocal.edit.toolbar.buttons.editDisabled

      button.setAttribute 'title', title

)(window.Cartography = window.Cartography || {})
