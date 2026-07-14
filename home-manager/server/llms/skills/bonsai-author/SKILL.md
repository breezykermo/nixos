---
name: bonsai-author
description: Build OCaml web applications using the Bonsai framework (js_of_ocaml). Use when working with .ml files that use Bonsai, Vdom, ppx_html, ppx_css, or when building incremental UIs in OCaml.
---

# bonsai-author

Bonsai is Jane Street's incremental UI framework for OCaml, compiled to
JavaScript via `js_of_ocaml`. This skill covers the current (`local_ graph`)
API: `ppx_html`, `ppx_css`, state, control flow, effects, lifecycles, error
handling, and the main feature libraries (forms, RPCs, routing, testing).

> **Syntax note (important, changed recently):** Modern Bonsai uses `{%html|...|}`
> — **not** `{%html.jsx|...|}`. The `.jsx` dialect no longer appears in the docs
> or examples. Use `{%html|...|}` and `{%css|...|}`.

> **Graph parameter idiom:** Components that use Bonsai primitives take a
> `graph` parameter that is a `local` value. Write it `(local_ graph)` or
> equivalently `(graph @ local)` (newer OCaml "modes" syntax) — both appear in
> the docs and compile identically. In signatures the type is `local_ Bonsai.graph`.

## Mental Model: Two Times

Every Bonsai program runs at two distinct times. Understanding which one you
are in is the prerequisite for every API decision.

**Initialization** (runs once) — graph construction phase. You are here when
calling functions that take a `graph` parameter, creating state, or writing
code *outside* `let%arr` bodies.

**Stabilization** (runs repeatedly) — incremental recomputation. You are here
*inside* `let%arr` bodies. This code re-runs whenever the observed `Bonsai.t`
values change.

**Key invariant: no nested `let%arr`.** `Bonsai.t` is an arrow, not a monad;
there is no `bind`. A nested `let%arr` would produce `'a Bonsai.t Bonsai.t`,
which would permit constructing graph nodes at runtime. Combine multiple
signals with `let%arr x and y and z in` (parallel observation) instead.

**`let%arr` vs `let%map`:** With the `local_ graph` API they have the same type
and are interchangeable for the simple `let%arr foo = foo in` case. Prefer
`let%arr` when pattern-matching/destructuring: `let%arr { a; _ } = r in` only
recomputes when `a` changes (it adds an incremental cutoff on the projection),
whereas `let%map` recomputes on any change to `r`.

## View vs Component

| Takes | Returns | Called | Needs `let%arr` to consume? |
|---|---|---|---|
| Plain OCaml values | `Vdom.Node.t` | **View** (`let view`) | No |
| `Bonsai.t` values or `graph` | `'a Bonsai.t` | **Component** (`let component`) | Yes |

Views can only call views. Components can call both. If it has `let%arr`,
returns a `Bonsai.t`, or takes `graph`, it's a component. Modules export a
`view` and/or a `component` function accordingly.

```ocaml
module My_component = struct
  let component (input : string Bonsai.t) (local_ graph) =
    let%arr input in
    {%html|<div>#{input}</div>|}
  ;;
end
```

**Prefer `('a Bonsai.t * 'b Bonsai.t)` to `('a * 'b) Bonsai.t`.** Returning
tuples/records *of* `Bonsai.t`s (rather than a `Bonsai.t` of a tuple/record)
produces a better-structured incremental graph. Combine with `Bonsai.both` /
`let%arr`, split later with `let%sub`. (Exception: higher-order functions want
their `~f` to return a single `Bonsai.t`.)

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
│     ⚠ Always use state' for record/field updates — concurrent state setters race.
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
│     (input reaches apply_action as `Active v | Inactive` — a Computation_status.t)
│
└─ Per-key independent state?
    → Bonsai.scope_model (module Key) ~on:KEY_BONSAI graph ~for_:(fun graph -> ...)

### State code skeletons

**Bonsai.state** — simple replacement:
```ocaml
let value, set_value = Bonsai.state "initial" graph in
let%arr value and set_value in
(* use value, schedule (set_value "new") in event handlers *)
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

**Bonsai.state_machine** — `apply_action` receives `(context, model, action)`;
the `_` below is an `Apply_action_context.t`:
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
From inside `apply_action`, dispatch further effects with
`Apply_action_context.schedule_event context effect`, and read the current time
cheaply via the context's time source.

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

**Bonsai.scope_model** — separate state per key value; state persists when you
switch back to a key:
```ocaml
Bonsai.scope_model (module String) ~on:active_key graph
  ~for_:(fun graph -> Counter.component graph)
```

### Organizing state

- **Single source of truth.** Don't mirror the same state in two places; sync
  bugs and stale-frame flashes follow. Lift shared state to a common parent.
- **Controllable components.** Let a component take an optional
  `?state:'a Bonsai.t * ('a -> unit Effect.t) Bonsai.t` — controlled if given,
  otherwise it makes its own. Design for this.
- **Don't store derived values.** If it can be computed with `let%arr`, compute
  it. Store the smallest thing (e.g. a selected *id*, not the selected record or
  its rendered view) to avoid duplicating/staling state.
- **No mutable models.** Incremental cutoff relies on `phys_equal`; mutation
  undermines it. Use state primitives + `Effect.t` for side effects.
- Last resort for genuinely un-ownable/external state: `Bonsai_extra.Mirror.mirror`
  (bi-directional sync; only for synchronous setters — never async).

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
│     Each arm is a separate Bonsai node with its own state.
│     ⚠ A top-level `match%sub` must be inside a fn taking `graph`
│       (`let c (local_ graph) = match%sub ...`), else it raises at startup.
│
├─ Deferred construction (e.g., route-based page loading)?
│   → match%sub [%lazy] VALUE with | Pattern -> ...
│     Only constructs the matched arm's graph. Requires `graph` in scope.
│     ⚠ Use sparingly — adds overhead. Good for URL routing.
│
└─ Dynamic number of nodes (list with per-item state)?
    → Bonsai.assoc (module Key) DATA ~f:(fun _key value graph -> ...) graph
      Returns a map; render with `Vdom.Node.Map_children.div` (see below).
      ⚠ Significant overhead, especially nested (see Performance).

**let%arr** — transform a Bonsai.t into another Bonsai.t:
```ocaml
let%arr student in
Student.name student
```

**Higher-order functions** — `match%sub` and `Bonsai.assoc` are themselves
higher-order. Build reusable abstractions (modals, query renderers, generic
tables) with signatures like:
```ocaml
val f : ('a Bonsai.t -> local_ Bonsai.graph -> 'b Bonsai.t) -> ... -> local_ Bonsai.graph -> 'c Bonsai.t
```
Instantiate the `~content`/`~f` child *inside* the branch where it's used so its
state/lifecycle only run when active.

## ppx_html Syntax

`ppx_html` lets you write HTML-like markup directly in OCaml (like JSX),
compiled to `Vdom.Node` calls. Use `{%html|...|}`.

Constraint: a block must return a single root node. Use a `<></>` fragment for
multiple siblings.

### Interpolating OCaml values into markup

| Syntax | Type | Effect |
|---|---|---|
| `#{string_value}` | string | Renders as text |
| `%{value#Module}` | any | Calls `Module.to_string value`, renders as text |
| `%{node}` | `Vdom.Node.t` | Inserts a node |
| `*{node_list}` | `Vdom.Node.t list` | Inserts a list of nodes |
| `?{node_option}` | `Vdom.Node.t option` | Inserts node or nothing |

### Interpolating attributes

| Syntax | Type | Effect |
|---|---|---|
| `attr="value"` | string literal | Standard HTML attribute |
| `attr=%{value}` | appropriate type | OCaml value as attribute |
| `%{attr}` | `Vdom.Attr.t` | Single attribute |
| `?{attr_option}` | `Attr.t option` | Optional attribute |
| `*{attr_list}` | `Attr.t list` | List of attributes |
| `attr'=%{bool}` | bool | Boolean attribute (e.g. `disabled'=%{has_error}`) |

Event handlers (`on_click`, `on_change`, …) take functions returning an
`Effect.t`: `on_click=%{fun _ -> effect}`.

### Rendering components

`<Module.path />` syntax — literal module paths only, no positional args:
```ocaml
module Badge = struct
  let view ?(attrs = []) () = {%html|<div *{attrs}>Badge</div>|}
end
(* Must end with a unit parameter *)
let view = {%html|<Badge.view class="active" />|}
```

`<%{expression}>` syntax — any OCaml expression, positional args OK:
```ocaml
let card (header : string) ?(attrs = []) children =
  {%html|<div *{attrs}><h1>#{header}</h1>*{children}</div>|}
let view = {%html|<%{card "Hi"} class="greeting">Content</>|}
```

Last positional parameter determines closing syntax:

| Last positional param | Syntax |
|---|---|
| `unit` | `<Foo.view />` (self-closing) |
| `Vdom.Node.t list` | `<Foo.view>children</>` (open/close; `</Foo.view>` also allowed) |

Named arguments: `~arg:%{value}` or shorthand `~arg` when the name matches.
Inline ppx_html arguments: `~arg:(<></>)` for `Vdom.Node.t`-typed args.
Comments: `<!-- comment -->` (HTML-style, not `(* *)`).

## ppx_css Syntax

`ppx_css` validates CSS at compile time. Three tiers:

**1. Inline style attribute** — simplest, single element:
```ocaml
{%html|<div style="background-color: red; height: %{h#Css_gen.Length}">Text</div>|}
```

**2. `{%css| |}` blocks** — reusable, pseudo-selectors:
```ocaml
let style = {%css|
  background-color: #fefefe;
  &:hover { background-color: %{color#Css_gen.Color}; }
|} in
{%html|<div %{style}>Hover me</div>|}
```

**3. `[%css stylesheet {| |}]`** — named classes, @media, relative selectors:
```ocaml
module Styles = [%css stylesheet {|
  .greeting { background: gray; &:hover .child { outline: 1px solid blue; } }
  @media (max-width: 800px) { .greeting { padding: 10px; } }
|}]
(* Use as: Styles.greeting → Vdom.Attr.t *)
{%html|<div %{Styles.greeting}>Hello</div>|}
```

## Effects

Effects are values representing side effects. Constructed anywhere, but only
run when *scheduled* (returned from event handlers like `on_click`, or from
lifecycle/edge triggers). State setters return `Effect.t` — they do nothing
until scheduled.

### Core patterns

**Schedule from event handler:**
```ocaml
let%arr value and set_value in
{%html|<button on_click=%{fun _ -> set_value "new"}>Click</button>|}
```

**Chain with the Effect monad:**
```ocaml
let%bind.Effect () = Effect.print_s [%message "step 1"] in
set_msg "done"
```

**Sync function → Effect:**
```ocaml
let%bind.Effect result = Effect.of_sync_fun (fun () -> Random.int 100) () in ...
```

**Run multiple:**
```ocaml
Effect.all_parallel [ e1; e2; e3 ]        (* 'a list Effect.t *)
Effect.all_parallel_unit [ e1; e2 ]       (* unit Effect.t *)
Effect.all_unit [ e1; e2 ]                (* sequential unit Effect.t *)
Effect.Many [ e1; e2 ]                    (* combine, e.g. with Stop_propagation *)
```

### Browser-API effects

`Effect.print_s`, `Effect.reload_page`, `Effect.Stop_propagation`,
`Effect.Stop_immediate_propagation`, `Effect.alert` (discouraged; throws in
tests). `Effect.Focus` for focus/blur (see below).

⚠ `Effect.Prevent_default` / `Stop_propagation` must run *first* — compose with
`Effect.Many`, never sequence anything after them via `let%bind.Effect` (an
async predecessor would make them fire too late). Note: `Effect.Prevent_default`
is deprecated.

### Stale values in effects — `Bonsai.peek`

An effect closes over the values it captured *when scheduled*; if you set state
and then read a value that depends on it in the same effect, you get the stale
value. Use `Bonsai.peek` to read the current value at run time instead:
```ocaml
let peek_computed = Bonsai.peek computed graph in
let effect =
  let%arr peek_computed and set_state in
  fun new_state ->
    let%bind.Effect () = set_state new_state in
    match%bind.Effect peek_computed with
    | Active v  -> Effect.alert v      (* Computation_status.t *)
    | Inactive  -> Effect.Ignore
in ...
```
(`Bonsai.peek` was previously named `Bonsai.yoink`.)

## Lifecycles and Edge-Triggered Effects

Nodes under `match%sub` / `Bonsai.assoc` are *active* or *inactive*; state
persists while inactive.

- `Bonsai.Edge.lifecycle ~on_activate ~on_deactivate graph` — schedule effects
  when a node becomes active/inactive. Outside any `match%sub`/`assoc`,
  `on_activate` runs once at startup and `on_deactivate` never runs.
- `Bonsai.Edge.on_change' ~trigger:`Before_display ~equal ~callback value graph`
  — run an effect when `value` changes (callback gets `prev option -> new`).
  `Bonsai.Edge.on_change` for the no-previous variant.
- `after_display` runs an effect *every frame* while active — almost never what
  you want.

⚠ Extensive use of `Edge` makes programs imperative and hard to test. Prefer
declarative alternatives; never use `Edge` just to sync two Bonsai states.

## Resetting State

- `Bonsai.with_model_resetter ~f graph` → `(view, reset)` where `reset :
  unit Effect.t` resets all state created inside `f` to its defaults.
- `Bonsai.with_model_resetter' ~f:(fun ~reset (local_ graph) -> ...) graph` —
  lets the block reset its own state.
- Customize per-state reset via `~reset` on creation, e.g.
  `Bonsai.state ~reset:(fun m -> m) default graph` to *exclude* state from
  resets, or a `~reset:(fun context model -> ...)` on `state_machine` to run
  cleanup effects. (Custom resets can disable default-model optimizations —
  only use when needed.)

## Rendering Lists Performantly

Vdom diffs lists naively by index, so inserts/removals/reorders can destroy and
recreate DOM nodes.

- For conditionally-shown nodes, render `Vdom.Node.none` (an empty comment) when
  hidden to keep list length constant — not `Vdom.Node.none_deprecated`, and
  avoid `List.filter_opt` on `Vdom.Node.t option`s.
- For keyed/reorderable lists (and `Bonsai.assoc` output, which is a map),
  render with `Vdom.Node.Map_children.div map` — it diffs by key, much better
  than `Vdom.Node.div (Map.data map)`.

## Time — `Bonsai.Clock`

Always use `Bonsai.Clock` (mockable in tests via `Handle.advance_clock_by`).

- `Bonsai.Clock.approx_now ~tick_every graph : Time_ns.t Bonsai.t` — cheap.
- `Bonsai.Clock.get_current_time graph : Time_ns.t Effect.t Bonsai.t` — fetch
  fresh time inside an effect (avoids staleness).
- `Bonsai.Clock.sleep graph` — `Time_ns.Span.t -> unit Effect.t` (setTimeout).
- `Bonsai.Clock.every ~when_to_start_next_effect ~trigger_on_activate span effect graph`.
- `Bonsai.Clock.Expert.now graph` — updates *every frame*; expensive, avoid.

## Error Handling

Never raise exceptions in Bonsai code — they are extremely slow in
`js_of_ocaml` and cause severe performance degradation. Wrap fallible values in
`Or_error.t Bonsai.t` and match on them:
```ocaml
match%arr result with
| Ok value -> {%html|<div>Success: #{show value}</div>|}
| Error e  -> {%html|<div>Error: #{Error.to_string_hum e}</div>|}
```

## Performance

- **Don't over-incrementalize.** Incremental nodes aren't free; folding cheap
  intermediate computations into one `let%arr` is often faster.
- **`Bonsai.assoc` is expensive** (per-key state, retained for removed keys;
  grows badly when nested). If a body instantiates *nothing* with `graph`,
  Bonsai lowers it to a constant-node `Incr_map.mapi`; keep large assoc bodies
  graph-free (except `Bonsai.path`).
- Graph height is capped at **1024** — occasionally hit by recursive
  `Bonsai.fix`.
- `Bonsai_extra` has many helpers built on the primitives.

## Feature Libraries (concise pointers)

**Forms** — `module Form = Bonsai_web_form.With_manual_view`. Core:
`Form.value : ('a,_) t -> 'a Or_error.t`, `Form.view`, `Form.set`.
Elements: `Form.Elements.Textbox.string ~allow_updates_when_focused:`Always ()
graph`, `.int`/`.float`, `Checkbox.bool`, `Number.int`, `Dropdown.list (module
M) values ~equal`. Transform with `Form.project ~parse_exn ~unparse` (needs
both, so `set` round-trips) and `Form.validate ~f`. Compose with `Form.both`;
derive with `Form.Typed.Record.make` / `Form.Typed.Variant.make`.

**RPCs** — `Rpc_effect`. One-shot:
`Rpc_effect.Rpc.dispatcher rpc ~where_to_connect graph : (query -> response
Or_error.t Effect.t) Bonsai.t` (fires only when the effect is scheduled).
Polling: `Rpc_effect.Polling_state_rpc.poll`. Connect with
`Rpc_effect.Where_to_connect.self ~on_conn_failure:Retry_until_success ()`.

**Routing / URL** — `Url_var`. Build with `Url_var.Typed.make (module T) parser
~fallback`; read `Url_var.value var : 'a Bonsai.t`; set with
`Url_var.set_effect ?how:[ `Push | `Replace ] var v`. Route by `match%sub` on
the value. Derive parsers from types with `Uri_parsing` / `ppx_uri_parsing`
(`[@@deriving typed_variants, uri_parsing]`, `Parser.Variant.make` /
`Parser.Record.make`). ⚠ `Url_var` needs a real browser — create it in `bin/`,
not `lib/` or `test/`; keep a `Parser.check_ok_and_print_urls_or_errors` test.

**Testing** — `Bonsai_web_test`. `Handle.create (Result_spec.vdom Fn.id)
component`; inspect with `Handle.show` / `Handle.show_diff`; interact with
`Handle.click_on ~get_vdom:Fn.id ~selector` and `Handle.input_text ~text`;
prefer `Test_selector.t` over CSS strings; drive dynamic inputs with
`Bonsai.Expert.Var`; advance time with `Handle.advance_clock_by`. Tests run in
Node (no real DOM/hooks/widgets); avoid async tests unless testing RPCs.

**Dynamic scope** (React-context-like) — `Bonsai.Dynamic_scope.create ~name
~fallback ()`, `lookup t graph`, `set t value ~inside graph`.

**`Bonsai.Expert.Var`** — a mutable var *outside* the graph (no `graph` param).
Only for test inputs and toplevel global state (e.g. backing a `Url_var`); never
for component-local state.

**Theming** — `Bonsai_web.View` helpers (`View.hbox`/`vbox`, `View.button theme
~on_click ?intent`, `View.text`), `View.Theme.current graph`,
`View.Theme.set_for_app`, `Kado.theme ~version:V1 ()`. Note: the theme API is
being deprecated; prefer `ppx_css` for new apps.

**JS interop** — `Js_of_ocaml` (`Js.t`, `Js.string`/`to_string`, `ppx_js`
`obj##.prop`/`obj##method`, `Js.Unsafe.coerce`). Test manually — most tests run
in Node. Int size differs (JS 32-bit, Wasm 31-bit): use `Int63`/`Int64` for
large ints.

## Common Gotchas

1. **Use `{%html|...|}`, not `{%html.jsx|...|}`.** The `.jsx` dialect is gone.
2. **No nested `let%arr`.** Combine with `let%arr x and y in`.
3. **`Bonsai.state` vs `state'` for records.** Concurrent updates to the same
   record race and clobber each other. Use `state'` for any field update.
4. **Can't embed `Vdom.Node.t Bonsai.t` in ppx_html.** `let%arr` it first, then
   `%{node}`.
5. **`graph` is unavailable inside `let%arr`.** Create state before the
   `let%arr`, thread results in with `and`.
6. **Components taking `graph` can't be `<Module.path />` in ppx_html.** Call
   the component outside, `let%arr` the result, embed with `%{result}`.
7. **Effects capture stale values.** Use `Bonsai.peek` to read current values
   inside an effect.
8. **`Bonsai.assoc` overhead** — keep bodies graph-free at scale; render output
   with `Vdom.Node.Map_children.div`.
9. **`match%sub [%lazy]` overhead** — route-level granularity only.
10. **Never raise exceptions** — catastrophic in js_of_ocaml. Use `Or_error.t`.
11. **Avoid `Edge`/mutable state to sync signals** — prefer a single source of
    truth.

## Reference

Docs (in `janestreet/bonsai_web`, `docs/`):
- Quick start: https://github.com/janestreet/bonsai_web/blob/master/docs/quick_start.md
- Thinking in Bonsai: https://github.com/janestreet/bonsai_web/blob/master/docs/thinking_in_bonsai.md
- How-to guides index: https://github.com/janestreet/bonsai_web/tree/master/docs/how_to
  (best_practices_pitfalls, organizing_state, resetting_state, lifecycles,
  edge_triggered_effects, effects_and_stale_values, higher_order_functions,
  forms, rpcs, testing, url_var, uri_parsing, theming, time, focus, cutoff,
  dynamic_scope, javascript_interop, partial_render_table)
- `local_ graph` upgrade notes: https://github.com/janestreet/bonsai_web/blob/master/docs/upgrade/local-graph.md
- Examples: https://github.com/janestreet/bonsai_examples
- API docs: https://janestreet.github.io/bonsai/
