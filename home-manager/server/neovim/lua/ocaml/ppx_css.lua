vim.schedule(function()
  pcall(vim.treesitter.query.set, "ocaml", "injections", [[
((comment) @injection.content
  (#set! injection.language "comment"))

((extension
   (attribute_id) @_name
   (#eq? @_name "css")
   (attribute_payload
     (expression_item
       (application_expression
         (quoted_string
           (quoted_string_content) @injection.content)))))
 (#set! injection.language "css"))

((extension
   (attribute_id) @_name
   (#eq? @_name "css")
   (attribute_payload
     (expression_item
       (quoted_string
         (quoted_string_content) @injection.content))))
 (#set! injection.language "css"))
  ]])
end)
