(* Tests for sml-buffer. *)

structure BufferTests =
struct
  open Harness

  fun run () =
    let
      val () = section "Buffer basics"

      val () = checkInt "empty length is 0" (0, Buffer.length (Buffer.empty ()))
      val () = checkBool "empty isEmpty" (true, Buffer.isEmpty (Buffer.empty ()))

      val () = checkString "single addString"
                 ("hello", Buffer.build (fn b => Buffer.addString b "hello"))

      val () = checkString "addChar sequence"
                 ("abc", Buffer.build (fn b =>
                    (Buffer.addChar b #"a"; Buffer.addChar b #"b"; Buffer.addChar b #"c")))

      val () = checkString "mixed append"
                 ("ab12", Buffer.build (fn b =>
                    (Buffer.addString b "ab"; Buffer.addString b "12")))

      val () = checkString "empty addString is noop"
                 ("xy", Buffer.build (fn b =>
                    (Buffer.addString b "x"; Buffer.addString b ""; Buffer.addString b "y")))

      val () = section "Buffer length / sub"

      val b1 = Buffer.empty ()
      val () = Buffer.addString b1 "abcdef"
      val () = checkInt "length after append" (6, Buffer.length b1)
      val () = check "sub 0" (Buffer.sub b1 0 = #"a")
      val () = check "sub 5" (Buffer.sub b1 5 = #"f")
      val () = checkRaises "sub out of range raises" (fn () => Buffer.sub b1 6)
      val () = checkRaises "sub negative raises" (fn () => Buffer.sub b1 ~1)

      val () = section "Buffer clear / reuse"

      val () = Buffer.clear b1
      val () = checkInt "length after clear" (0, Buffer.length b1)
      val () = Buffer.addString b1 "new"
      val () = checkString "reuse after clear" ("new", Buffer.contents b1)

      val () = section "Buffer growth (large concat)"

      (* 10k single-char appends must equal the expected concatenation and
         exercise several doublings of the backing array. *)
      val n = 10000
      val expected = String.concat (List.tabulate (n, fn _ => "x"))
      val big = Buffer.build (fn b =>
                  let fun loop i = if i >= n then () else (Buffer.addChar b #"x"; loop (i + 1))
                  in loop 0 end)
      val () = checkInt "large length" (n, String.size big)
      val () = checkBool "large content matches" (true, big = expected)

      val () = section "Buffer addBuffer"

      val src = Buffer.empty ()
      val () = Buffer.addString src "world"
      val () = checkString "addBuffer appends source"
                 ("hello world", Buffer.build (fn b =>
                    (Buffer.addString b "hello "; Buffer.addBuffer b src)))
      val () = checkInt "addBuffer leaves source intact" (5, Buffer.length src)

      val () = section "Buffer addSubstring"

      val () = checkString "addSubstring slice"
                 ("cde", Buffer.build (fn b =>
                    Buffer.addSubstring b (Substring.substring ("abcdef", 2, 3))))

      val () = section "Buffer concat helpers"

      val () = checkString "concat" ("abc", Buffer.concat ["a", "b", "c"])
      val () = checkString "concat empty" ("", Buffer.concat [])
      val () = checkString "concatWith" ("a,b,c", Buffer.concatWith "," ["a", "b", "c"])
      val () = checkString "concatWith single" ("a", Buffer.concatWith "," ["a"])
      val () = checkString "concatWith empty" ("", Buffer.concatWith "," [])
    in
      ()
    end
end
