ExportHtmlBrowserView = require "./export-html-bowser-view"
{CompositeDisposable} = require 'atom'
os = require "os"
path = require "path"
{exec} = require 'child_process'
Shell = require 'shell'
_ = require 'underscore-plus'
aliases = require './aliases'

module.exports = ExportHtml =
  preview: null
  subscriptions: null

  # config:
  #   fontSize:
  #     type: "integer"
  #     default: 12
  #   openBrowser:
  #     type: "boolean"
  #     default: true
  #   style:
  #     type: "string"
  #     default: "github"
  #     tilte: "Stylesheet"
  #     description: "Choose from [highlight.js styles.](https://github.com/isagalaev/highlight.js/tree/master/src/styles) ."
  #   lineNumber:
  #     type: "object"
  #     properties:
  #       use:
  #         type: "boolean"
  #         default: true
  #       styles:
  #         type: "string"
  #         title: "StyleSheet"
  #         default: "opacity: 0.5;"


  activate: ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'export-html:export': => @export()

  deactivate: ->
    @subscriptions.dispose()
    @preview = null
    @previewPanel.destroy()

  export: ->
    editor = atom.workspace.getActiveTextEditor()
    tmpdir = os.tmpdir()
    return unless editor?
    title = editor.getTitle() || 'untitled'
    tmpfile = path.join(tmpdir, title + ".html")
    text = editor.getText()
    html = @getHtml(editor, title, tmpfile, (path, contents) =>
      fs = require 'fs'
      fs.writeFileSync(path, contents, "utf8")
      openIn = atom.config.get("export-html.openIn")
      if openIn is "atom"
        @openPreview path
      else if openIn is "browser"
        @openPath path
    )

  panelHide: ->
    @previewPanel.hide()

  openPreview: (path) ->
    params = {}
    params.src = path
    if @preview?
      @previewPanel.show()
      @preview.loadURL params.src
    else
      @preview = new ExportHtmlBrowserView(params, this)
      @previewPanel = atom.workspace.addRightPanel(item:atom.views.getView(@preview))

  openPath: (filePath) ->
    # http://atomio.discourse.org/t/how-do-you-get-file-path/8693/7
    process_architecture = process.platform
    switch process_architecture
      when 'darwin' then exec ('open "'+filePath+'"')
      when 'linux' then exec ('xdg-open "'+filePath+'"')
      when 'win32' then Shell.openExternal('file:///'+filePath)

  getHtml: (editor, title, path, cb) ->
    grammar = editor.getGrammar()
    text = editor.getText()
    style = ""
    if grammar.scopeName is "source.gfm"
      roaster = require "roaster"
      roaster(text, {isFile: false}, (err, contents) =>
        html = @buildHtml(contents)
        cb(path, html)
      )
    else if grammar.scopeName is "text.html.basic"
      html = text
      cb(path, html)
    else
      language = title?.split(".")?.pop() || grammar.scopeName?.split(".").pop()
      body = @buildBodyByCode _.escape(text), language
      html = @buildHtml body, language
      cb(path, html)

  resolveAliase: (language) ->
    table = {}
    aliases.table
      .split("\n")
      .map((l) -> l.split(/,\s?/))
      .forEach (l) ->
        l.forEach (d) ->
          table[d] = l[0]

    return table[language];

  buildHtml: (body, language) ->
    language = @resolveAliase(language)
    style = atom.config.get("export-html.style")
    highlightjs = "https://rawgithub.com/highlightjs/cdn-release/master/build"
    css = "#{highlightjs}/styles/#{style}.min.css"
    js = "#{highlightjs}/highlight.min.js"
    lang = "#{highlightjs}/languages/#{language}.min.js"
    html = """
    <html>
    <head>
      <meta charset="UTF-8">
      <script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
      <link rel="stylesheet" href="#{css}">
      <script src="#{js}"></script>
      <script src="#{lang}"></script>
      <style>
        body {
          margin: 0px;
          padding: 15px;
          font-size: #{atom.config.get("export-html.fontSize")}
        }
        .hljs {
          margin: -15px;
          word-wrap: break-word;
        }
        body, .hljs {
          font-family: #{atom.config.get("editor.fontFamily")};
        }
        .number {
          float:left;
          text-align: right;
          display: inline-block;
          margin-right: 5px;
        }
        .ln {
          #{atom.config.get("export-html.lineNumber.styles")}
        }
        pre {
          tab-size:      #{atom.config.get("export-html.tabWidth")};
        }
      </style>
    </head>
    <body>
    #{body}
    </body>
    </html>
    """
    return html

  buildBodyByCode: (text, language) ->
    lines = text.split(/\r?\n/)
    width = if lines.length.toString().split("").length > 3 then "40" else "20"
    text = lines.map( (l, i) =>
      return "<span class=\"number\"><span>#{i + 1}</span></span><span class=\"code\">#{l}</span>"
    ).join("\n") if atom.config.get("export-html.lineNumber.use")

    body = """
    <pre><code class="#{language}">
    #{text}
    </code></pre>
    <script>hljs.initHighlightingOnLoad();</script>
    <script>
      setTimeout(function() {
        $(".number").css("width", "#{width}px");
        $(".number span").attr("class", "ln hljs-subst");
        resize();
        var timer = false;
        $(window).resize(function() {
          if (timer !== false) {
            clearTimeout(timer);
          }
          timer = setTimeout(function() {
            resize();
          }, 200);
        })

      }, 100);
      function resize() {
        $("span.code").each(function(i, c) {
          var h = $(c).height();
          $(c).prev().height(h);
        });
      }
    </script>
    """
    return body
