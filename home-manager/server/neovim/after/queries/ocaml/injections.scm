;; extends

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
