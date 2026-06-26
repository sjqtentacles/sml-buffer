(* buffer.sig

   A growable, mutable byte/char buffer for assembling strings without the
   O(n^2) cost of repeated `^` concatenation. Backed by a doubling char
   array; `contents` materializes the accumulated bytes as a string.

   This is the workhorse for building HTTP responses, serialized messages,
   and any other place a server emits a stream of small fragments. *)

signature BUFFER =
sig
  type buffer

  (* Create an empty buffer. The hint is an initial capacity in bytes; it is
     only an optimization (a non-positive hint is clamped to a small default). *)
  val new       : int -> buffer
  val empty     : unit -> buffer

  (* Current number of bytes held. *)
  val length    : buffer -> int
  val isEmpty   : buffer -> bool
  (* Current allocated capacity in bytes (>= length). *)
  val capacity  : buffer -> int

  (* Append operations (all mutate the buffer in place). *)
  val addChar   : buffer -> char -> unit
  val addString : buffer -> string -> unit
  val addSubstring : buffer -> substring -> unit
  (* Append the contents of another buffer (the source is not modified). *)
  val addBuffer : buffer -> buffer -> unit
  (* Append the char `c` repeated `n` times (n <= 0 appends nothing). *)
  val addChars  : buffer -> char -> int -> unit
  (* Append the decimal rendering of an int (e.g. ~12 -> "~12"). *)
  val addInt    : buffer -> int -> unit
  (* Append a string followed by a newline. *)
  val addLine   : buffer -> string -> unit

  (* Materialize. `contents` returns all accumulated bytes; `sub` reads a
     single byte (raises Subscript if out of range); `last` is the final byte
     (NONE when empty). *)
  val contents  : buffer -> string
  val sub       : buffer -> int -> char
  val last      : buffer -> char option
  (* Materialize a sub-range [start, start+len) as a string. Raises Subscript
     if the range is out of bounds. *)
  val contentsSlice : buffer -> int -> int -> string

  (* Overwrite the byte at index i in place (raises Subscript if out of range;
     does not change the length). *)
  val update    : buffer -> int -> char -> unit

  (* Iterate over the live bytes in order. *)
  val appChars  : (char -> unit) -> buffer -> unit
  val foldChars : (char * 'a -> 'a) -> 'a -> buffer -> 'a

  (* Reset to empty, keeping the allocated capacity for reuse. *)
  val clear     : buffer -> unit
  (* Drop everything past the first `n` bytes (n >= length is a no-op; n < 0
     clears). Keeps the allocated capacity. *)
  val truncate  : buffer -> int -> unit
  (* Ensure capacity for at least `n` total bytes (never shrinks). *)
  val reserve   : buffer -> int -> unit

  (* Build a string by running a function that appends into a fresh buffer.
     `build (fn b => ...)` is the idiomatic entry point. *)
  val build     : (buffer -> unit) -> string

  (* Concatenate a list of strings via a single buffer pass. *)
  val concat    : string list -> string
  val concatWith : string -> string list -> string
end
