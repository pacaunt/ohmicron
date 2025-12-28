#import "dependencies.typ": *
#import "utils.typ"

// For saving anchor of the coordinates.
#let save(
  name,
) = {
  return (
    kind: "anchor",
    name: name,
  )
}

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
) = {
  let drawing = (
    draw.group(
      name: name,
      {
        let _anchor = anchor
        import draw: *
        let center = (start, position, end)
        let comp(center) = group(name: "body", anchor: _anchor, padding: padding, {
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
          comp(center)
          line(start, end, name: "_through")
        }))

        get-ctx(ctx => {
          let (ctx, a, b, c) = cetz.coordinate.resolve(
            ctx,
            "_through.start",
            "_through.end",
            (
              name: "_through",
              anchor: position,
            ),
          )
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
          anchor("start", a)
          anchor("end", b)
          scope({
            rotate(ang, origin: c)
            rect(
              name: "bounds",
              (to: c, rel: (-width / 2, -height / 2)),
              (rel: (width, height)),
              stroke: if debug { red } else { none },
            )
            comp(c)
            // The Labels
            content(
              "bounds.north",
              std.rotate(ang, label, reflow: true),
              anchor: "south",
              angle: ang,
              padding: (bottom: label1-gap),
              name: "label-north",
            )
            content(
              "bounds.south",
              std.rotate(ang, label2, reflow: true),
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
            let i-style = i.at("style", default: (fill: line-style.stroke.paint))
            let (up, right) = utils.parse-flow(i-pos)

            let coor = (a, i-dist, b)

            mark(
              coor,
              if right { b } else { a },
              symbol: ">",
              anchor: "center",
              ..i-style,
            )
            content(
              coor,
              std.rotate(ang, i-label, reflow: true),
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
              std.rotate(ang, v-label, reflow: true),
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
              rotate(ang, origin: c)
              content(
                v-sign-pos.first(),
                std.rotate(ang, v-plus, reflow: true),
                anchor: if up { "south" } else { "north" },
                padding: ({ if up { "bottom" } else { "top" } }: v-label-gap),
                angle: ang,
                name: "v-plus",
              )
              content(
                v-sign-pos.last(),
                std.rotate(ang, v-minus, reflow: true),
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
              rotate(ang, origin: c)
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
                std.rotate(ang, f-label, reflow: true),
                anchor: if up { "south" } else { "north" },
                padding: ({ if up { "bottom" } else { "top" } }: f-label-gap),
                // angle: ang,
                name: "f-label",
              )
            })
          }

          // Draw nodes
          let (end-mark, start-mark) = utils.parse-nodes(nodes, styles: (
            "*": (fill: line-style.stroke.paint),
            "o": (fill: white),
          ))
          on-layer(1, {
            mark(
              a,
              b,
              anchor: "center",
              ..start-mark,
            )
            mark(
              b,
              a,
              anchor: "center",
              ..end-mark,
            )
          })
        })
        cover({
          line("start", "bounds.west")
          line("bounds.east", "end")
        })
      },
    )
      + draw.move-to(name + ".end")
  )
  return (
    kind: "component",
    drawing: drawing,
    name: name,
    bounds: name + ".bounds",
    start: name + ".start",
    end: name + ".end",
    comp-start: name + ".bounds.west",
    comp-end: name + ".bounds.east",
  )
}

#let wiring(
  ..comp-styles,
  name: none,
  anchor: "center",
  origin: (0, 0),
  close: false,
) = {
  let styles = comp-styles.named()
  let comps = comp-styles.pos()
  let line-name(no) = if name != none { "segment-" + str(no) }
  let wrapper = if name == none { it => it } else {
    it => {
      group(name: name, anchor: anchor, {
        set-origin(origin)
        anchor("default", origin)
        it
      })
    }
  }

  let coordinate(coord) = (kind: "coordinate", value: coord)

  // Step 1: Labeling
  let labelled-comps = comps
    .map(c => {
      if type(c) == dictionary and "kind" in c {
        if c.kind in ("anchor", "component") {
          c
        } else {
          panic("Unknown kind: " + repr(kind))
        }
      } else {
        (
          kind: "coordinate",
          value: c,
        )
      }
    })
    .flatten()

  // Step 2: Evaluation
  // this is for accessing anchors
  let predraw = draw.on-layer(1, {
    labelled-comps
      .filter(c => c.kind != "anchor")
      .map(c => {
        if c.kind == "component" {
          c.drawing
        } else if c.kind == "coordinate" {
          draw.move-to(c.value)
        }
      })
      .join()
  })

  let result = predraw
  let coords = ()
  let line-args = ()
  let segment-no = 0
  let line-func = draw.line.with(..styles)

  for (i, c) in labelled-comps.enumerate() {
    if c.kind == "coordinate" {
      coords.push(c.value)
      line-args.push(c.value) // for drawing lines
    } else if c.kind == "anchor" {
      result += draw.anchor(c.name, coords.last())
    } else if c.kind == "component" {
      line-args.push(c.start)
      line-args.push(c.comp-start)
      result += line-func(..line-args, name: line-name(segment-no))
      segment-no += 1
      line-args = (c.comp-end, c.end)
      coords += (c.start, c.comp-start, c.comp-end, c.end)
    }
  }
  if line-args != () {
    result += line-func(..line-args, name: line-name(segment-no))
  }
  return wrapper(result)
}

#let resistor(
  name,
  start,
  end,
  width: 1,
  height: .5,
  segments: 4,
  ..args,
  style: (:),
) = {
  x-component(
    name,
    start,
    end,
    ..args,
    {
      draw.set-style(..style)
      decorations.zigzag(
        draw.line((0, 0), (width, 0)),
        amplitude: height,
        segments: segments,
      )
    },
  )
}

#let cmeter(
  ..args,
  radius: .4,
  fill: none,
  inside: none,
) = x-component(..args, {
  draw.circle(radius: radius, name: "circle", (0, 0), fill: fill)
  inside
})

#let ammeter = cmeter.with(inside: draw.content("circle.center", [A], name: "A"))
#let voltmeter = cmeter.with(inside: draw.content("circle.center", [V], name: "V"))
#let isource(
  ..args,
  symbol: ">",
  arrow-stroke: black,
  arrow-length: 0.5,
  invert: false,
) = cmeter(
  ..args,
  inside: {
    import draw: *
    line(
      (-arrow-length / 2, 0),
      (rel: (arrow-length, 0)),
      mark: (
        (if invert { "start" } else { "end" }): symbol,
        fill: arrow-stroke.paint,
      ),
      stroke: arrow-stroke,
      name: "arrow",
    )
  },
)

#let short(..args) = x-component(..args, {})


#canvas({
  import draw: *
  // x-component(
  //   "R1",
  //   (0, 0),
  //   (4, 2),
  //   {
  //     decorations.zigzag(line((0, 0), (1, 0)), amplitude: .5, segments: 3)
  //   },
  //   label: $R$,
  //   label2: [30 k],
  //   position: 30%,
  //   i: (label: $i_1$, pos: "->"),
  //   nodes: "*-*",
  //   v: (label: $V$, label-gap: 1fr, spread: 1.5fr),
  //   f: (label: $I$, stroke: red + 2pt, pos: "<_"),
  //   // debug: true,
  // )

  // set-origin("R1.end")

  // x-component(
  //   "R2",
  //   (0, 0),
  //   (4, 2),
  //   {},
  // )
  let resistor = resistor.with(style: (stroke: red + 1.5pt))
  wiring(
    resistor("r1", (0, 0), (0, 3), label: $R$, v: (label: $V_0$, pos: "_")),
    short("s1", (), (rel: (2, 0)), i: (label: $I_0$, distance: 50%, style: (fill: green, stroke: green))),
    resistor("r2", (), (rel: (3, 0)), label: $4 Omega$, nodes: "*-o"),
    isource("I1", (), ((), "|-", "r1.start"), invert: true, label: $5 "A"$, arrow-stroke: 1.5pt + red),
    "r1",
  )
  wiring(
    resistor("r3", "s1.end", ((), "|-", "r1"), label: $6 Omega$),
  )
})


