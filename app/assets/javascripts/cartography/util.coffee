((C, $, _) ->
  "use strict"

  class C.Util

    #Leaflet inspiration, but provides object deep merging
    @extend: (dest, src) ->
      _.merge(dest, src)

    @setOptions = (obj, options) ->
      if !obj.hasOwnProperty 'options'
        obj.options = if obj.options then L.Util.create(obj.options) else {}
      @extend obj.options, options

  C.extend = C.Util.extend
  C.setOptions = C.Util.setOptions

)(window.Cartography = window.Cartography || {}, jQuery, _)
