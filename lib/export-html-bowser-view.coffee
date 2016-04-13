{View, $} = require "atom-space-pen-views"
module.exports =
  class ExportHtmlBrowserView extends View
    @content: (params, self) ->
      @div style:"height:100%;width:0px", =>
        @tag "webview", id:"epreview", outlet:"epreview", src:params.src, nodeintegration:"on", style:"display: inline-block "

    initialize: (params, self) ->
      @self = self

    attached: (onDom) ->
      @epreview[0].addEventListener "did-finish-load", (evt) =>
        @epreview[0].print()
        @self.panelHide()

    loadURL: (path) ->
      @epreview[0].src = path
