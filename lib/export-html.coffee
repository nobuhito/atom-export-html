{CompositeDisposable} = require 'atom'
os = require "os"
path = require "path"
{exec} = require 'child_process'
Shell = require 'shell'
_ = require 'underscore-plus'

module.exports = ExportHtml =
  subscriptions: null

  config:
    fontSize:
      type: "integer"
      default: 12
    openBrowser:
      type: "boolean"
      default: true
    style:
      type: "string"
      default: "github"
      tilte: "Stylesheet"
      description: "Choose from [highlight.js styles.](https://github.com/isagalaev/highlight.js/tree/master/src/styles) ."

  activate: ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'export-html:export': => @export()

  deactivate: ->
    @subscriptions.dispose()

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
      @openPath path if atom.config.get("export-html.openBrowser") is true
    )

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
      language  = title?.split(".")?.pop() || grammar.scopeName?.split(".").pop()
      body = @buildBodyByCode _.escape(text), language
      html = @buildHtml body
      cb(path, html)

  buildHtml: (body) ->
    style = atom.config.get("export-html.style")
    css = "http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.7/styles/#{style}.min.css"
    js = "http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.7/highlight.min.js"
    html = """
    <html>
    <head>
      <meta charset="UTF-8">
      <link rel="stylesheet" href="#{css}">
      <script src="#{js}"></script>
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
      </style>
    </head>
    <body>
    #{body}
    </body>
    </html>
    """
    return html

  buildBodyByCode: (text, language) ->
    body = """
    <pre><code class="#{language}">
    #{text}
    </code></pre>
    <script>hljs.initHighlightingOnLoad();</script>
    """
    return body
