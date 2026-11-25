#if DEBUG
import Foundation

enum DevToolsShellPage {
    static let html = Data("""
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>Hackle User Explorer</title>
      </head>
      <body>
        <div id="root"></div>
        <script type="module">\(DevToolsViewerScript.source)</script>
      </body>
    </html>
    """.utf8)
}
#endif
