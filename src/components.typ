#import "dependencies.typ": *
#import "defaults.typ": default-style
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
#let component(
  name,
  start,
  end,
  i: none,
  v: none,
  f: none,
  n: none,
  debug: false,
  // Extra drawing
  append: none,
  // The component
  body-func,
  ..styles,
) = {
  let styles = styles.named()
  let drawing = draw.get-ctx(ctx0 => (
    draw.group(
      name: name,
      {
        let default = cetz.styles.resolve(ctx0.style, root: "component")
        let styles = utils.merge-dict(default, styles)

        import draw: *

        let comp(ctx, center) = group(name: "body", anchor: styles.anchor, padding: styles.padding, {
          set-origin(center)
          anchor("default", (0, 0))
          if body-func(ctx) == none {
            anchor("center", (0, 0))
          }
          body-func(ctx)
        })

        let cover = if debug { it => it } else { hide }

        // place to find the sizes
        cover(scope(get-ctx(ctx => {
          stroke(gray)
          comp(ctx, (start, styles.position, end))
        })))

        get-ctx(ctx => {
          let (ctx, a, b) = cetz.coordinate.resolve(ctx, start, end)
          let c = vector.lerp(a, b, styles.position / 100%)
          let ang = vector.angle2(a, b)

          let (ctx, SW, NE) = (ctx, center, center)
          let (width, height) = (1e-8, 1e-8)

          if body-func(ctx) != none {
            (ctx, SW, NE) = cetz.coordinate.resolve(ctx, "body.south-west", "body.north-east")
            (width, height) = vector.sub(NE, SW).slice(0, 2) // size of the component
          }

          let (label1-gap, label2-gap) = if styles.label2-gap == auto {
            (styles.label-gap,) * 2
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
            comp(ctx, c)
            // The Labels
            content(
              "bounds.north",
              std.rotate(ang, styles.label, reflow: true),
              anchor: "south",
              angle: ang,
              padding: (bottom: label1-gap),
              name: "label-north",
            )
            content(
              "bounds.south",
              std.rotate(ang, styles.label2, reflow: true),
              anchor: "north",
              angle: ang,
              padding: (top: label2-gap),
              name: "label-south",
            )
          })

          // Drawing current
          if i != none {
            let i = i
            if type(i) != dictionary { i = (label: i) }
            i = utils.merge-dict(default-style.component.i, i)
            // resolving lengths
            i.label-gap = utils.resolve-length(i.label-gap, full: height)

            let (up, right) = utils.parse-flow(i.pos)
            let coor = (a, i.distance, b)

            mark(
              coor,
              if right { b } else { a },
              anchor: "center",
              ..i.mark,
            )
            content(
              coor,
              std.rotate(ang, i.label, reflow: true),
              anchor: if up { "south" } else { "north" },
              padding: ({ if up { "bottom" } else { "top" } }: i.label-gap),
              angle: ang,
              name: "i-label",
            )
          }

          // Drawing voltage
          if v != none {
            let v = v
            if type(v) != dictionary { v = (label: v) }
            v = utils.merge-dict(default-style.component.v, v)
            // resolving lengths
            v.label-gap = utils.resolve-length(v.label-gap, full: height)
            v.spread = utils.resolve-length(v.spread, full: width)

            let (right, up) = utils.parse-volt(v.pos)
            let v-center = "bounds" + if up { ".north" } else { ".south" }

            content(
              v-center,
              std.rotate(ang, v.label, reflow: true),
              anchor: if up { "south" } else { "north" },
              padding: ({ if up { "bottom" } else { "top" } }: v.label-gap),
              angle: ang,
              name: "v-label",
            )

            let v-sign-pos = (
              (to: v-center, rel: (-v.spread / 2, 0)),
              (to: v-center, rel: (v.spread / 2, 0)),
            )
            if not right { v-sign-pos = v-sign-pos.rev() }

            scope({
              rotate(ang, origin: c)
              content(
                v-sign-pos.first(),
                std.rotate(ang, v.plus, reflow: true),
                anchor: if up { "south" } else { "north" },
                padding: ({ if up { "bottom" } else { "top" } }: v.label-gap),
                angle: ang,
                name: "v-plus",
              )
              content(
                v-sign-pos.last(),
                std.rotate(ang, v.minus, reflow: true),
                anchor: if up { "south" } else { "north" },
                padding: ({ if up { "bottom" } else { "top" } }: v.label-gap),
                angle: ang,
                name: "v-minus",
              )
            })
          }

          // Drawing flows
          if f != none {
            let f = f
            if type(f) != dictionary { f = (label: f) }
            f = utils.merge-dict(default-style.component.f, f)
            f.label-gap = utils.resolve-length(f.label-gap, full: height)
            f.spread = utils.resolve-length(f.spread, full: width)

            let (right, up) = utils.parse-volt(f.pos)
            let f-center = "bounds" + if up { ".north" } else { ".south" }
            scope({
              rotate(ang, origin: c)
              bezier(
                (to: f-center, rel: (-f.spread / 2, 0)),
                (to: f-center, rel: (f.spread / 2, 0)),
                (to: f-center, rel: (if up { 90deg } else { -90deg }, f.spread / 2 / calc.sin(f.bend))),
                mark: ((if right { "end" } else { "start" }): f.mark),
                name: "flow",
                ..f.style,
              )
              content(
                "flow.50%",
                std.rotate(ang, f.label, reflow: true),
                anchor: if up { "south" } else { "north" },
                padding: ({ if up { "bottom" } else { "top" } }: f.label-gap),
                angle: ang,
                name: "f-label",
              )
            })
          }

          // Draw nodes
          if n != none {
            let n = n
            if type(n) != dictionary { n = (pattern: n) }
            n = utils.merge-dict(default-style.component.n, n)
            let (end-mark, start-mark) = utils.parse-nodes(
              n.pattern,
              styles: n,
            )
            on-layer(1, {
              mark(a, b, anchor: "center", ..start-mark)
              mark(b, a, anchor: "center", ..end-mark)
            })
          }
        })
        cover({
          line("start", "bounds.west")
          line("bounds.east", "end")
        })
      },
    )
      + draw.move-to(name + ".end")
  ))

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

#let to(
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

  let result = {
    predraw // for accessing anchors
    draw.get-ctx(ctx => {
      let solved-coords = labelled-comps
        .map(c => {
          if c.kind == "coordinate" {
            c.value = cetz.coordinate.resolve(ctx, c.value).last()
            return c
          } else if c.kind == "component" {
            return c
              .pairs()
              .map(((k, v)) => if k
                in (
                  "start",
                  "comp-start",
                  "end",
                  "comp-end",
                ) {
                (k, cetz.coordinate.resolve(ctx, v).last())
              } else { (k, v) })
              .to-dict()
          }
        })
        .filter(c => c != none)
      // The function for drawing the wires
      let styles = utils.resolve-style(ctx.style, styles, root: "wiring")
      let line-func = draw.line.with(..styles)
      // Arrange the components, for a more pleasing when `close` is set to true.
      let arranged-comps = ()
      if not close {
        arranged-comps = solved-coords
      } else {
        if solved-coords.all(c => c.kind != "component") {
          line-func = line-func.with(close: true)
          arranged-comps = solved-coords
        } else {
          let (idx, first) = utils.find-next(-1, c => c.kind == "component", arr: solved-coords)

          // starting the drawing from the first component breakpoint.
          arranged-comps = (
            solved-coords.slice(idx, none)
              + solved-coords.slice(0, idx)
              + (coordinate(first.start), coordinate(first.comp-start))
          )
        }
      }

      // The drawing part
      let line-args = ()
      let last-coords
      let segment-no = 0
      for (i, c) in arranged-comps.enumerate() {
        if c.kind == "component" {
          if close and i == 0 {
            line-args.push(c.comp-end)
            line-args.push(c.end)
          } else {
            line-args.push(c.start)
            line-args.push(c.comp-start)
            line-func(..line-args, name: line-name(segment-no))
            segment-no += 1
            line-args = (c.comp-end, c.end)
          }
        } else if c.kind == "anchor" {
          draw.anchor(c.name, last-coords)
        } else if c.kind == "coordinate" {
          line-args.push(c.value)
          last-coords = c.value
        }
      }

      if line-args.len() > 0 {
        line-func(..line-args, name: line-name(segment-no))
      }
    })
  }
  return wrapper(result)
}


#let resistor(
  name,
  start,
  end,
  ..args,
  style: (:),
) = {
  component(name, start, end, ..args, ctx => {
    let styles = utils.resolve-style(ctx.style, style, root: "resistor")
    decorations.zigzag(
      draw.line((0, 0), (styles.width, 0)),
      amplitude: styles.height,
      segments: styles.segments,
      ..styles,
    )
  })
}

#let cmeter(
  ..args,
  inside: ctx => none,
  style: (:),
  id: "cmeter",
) = component(..args, ctx => {
  let styles = utils.resolve-style(ctx.style, style, root: id)
  draw.set-style(..styles)
  draw.circle(radius: styles.radius, name: "circle", (0, 0), ..styles)
  inside(ctx)
})

#let ammeter = cmeter.with(inside: ctx => draw.content("circle.center", [A], name: "A"), id: "ammeter")

#let voltmeter = cmeter.with(inside: ctx => draw.content("circle.center", [V], name: "V"), id: "voltmeter")

#let isource(
  ..args,
  style: (:),
  invert: false,
) = cmeter(
  ..args,
  style: style,
  id: "isource",
  inside: ctx => {
    import draw: *
    let styles = utils.resolve-style(ctx.style, style, root: "isource")
    line(
      (-styles.arrow-length / 2, 0),
      (rel: (styles.arrow-length, 0)),
      mark: (
        (if invert { "start" } else { "end" }): styles.symbol,
        fill: styles.arrow-stroke.paint,
      ),
      stroke: styles.arrow-stroke,
      name: "arrow",
    )
  },
)

#let short(..args) = component(..args, ctx => {})

#let battery(name, start, end, ..args, style: (:), invert: false) = {
  component(name, start, end, ..args, ctx => {
    import draw: *
    let styles = utils.resolve-style(ctx.style, style, root: "battery")
    draw.set-style(..styles)
    if invert {
      scale(x: -100%)
    }
    line(..utils.spread((0, 0), 90deg, styles.height), ..styles.plus, name: "plus")
    line(
      ..utils.spread((rel: (styles.gap, 0), to: "plus.mid"), 90deg, styles.height * styles.ratio / 100%),
      ..styles.minus,
      name: "minus",
    )
  })
}

#let switch(name, start, end, ..args, style: (:), invert: false, close: false) = {
  component(
    name,
    start,
    end,
    ..args,
    ctx => {
      import draw: *
      let styles = utils.resolve-style(ctx.style, style, root: "switch")
      draw.set-style(..styles)
      let (start, end) = utils.spread((0, 0), 0deg, styles.width)

      if type(styles.n) != dictionary { styles.n = (pattern: styles.n) }
      styles.n = utils.resolve-style(ctx.style, styles, root: "switch").n
      let (start-mark, end-mark) = utils.parse-nodes(styles.n.pattern, styles: styles.n)

      mark(start, end, ..start-mark, anchor: "center")
      mark(end, start, ..end-mark, anchor: "center")

      on-layer(-1, {
        if close { styles.angle = 0deg }
        line(start, (rel: (styles.angle, styles.width)))
        hide(line(start, (rel: (-styles.angle, styles.width))), bounds: true)
      })
    },
  )
}

#canvas({
  import draw: *
  set-style(..default-style)
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
  // let resistor = resistor.with(style: (stroke: red + 1.5pt))
  set-style(resistor: (stroke: red + 1.5pt), isource: (arrow-stroke: red + 1.5pt), battery: (stroke: red), switch: (stroke: red, n: ("*": (fill: red, stroke: 0pt))))
  to(
    resistor("r1", (0, 0), (0, 3), label: $R$, v: (label: $V_0$, pos: "_"), f: $I$),
    short("s1", (), (rel: (2, 0)), i: (label: $I_0$, distance: 50%, style: (fill: green, stroke: green))),
    resistor("r2", (), (rel: (3, 0)), label: $4 Omega$, n: "*-o"),
    battery("b1", (), ((), "|-", "r1"), label: $V$),
    close: true,
  )
  to(
    resistor("r3", "s1.end", ((), "|-", "r1"), label: $6 Omega$),
  )

  set-origin((0, -4))
  to(
    switch("s1", (0, 0), (3, 0), style: (n: "*-*"), close: false),
    resistor("r1", (), (rel: (0, -3)), label: $6 Omega$), 
    battery("b1", (), ((), "-|", "r1"), label: $9"V"$), 
    close: true
  )
})


