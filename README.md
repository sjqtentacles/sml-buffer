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
val capacity     : buffer -> int           (* allocated bytes (>= length) *)

(* appends (mutate in place) *)
val addChar      : buffer -> char -> unit
val addString    : buffer -> string -> unit
val addSubstring : buffer -> substring -> unit
val addBuffer    : buffer -> buffer -> unit
val addChars     : buffer -> char -> int -> unit   (* char repeated n times *)
val addInt       : buffer -> int -> unit           (* decimal rendering *)
val addLine      : buffer -> string -> unit        (* string + newline *)

(* read *)
val contents     : buffer -> string
val contentsSlice : buffer -> int -> int -> string (* [start, start+len) *)
val sub          : buffer -> int -> char
val last         : buffer -> char option
val appChars     : (char -> unit) -> buffer -> unit
val foldChars    : (char * 'a -> 'a) -> 'a -> buffer -> 'a

(* mutate *)
val update       : buffer -> int -> char -> unit   (* overwrite byte i *)
val clear        : buffer -> unit
val truncate     : buffer -> int -> unit           (* keep first n bytes *)
val reserve      : buffer -> int -> unit           (* grow capacity *)

(* one-shot builders *)
val build        : (buffer -> unit) -> string
val concat       : string list -> string
val concatWith   : string -> string list -> string
```

`sub`, `update`, and `contentsSlice` raise `Subscript` on an out-of-range
index; `last` returns `NONE` for an empty buffer. `truncate b n` drops
everything past the first `n` bytes (a no-op when `n >= length`, clears when
`n < 0`) while keeping the allocated capacity; `reserve` only ever grows it.

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

(* Render a small table with repeats, ints, and line breaks. *)
val report = Buffer.build (fn b =>
  ( Buffer.addLine b "name   score"
  ; Buffer.addChars b #"-" 12; Buffer.addChar b #"\n"
  ; Buffer.addString b "alice  "; Buffer.addInt b 42; Buffer.addChar b #"\n" ))

(* Read back individual bytes / slices. *)
val sliced = Buffer.contentsSlice (let val b = Buffer.empty ()
                                   in Buffer.addString b "abcdef"; b end) 2 3  (* "cde" *)
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
  test.sml      the suite (53 checks)
  entry.sml     defines main
  main.sml      MLton top-level call
tools/polybuild Poly/ML build wrapper
```

## Tests

53 deterministic checks covering append (char/string/substring/buffer), the
`addChars`/`addInt`/`addLine` helpers, `capacity`/`reserve`/`truncate`,
`last`/`update`/`contentsSlice` with `Subscript` bounds checks,
`appChars`/`foldChars` iteration, length and bounds-checked `sub`,
`clear`/reuse, growth across several doublings (10k appends), and the
`concat`/`concatWith` helpers. Run `make all-tests` to verify identical output
under both compilers.

## License

MIT. See [LICENSE](LICENSE).
