;; extends

; --- CSS injections ---

; [%css {| ... |}]
((extension
   (attribute_id) @_name
   (#eq? @_name "css")
   (attribute_payload
     (expression_item
       (quoted_string
         (quoted_string_content) @injection.content))))
 (#set! injection.language "css"))

; [%css stylesheet {| ... |}]
((extension
   (attribute_id) @_name
   (#eq? @_name "css")
   (attribute_payload
     (expression_item
       (application_expression
         (quoted_string
           (quoted_string_content) @injection.content)))))
 (#set! injection.language "css"))

; {%css| ... |}
((quoted_extension
   (attribute_id) @_ext_id
   (#eq? @_ext_id "css")
   (quoted_string_content) @injection.content)
 (#set! injection.language "css"))

; --- HTML injections ---

; {%html.jsx| ... |} (matches html, html.jsx, etc.)
((quoted_extension
   (attribute_id) @_ext_id
   (#match? @_ext_id "^html")
   (quoted_string_content) @injection.content)
 (#set! injection.language "html"))
