define [
  "underscore"
  "backbone"
  "common/logging"
  "./remote_data_source"
], (_, Backbone, Logging, RemoteDataSource) ->

  logger = Logging.logger

  #maybe generalize to ajax data source later?
  class AjaxDataSource extends RemoteDataSource.RemoteDataSource
    type: 'AjaxDataSource'
    destroy : () =>
      if @interval?
        clearInterval(@interval)

    setup : (plot_view, glyph) =>
      @pv = plot_view
      @get_data()
      if @get('polling_interval')
        @interval = setInterval( @get_data, @get('polling_interval'), @get('mode'), @get('max_size'), @get('if_modified'))

    get_data : (mode="replace", max_size=0, if_modified=false) =>
      $.ajax(
        dataType: 'json'
        ifModified: if_modified
        url : @get('data_url')
        xhrField :
          withCredentials : true
        method : @get('method')
        contentType : 'application/json'
      ).done((data) =>
        if mode == 'replace'
          @set('data', data)
        else if mode == 'append'
          original_data = @get('data')
          for column in @columns()
            data[column] = original_data[column].concat(data[column])[-max_size..]
          @set('data', data)
        else
          console.error("unsupported mode: " + mode)
        console.log(data)
        return null
      ).error(() =>
        console.log(arguments)
      )
      return null

  class AjaxDataSources extends Backbone.Collection
    model: AjaxDataSource
    defaults:
      url : ""
      expr : null

  return {
    "Model": AjaxDataSource
    "Collection": new AjaxDataSources()
  }
