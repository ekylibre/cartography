((C, $) ->
  class L.Control.Importer extends L.Control.EasyButton
    constructor: (map, options) ->
      C.Util.setOptions @, options
      super "<i class='leaflet-importer-ctrl' title='#{this.options.buttonTitle}'></i>", @_buttonCallback
    
    _buttonCallback: ->
      modalOptions = {
        title: this.options.title
        onShow: (evt) =>
          modal = evt.modal
          map = evt.target
          self = this

          formats = ['gml', 'kml', 'geojson'].map (format) ->
                      format if self.options[format]
          
          content = C.templates.importModalForm(this.options.url, formats)
          $(modal._getInnerContentContainer()).find('.modal-body').empty()
          $(modal._getInnerContentContainer()).find('.modal-body').append($(content))
          modal.update()

          $('*[data-editor-submit]', modal._container).on 'click', (e) ->
            $(modal._container).find('form[data-importer-form]').submit()
            e.preventDefault
            return false

          $('*[data-editor-cancel]', modal._container).on 'click', (e) =>
            e.preventDefault
            modal.hide()
            return false

          $('form[data-importer-form]', modal._container).submit ->
            $(this).find('[data-importer-spinner]').addClass('active')

          $(modal._container).on 'ajax:complete','form[data-importer-form]', (e,data) =>

            feature = $.parseJSON(data.responseText)
            $(e.currentTarget).find('[data-importer-spinner]').removeClass('active')

            if feature.alert?
              $(modal._container).find('#alert').text(feature.alert)
            else
              modal.hide()
              map.fire "importer:complete", { importedFeature: feature }

        onHide: (evt) ->
          modal = evt.modal
          $('*[data-editor-submit], *[data-editor-cancel]', modal._container).off 'click'

      }
      @_map.fire 'modal', $.extend(true, {}, this.options, modalOptions )

)(window.Cartography = window.Cartography || {}, jQuery)
