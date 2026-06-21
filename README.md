# sml-buffer

[![CI](https://github.com/sjqtentacles/sml-buffer/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-buffer/actions/workflows/ci.yml)

A small, portable growable byte/char buffer for Standard ML.

`sml-buffer` gives you a mutable, doubling buffer for assembling strings out
of many small fragments without the O(n^2) cost of repeated `^`
concatenation. It is the workhorse for building HTTP responses, serialized
messages, and any other place a server emits a stream of pieces.

Pure Standard ML using only the Basis library -- no dependencies. Verified on
**MLton** and **Poly/ML**; the test suite produces byte-for-byte identical
output across both.

## API

From `structure Buffer`:

```sml
type buffer
val new          : int -> buffer          (* initial capacity hint *)
val empty        : unit -> buffer
val length       : buffer -> int
val isEmpty      : buffer -> bool
val addChar      : buffer -> char -> unit
val addString    : buffer -> string -> unit
val addSubstring : buffer -> substring -> unit
val addBuffer    : buffer -> buffer -> unit
val contents     : buffer -> string
val sub          : buffer -> int -> char
val clear        : buffer -> unit
val build        : (buffer -> unit) -> string
val concat       : string list -> string
val concatWith   : string -> string list -> string
```

### Example

```sml
(* Build a string by appending into a fresh buffer. *)
val s = Buffer.build (fn b =>
  ( Buffer.addString b "Status: "
  ; Buffer.addString b (Int.toString 200)
  ; Buffer.addChar b #"\n" ))
(* s = "Status: 200\n" *)

(* One-shot concatenation. *)
val joined = Buffer.concatWith ", " ["a", "b", "c"]   (* "a, b, c" *)
```

## Build & test

Requires [MLton](http://mlton.org/) and/or [Poly/ML](https://polyml.org/).

```sh
make test        # build + run the suite under MLton
make test-poly   # run the suite under Poly/ML
make all-tests   # both
make clean
```

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-buffer
smlpkg sync
```

Reference `lib/github.com/sjqtentacles/sml-buffer/sml-buffer.mlb` from your own
`.mlb` (MLton / MLKit), or feed `sources.mlb` to `tools/polybuild` (Poly/ML).

## Layout

```
sml.pkg                                       smlpkg manifest
Makefile                                      MLton + Poly/ML targets
.github/workflows/ci.yml                      CI: MLton + Poly/ML
lib/github.com/sjqtentacles/sml-buffer/
  buffer.sig    BUFFER signature
  buffer.sml    Buffer structure (doubling CharArray)
  sources.mlb   ordered source list
  sml-buffer.mlb  public basis
test/
  harness.sml   shared assertion harness
  test.sml      the suite (23 checks)
  entry.sml     defines main
  main.sml      MLton top-level call
tools/polybuild Poly/ML build wrapper
```

## Tests

23 deterministic checks covering append (char/string/substring/buffer),
length and bounds-checked `sub`, `clear`/reuse, growth across several
doublings (10k appends), and the `concat`/`concatWith` helpers. Run
`make all-tests` to verify identical output under both compilers.

## License

MIT. See [LICENSE](LICENSE).
