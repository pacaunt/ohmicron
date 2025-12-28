#import "dependencies.typ": *
#import "utils.typ"

#let parse-i-position

/// Template for creating component that has only two nodes: the input and output.
#let x-component(
  name,
  start,
  end,
  position: 50%,
  label: none,
  label2: none,
  i: none,
  v: none,
  f: none,
  nodes: "-",
  padding: none,
  label-gap: .2,
  label2-gap: auto,
  anchor: "center",
  debug: false,
  // Extra drawing 
  append: none, 
  // The component 
  body,

) = draw.group(
  name: name,
  {
    let _anchor = anchor
    import draw: *
    let center = (start, position, end)
    let drawing = group(name: "body", anchor: _anchor, padding: padding, {
      set-origin(center)
      anchor("default", (0, 0))
      if body == none {
        anchor("center", (0, 0))
      }
      body
    })
    let cover = if debug { it => it } else { hide }

    // place to find the sizes
    cover(scope({
      stroke(gray)
      drawing
    }))

    get-ctx(ctx => {
      let (ctx, a, b) = cetz.coordinate.resolve(ctx, start, end)
      let line-style = cetz.styles.resolve(ctx.style, root: "line")
      let ang = vector.angle2(a, b)


      let (ctx, SW, NE) = (ctx, center, center)
      let (width, height) = (1e-8, 1e-8)

      if body != none {
        (ctx, SW, NE) = cetz.coordinate.resolve(ctx, "body.south-west", "body.north-east")
        (width, height) = vector.sub(NE, SW).slice(0, 2) // size of the component
      }

      let (label1-gap, label2-gap) = if label2-gap == auto {
        (label-gap,) * 2
      } else {
        (label-gap, label2-gap)
      }.map(utils.resolve-length.with(full: height))

      set-origin((0, 0))
      anchor("default", (0, 0))
      anchor("start", start)
      anchor("end", end)
      scope({
        rotate(ang, origin: center)
        rect(
          name: "bounds",
          (to: center, rel: (-width / 2, -height / 2)),
          (rel: (width, height)),
          stroke: if debug { red } else { none },
        )
        drawing
        // The Labels
        content(
          "bounds.north",
          label,
          anchor: "south",
          angle: ang,
          padding: (bottom: label1-gap),
          name: "label-north",
        )
        content(
          "bounds.south",
          label2,
          anchor: "north",
          angle: ang,
          padding: (top: label2-gap),
          name: "label-south",
        )
      })

      // Drawing current
      if i != none {
        let i-label = i.at("label", default: [])
        let i-label-gap = utils.resolve-length(i.at("label-gap", default: .2), full: height)
        let i-dist = i.at("distance", default: 75%)
        let i-pos = i.at("pos", default: "->")
        let (up, right) = utils.parse-flow(i-pos)

        let coor = (start, i-dist, end)

        mark(
          coor,
          if right { end } else { start },
          symbol: ">",
          fill: line-style.stroke.paint,
          anchor: "center",
        )
        content(
          coor,
          i-label,
          anchor: if up { "south" } else { "north" },
          padding: ({ if up { "bottom" } else { "top" } }: i-label-gap),
          angle: ang,
          name: "i-label",
        )
      }

      // Drawing voltage
      if v != none {
        let v-label = v.at("label", default: [])
        let v-label-gap = utils.resolve-length(v.at("label-gap", default: .2), full: height)
        let v-plus = v.at("plus", default: $+$)
        let v-minus = v.at("minus", default: $-$)
        let v-pos = v.at("pos", default: "->")
        let v-spread = utils.resolve-length(v.at("spread", default: 1.1fr), full: width)
        let (right, up) = utils.parse-volt(v-pos)
        let v-center = "bounds" + if up { ".north" } else { ".south" }

        content(
          v-center,
          v-label,
          anchor: if up { "south" } else { "north" },
          padding: ({ if up { "bottom" } else { "top" } }: v-label-gap),
          angle: ang,
          name: "v-label",
        )

        let v-sign-pos = (
          (to: v-center, rel: (-v-spread / 2, 0)),
          (to: v-center, rel: (v-spread / 2, 0)),
        )
        if not right { v-sign-pos = v-sign-pos.rev() }

        scope({
          rotate(ang, origin: center)
          content(
            v-sign-pos.first(),
            v-plus,
            anchor: if up { "south" } else { "north" },
            padding: ({ if up { "bottom" } else { "top" } }: v-label-gap),
            angle: ang,
            name: "v-plus",
          )
          content(
            v-sign-pos.last(),
            v-minus,
            anchor: if up { "south" } else { "north" },
            padding: ({ if up { "bottom" } else { "top" } }: v-label-gap),
            angle: ang,
            name: "v-minus",
          )
        })
      }

      // Drawing flows
      if f != none {
        let f = f
        let f-label = f.remove("label", default: [])
        let f-label-gap = utils.resolve-length(f.remove("label-gap", default: .4fr), full: height)
        let f-pos = f.remove("pos", default: "->")
        let f-spread = utils.resolve-length(f.remove("spread", default: 1.2fr), full: width)
        let f-bend = f.remove("bend", default: 21deg)
        let f-mark = f.remove("mark", default: (symbol: ">", fill: line-style.stroke.paint))
        let f-styles = f // the remaining arguments

        let (right, up) = utils.parse-volt(f-pos)
        let f-center = "bounds" + if up { ".north" } else { ".south" }
        scope({
          rotate(ang, origin: center)
          bezier(
            (to: f-center, rel: (-f-spread / 2, 0)),
            (to: f-center, rel: (f-spread / 2, 0)),
            (to: f-center, rel: (if up { 90deg } else { -90deg }, f-spread / 2 / calc.sin(f-bend))),
            mark: ((if right { "end" } else { "start" }): f-mark),
            name: "flow",
            ..f-styles,
          )
          content(
            "flow.50%",
            f-label,
            anchor: if up { "south" } else { "north" },
            padding: ({ if up { "bottom" } else { "top" } }: f-label-gap),
            angle: ang,
            name: "f-label",
          )
        })
      }

      // Draw nodes
      let (end-mark, start-mark) = utils.parse-nodes(nodes, styles: (
        "*": (fill: line-style.stroke.paint),
        "o": (:),
      ))
      on-layer(1, {
        mark(
          start,
          end,
          anchor: "center",
          ..start-mark,
        )
        mark(
          end,
          start,
          anchor: "center",
          ..end-mark,
        )
      })
    })
  
      line("start", "bounds.west", name: "before")
    
    line("bounds.east", "end")
  },
)

#let wiring(..comp-styles) = {
  let styles = comp-styles.named() 
  let comps = comp-styles.pos() 

}

#let center-rect(center, size: (1, 2), ..styles) = {
  import draw: *
  let (w, h) = size
  rect(
    (to: center, rel: (-w / 2, -h / 2)),
    (rel: (w, h)),
    ..styles,
  )
}


#canvas({
  import draw: *
  x-component(
    "R1",
    (0, 0),
    (4, 2),
    {
      decorations.zigzag(line((0, 0), (1, 0)), amplitude: .5, segments: 3)
    },
    label: $R$,
    label2: [30 k],
    position: 30%,
    i: (label: $i_1$, pos: "->"),
    nodes: "*-*",
    v: (label: $V$, label-gap: 1fr, spread: 1.5fr),
    f: (label: $I$, stroke: red + 2pt, pos: "<_"),
    // debug: true,
  )

  set-origin("R1.end")

  x-component(
    "R2",
    (0, 0),
    (4, 2),
    {},
  )
  get-ctx(ctx => {
    content((3, -3), [#ctx.shared-state])
  })
  group(name: "g", {
    scope({
      circle((0, 0), name: "R")
    })
  })
  // circle("R.center")
  
})


