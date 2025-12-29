#import "dependencies.typ": cetz

#let spread(center, angle, length) = {
  ((to: center, rel: (angle, -length / 2)), (to: center, rel: (angle, length / 2)))
}

#let merge-dict = cetz.util.merge-dictionary.with(overwrite: true)

#let resolve-style(ctx, default: none, styles, root: none) = {
  if default == none {
    default = cetz.styles.resolve(ctx, root: root)
  }
  merge-dict(default, styles)
}
/// Parse mark notation
/// * means having a filled mark there,
///
#let parse-nodes(
  txt,
  styles: (
    "*": (fill: black, symbol: "o"),
    "o": (symbol: "o"),
  ),
) = {
  let (start, end) = txt.split("-")
  let out = (:)

  for (mark, pos) in (start, end).zip(("start", "end")) {
    if mark == "*" {
      out.insert(pos + "-mark", styles.at("*"))
    } else if mark == "o" {
      out.insert(pos + "-mark", styles.at("o"))
    } else {
      out.insert(pos + "-mark", ())
    }
  }
  return out
}

// #parse-marked("o-o")\
// #parse-marked("*-")\
// #parse-marked("-*")\
// #parse-marked("o-")\
// #parse-marked("-")

#let parse-flow(txt) = {
  let out = (
    up: true,
    right: true,
    before: true,
  )
  if txt.contains("_") {
    out.up = false
  }
  if txt.contains("<") {
    out.right = false
  }
  if txt.contains(regex("\-[><]")) {
    out.before = false
  }

  return out
}

// #parse-flow("->")\
// #parse-flow(">-")\
// #parse-flow("_<")\
// #parse-flow("<-")\
// #parse-flow("_>")\

#let parse-volt(txt) = {
  let out = (
    up: true,
    right: true,
  )
  if txt.contains("_") { out.up = false }
  if txt.contains(regex("[\-]*[\_]*<")) { out.right = false }
  return out
}

// #parse-volt("<")

// 1fr => multiples
// 100% => ratio
// 1.2 => absolute length
#let resolve-length(len, full: 1) = if type(len) == ratio {
  len / 100% * full
} else if type(len) == fraction {
  len / 1fr * full
} else {
  len
}

#let find-next(
  index, // current index
  cond, // condition to find
  arr: (), // the array
  // -> (index, value)
) = {
  let len = arr.len()
  range(len).zip(arr).filter(((i, v)) => { i > index and cond(v) }).first()
}

// #let arr = ((9, "a"), (9, "b"), (8, "d"), (9, "c"))
// #find-next(1, v => v.at(0) == 9, arr: arr)
// -> (3, (9, "c"))

