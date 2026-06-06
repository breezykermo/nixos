;; extends

; --- CSS injections ---
; NOTE: #gsub! strips %{...} OCaml interpolations so the CSS parser doesn't
; choke on them. Position mapping may shift slightly on lines with long
; interpolations, but subsequent lines remain accurate.

; [%css {| ... |}]
((extension
   (attribute_id) @_name
   (#eq? @_name "css")
   (attribute_payload
     (expression_item
       (quoted_string
         (quoted_string_content) @injection.content))))
 (#set! injection.language "css")
 (#gsub! @injection.content "%%{[^}]*}" " "))

; [%css stylesheet {| ... |}]
((extension
   (attribute_id) @_name
   (#eq? @_name "css")
   (attribute_payload
     (expression_item
       (application_expression
         (quoted_string
           (quoted_string_content) @injection.content)))))
 (#set! injection.language "css")
 (#gsub! @injection.content "%%{[^}]*}" " "))

; {%css| ... |}
((quoted_extension
   (attribute_id) @_ext_id
   (#eq? @_ext_id "css")
   (quoted_string_content) @injection.content)
 (#set! injection.language "css")
 (#gsub! @injection.content "%%{[^}]*}" " "))

; --- HTML injections ---

; {%html.jsx| ... |} (matches html, html.jsx, etc.)
((quoted_extension
   (attribute_id) @_ext_id
   (#match? @_ext_id "^html")
   (quoted_string_content) @injection.content)
 (#set! injection.language "html"))
