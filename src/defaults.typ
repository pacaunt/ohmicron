#let default-style = (
  component: (
    position: 50%,
    label: none,
    label2: none,
    i: (
      label: [],
      label-gap: .2,
      distance: 75%,
      pos: "->",
      mark: (
        symbol: ">",
        fill: black,
      ),
      style: (:),
    ),
    v: (
      label: [],
      label-gap: .2,
      plus: $+$,
      minus: $-$,
      pos: "->",
      spread: 1.2fr,
    ),
    f: (
      label: [],
      label-gap: .2,
      pos: "->",
      spread: 1.2fr,
      bend: 20deg,
      mark: (
        symbol: ">",
        fill: black,
      ),
      style: (
        stroke: black + 1pt,
      ),
    ),
    n: (
      pattern: "-",
      "*": (fill: black, symbol: "o"),
      "o": (fill: white, symbol: "o"),
    ),
    padding: none,
    label-gap: .2,
    label2-gap: auto,
    anchor: "center",
    debug: false,
  ),
  wiring: (:),
  resistor: (
    width: 1,
    height: .5,
    segments: 4,
    style: (:),
  ),
  cmeter: (
    radius: .4,
  ),
  ammeter: (
    radius: .4, 
  ), 
  voltmeter: (
    radius: .4, 
  ), 
  isource: (
    radius: .4, 
    arrow-stroke: 1pt + black, 
    arrow-length: 0.5,
    symbol: ">"
  ), 
  battery: (
    height: .8, 
    plus: (:), 
    minus: (stroke: 2.5pt), 
    gap: 0.2, 
    ratio: 50%,
  ), 
  switch: (
    width: 1, 
    angle: 20deg, 
    n: (
      pattern: "-",
      "*": (fill: black, symbol: "o"),
      "o": (fill: white, symbol: "o"),
    )
  )
)