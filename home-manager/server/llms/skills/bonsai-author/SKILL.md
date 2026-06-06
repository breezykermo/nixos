---
name: bonsai-author
description: Build OCaml web applications using the Bonsai framework (js_of_ocaml). Use when working with .ml files that use Bonsai, Vdom, ppx_html, ppx_css, or when building incremental UIs in OCaml.
---

# bonsai-author

Bonsai is Jane Street's incremental UI framework for OCaml, compiled to
JavaScript via `js_of_ocaml`. This skill covers the core APIs: `ppx_html`,
`ppx_css`, state management, control flow, effects, and error handling.

## Mental Model: Two Times

Every Bonsai program runs at two distinct times. Understanding which one you
are in is the prerequisite for every API decision.

**Initialization** (runs once) — graph construction phase. You are here when
calling functions that take a `graph` parameter, creating state, or writing
code *outside* `let%arr` bodies.

**Stabilization** (runs repeatedly) — incremental recomputation. You are here
*inside* `let%arr` bodies. This code re-runs whenever the observed `Bonsai.t`
values change.

**Key invariant: no nested `let%arr`.** `Bonsai.t` is not a monad; there is no
`bind`. Combine multiple signals with `let%arr x and y and z in` (parallel
observation), never by nesting.

## View vs Component

| Takes | Returns | Called | Needs `let%arr` to consume? |
|---|---|---|---|
| Plain OCaml values | `Vdom.Node.t` | **View** (`let view`) | No |
| `Bonsai.t` values or `graph` | `'a Bonsai.t` | **Component** (`let component`) | Yes |

Views can only call views. Components can call both.

## State API Decision Tree

Every state API takes a `graph` parameter and returns both the current value
and a way to update it.

Need state?
│
├─ No dependency on old value (e.g., replacing a string)?
│   → Bonsai.state VALUE graph
│     Returns: 'model Bonsai.t * ('model -> unit Effect.t) Bonsai.t
│
├─ New value depends on old (e.g., counters, record field updates)?
│   → Bonsai.state' VALUE graph
│     Returns: 'model Bonsai.t * (('model -> 'model) -> unit Effect.t) Bonsai.t
│     ⚠ Always use state' for record updates — concurrent state setters will race.
│
├─ Just a boolean toggle?
│   ├─ Only need toggle? → Bonsai.toggle ~default_model:BOOL graph
│   │     Returns: bool Bonsai.t * unit Effect.t Bonsai.t
│   └─ Also need set_state? → Bonsai.toggle' ~default_model:BOOL graph
│         Returns: { state; set_state; toggle } Bonsai.Toggle.t Bonsai.t
│
├─ Multiple distinct update actions (variant dispatch)?
│   → Bonsai.state_machine ~default_model ~apply_action graph
│     Returns: 'model Bonsai.t * ('action -> unit Effect.t) Bonsai.t
│
├─ Actions must return values (e.g., generated IDs)?
│   → Bonsai.actor ~default_model ~recv graph
│     Returns: 'model Bonsai.t * ('action -> 'return Effect.t) Bonsai.t
│
├─ State machine depends on external changing values?
│   → Bonsai.state_machine_with_input ~default_model ~apply_action INPUT graph
│
└─ Per-key independent state?
    → Bonsai.scope_model (module Key) ~on:KEY_BONSAI graph ~for_:(fun graph -> ...)

### State code skeletons

**Bonsai.state** — simple replacement:
```ocaml
let value, set_value = Bonsai.state "initial" graph in
let%arr value and set_value in
(* use value, schedule set_value "new" in event handlers *)
```

**Bonsai.state'** — update from previous:
```ocaml
let count, set_count = Bonsai.state' 0 graph in
let%arr count and set_count in
(* set_count (fun c -> c + 1) *)
```

**Bonsai.toggle**:
```ocaml
let is_on, toggle = Bonsai.toggle ~default_model:true graph in
let%arr is_on and toggle in
(* toggle is a unit Effect.t — schedule from on_click *)
```

**Bonsai.state_machine**:
```ocaml
type action = Increment | Reset
type model = { count : int } [@@deriving equal]
let state, inject =
  Bonsai.state_machine
    ~default_model:{ count = 0 }
    ~apply_action:(fun _ model -> function
      | Increment -> { count = model.count + 1 }
      | Reset -> { count = 0 })
    graph
in
let%arr state and inject in
(* inject Increment returns unit Effect.t *)
```

**Bonsai.actor** — actions return values:
```ocaml
let state, inject =
  Bonsai.actor ~default_model:{ items = []; next_id = 0 }
    ~recv:(fun _ model -> function
      | Add_item name ->
        let id = model.next_id in
        ({ items = (id, name) :: model.items; next_id = id + 1 }, id))
    graph
in
let%arr state and inject in
(* let%bind.Effect new_id = inject (Add_item "x") in ... *)
```

## Control Flow Decision Tree

Conditionally render based on a Bonsai.t value?
│
├─ All branches are pure (no state, no graph)?
│   → match%arr VALUE with | Pattern -> EXPR | ...
│     Sugar for: let%arr v in match v with ...
│     ✅ PREFERRED — start here.
│
├─ At least one branch needs its own state or graph?
│   → match%sub VALUE with
│     | Pattern ->
│       let state, set_state = Bonsai.state ... graph in
│       let%arr ... in ...
│     Higher overhead — each arm is a separate Bonsai node.
│
├─ Deferred construction (e.g., route-based page loading)?
│   → match%sub [%lazy] VALUE with | Pattern -> ...
│     Only constructs the matched arm's graph.
│     ⚠ Use sparingly — adds overhead. Good for URL routing.
│
└─ Dynamic number of nodes (list with per-item state)?
    → Bonsai.assoc (module Key) DATA ~f:(fun _key value graph -> ...) graph
      ⚠ Significant overhead, especially nested.

**let%arr** — transform a Bonsai.t into another Bonsai.t:
```ocaml
let%arr student in
Student.name student
```

## ppx_html Syntax

ppx_html is a syntax extension that lets you write HTML-like markup directly
in OCaml, similar to JSX. Converts to Vdom.Node calls at compile time.

Constraint: A ppx_html block must return a single root node. Use `<></>`
fragments for multiple siblings.

### Interpolating OCaml values into markup

┌─────────────────┬────────────────────┬───────────────────────────────────────────────┐
│     Syntax      │        Type        │                    Effect                     │
├─────────────────┼────────────────────┼───────────────────────────────────────────────┤
│ #{string_value} │ string             │ Renders as text                               │
├─────────────────┼────────────────────┼───────────────────────────────────────────────┤
│ %{value#Module} │ any                │ Calls Module.to_string value, renders as text │
├─────────────────┼────────────────────┼───────────────────────────────────────────────┤
│ %{node}         │ Vdom.Node.t        │ Inserts a node                                │
├─────────────────┼────────────────────┼───────────────────────────────────────────────┤
│ *{node_list}    │ Vdom.Node.t list   │ Inserts list of nodes                         │
├─────────────────┼────────────────────┼───────────────────────────────────────────────┤
│ ?{node_option}  │ Vdom.Node.t option │ Inserts node or nothing                       │
└─────────────────┴────────────────────┴───────────────────────────────────────────────┘

### Interpolating attributes

┌────────────────┬──────────────────┬──────────────────────────┐
│     Syntax     │       Type       │          Effect          │
├────────────────┼──────────────────┼──────────────────────────┤
│ attr="value"   │ string literal   │ Standard HTML attribute  │
├────────────────┼──────────────────┼──────────────────────────┤
│ attr=%{value}  │ appropriate type │ OCaml value as attribute │
├────────────────┼──────────────────┼──────────────────────────┤
│ %{attr}        │ Vdom.Attr.t      │ Single attribute         │
├────────────────┼──────────────────┼──────────────────────────┤
│ ?{attr_option} │ Attr.t option    │ Optional attribute       │
├────────────────┼──────────────────┼──────────────────────────┤
│ *{attr_list}   │ Attr.t list      │ List of attributes       │
└────────────────┴──────────────────┴──────────────────────────┘

### Rendering components

`<Module.path />` syntax — literal module paths only, no positional args:
```ocaml
module Badge = struct
  let view ?(attrs = []) () = {%html.jsx|<div *{attrs}>Badge</div>|}
end
(* Must end with unit parameter *)
let view = {%html.jsx|<Badge.view class="active" />|}
```

`<%{expression}>` syntax — any OCaml expression, positional args OK:
```ocaml
let card (header : string) ?(attrs = []) children =
  {%html.jsx|<div *{attrs}><h1>#{header}</h1>*{children}</div>|}
let view = {%html.jsx|<%{card "Hi"} class="greeting">Content</>|}
```

Last parameter determines closing syntax:

┌───────────────────────┬────────────────────────────────────┐
│ Last positional param │               Syntax               │
├───────────────────────┼────────────────────────────────────┤
│ unit                  │ <Foo.view /> (self-closing)        │
├───────────────────────┼────────────────────────────────────┤
│ Vdom.Node.t list      │ <Foo.view>children</> (open/close) │
└───────────────────────┴────────────────────────────────────┘

Named arguments: `~arg:%{value}` or shorthand `~arg` when name matches.
Inline ppx_html arguments: `~arg:(<></>)` for Vdom.Node.t typed args.
Comments: `<!-- comment -->` (HTML-style, not `(* *)`).

### Component structure convention

```ocaml
module My_component = struct
  let component (input : string Bonsai.t) (graph @ local) =
    let%arr input in
    {%html.jsx|<div>#{input}</div>|}
end
```

## ppx_css Syntax

ppx_css validates CSS at compile time. Three tiers of complexity:

**1. Inline style attribute** — simplest, single element:
```ocaml
{%html.jsx|<div style="background-color: red; height: %{h#Css_gen.Length}">
  Text
</div>|}
```

**2. {%css| |} blocks** — reusable, pseudo-selectors:
```ocaml
let style = {%css|
  background-color: #fefefe;
  &:hover { background-color: %{color#Css_gen.Color}; }
|} in
{%html.jsx|<div %{style}>Hover me</div>|}
```

**3. [%css stylesheet {| |}]** — named classes, @media, relative selectors:
```ocaml
module Styles = [%css stylesheet {|
  .greeting { background: gray; &:hover .child { outline: 1px solid blue; } }
  @media (max-width: 800px) { .greeting { padding: 10px; } }
|}]
(* Use as: Styles.greeting → Vdom.Attr.t *)
{%html.jsx|<div %{Styles.greeting}>Hello</div>|}
```

## Effects

Effects are values representing side effects. Constructed anywhere, but only
run when scheduled (returned from event handlers like on_click). State
setters return Effect.t — they do nothing until scheduled.

### Core patterns

**Schedule from event handler:**
```ocaml
let%arr value and set_value in
let effect = set_value "new" in
{%html.jsx|<button on_click=%{fun _ -> effect}>Click</button>|}
```

**Chain with Effect monad:**
```ocaml
let%arr set_msg in
let effect =
  let%bind.Effect () = Effect.print_s [%message "step 1"] in
  let%bind.Effect () = Effect.print_s [%message "step 2"] in
  set_msg "done"
in
(* schedule 'effect' from handler *)
```

**Sync function → Effect:**
```ocaml
let%bind.Effect result = Effect.of_sync_fun (fun () -> Random.int 100) ()
```

**Run multiple in parallel:**
```ocaml
Effect.all_parallel [ e1; e2; e3 ]        (* 'a list Effect.t *)
Effect.all_parallel_unit [ e1; e2 ]       (* unit Effect.t *)
```

**Common event-handler composition:**
```ocaml
let handle_click =
  Effect.all_parallel_unit
    [ set_count (fun c -> c + 1)
    ; Effect.print_s [%message "clicked"]
    ]
```

## Error Handling

Never raise exceptions in Bonsai code. Exceptions are extremely slow in
js_of_ocaml and cause severe performance degradation.

Use `Or_error.t Bonsai.t` for fallible values:
```ocaml
match%arr result with
| Ok value -> {%html.jsx|<div>Success: #{show value}</div>|}
| Error e -> {%html.jsx|<div>Error: #{Error.to_string_hum e}</div>|}
```

## Common Gotchas

1. **No nested let%arr.** Use `let%arr x and y in` to combine signals.
2. **Bonsai.state vs state' for records.** Concurrent state updates to
   the same record will race. Always use state' when updating a field.
3. **Cannot embed Vdom.Node.t Bonsai.t directly in ppx_html.** `let%arr`
   it first, then use `%{node}`.
4. **graph is unavailable inside let%arr.** Create state before the
   `let%arr`, then thread results through with `and`.
5. **Bonsai.assoc overhead.** Significant cost, especially nested. Only use
   when each item truly needs independent state.
6. **match%sub [%lazy] overhead.** Use only for route-level granularity.
7. **Exceptions catastrophic in js_of_ocaml.** Always use Or_error.t.
8. **Components taking graph can't be used as `<Module.path />` inside
   ppx_html.** Call outside, let%arr the result, embed with `%{result}`.

## Reference

- Quick start: https://github.com/janestreet/bonsai_web/blob/master/docs/public_garden_exports/quick_start.md
- Thinking in Bonsai: https://github.com/janestreet/bonsai_web/blob/master/docs/public_garden_exports/thinking_in_bonsai.md
- API docs: https://janestreet.github.io/bonsai/
