;; extends

; --- HTML injections ---

; {%html.jsx| ... |} (matches html, html.jsx, etc.)
((quoted_extension
   (attribute_id) @_ext_id
   (#match? @_ext_id "^html")
   (quoted_string_content) @injection.content)
 (#set! injection.language "html"))
