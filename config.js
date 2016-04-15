
config = {
  meta: {
    // title: "reveal.js – The HTML Presentation Framework",
    // theme: "black",
    // highlight: "zenburn"
  },
  markdown: {
    // markdown: "README.md",
    // separator: "^\n\n\n",
    // separatorVertical: "\n\n",
    // separatorNotes: "^Note:",
    // charset: "utf-8"
  },
  initialize: {
		// Full list of configuration options available at:
		// https://github.com/hakimel/reveal.js#configuration
    controls: true,
  	progress: true,
  	history: true,
  	center: true,

  	transition: 'slide', // none/fade/slide/convex/concave/zoom

  	// Optional reveal.js plugins
  		dependencies: [
  			{ src: 'lib/js/classList.js', condition: function() { return !document.body.classList; } },
  			{ src: 'plugin/markdown/marked.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } },
  			{ src: 'plugin/markdown/markdown.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } },
  			{ src: 'plugin/highlight/highlight.js', async: true, callback: function() { hljs.initHighlightingOnLoad(); } },
  			{ src: 'plugin/zoom-js/zoom.js', async: true },
  			{ src: 'plugin/notes/notes.js', async: true }
  		]
    }
};
