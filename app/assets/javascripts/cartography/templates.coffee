((C, $) ->
  "use strict"
  C.templates = {
    importModalForm: (url, formats) ->

      radioButtons = formats.map (format,i) -> 
        "<div class='choice-padding'>
            <input
              type='radio'
              name='importer_format'
              id='importer_format_#{format}'
              value='#{format}'
              checked='#{i == 0 && 'checked'}
            />
            <label for='importer_format_#{format}'>#{format}</label>
         </div>   "

      "<form data-importer-form='true'
        enctype='multipart/form-data'
        action='#{url}'
        accept-charset='UTF-8'
        data-remote='true'
        method='post'
        >
        <div id='alert' class='row alert-danger'></div>
        <div class='row'>
            
              #{radioButtons.join('')}
            
        </div>
        <div class='row'>
            <input type='file' name='import_file' id='import_file' /><span
            class='spinner-loading'
            data-importer-spinner='true'
            ><i></i
            ></span>
        </div>
        </form>"


  }
)(window.Cartography = window.Cartography || {}, jQuery)