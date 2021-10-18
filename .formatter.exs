# Used by "mix format"
locals_without_parens = [
  poller: 2,
  poller: 1,
  matcher: 1,
  handle: 2,
  handle: 3,
  plug: 1,
  plug: 2
]

[
  locals_without_parens: locals_without_parens,
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [locals_without_parens: locals_without_parens]
]
