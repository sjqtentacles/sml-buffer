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

      val () = section "Buffer capacity / reserve / truncate"

      val () = checkBool "capacity >= length"
                 (true, Buffer.capacity (Buffer.empty ()) >= 0)
      val () = checkInt "new hint sets capacity >= hint"
                 (100, Int.min (100, Buffer.capacity (Buffer.new 100)))
      val cb = Buffer.empty ()
      val () = Buffer.reserve cb 1000
      val () = checkBool "reserve grows capacity" (true, Buffer.capacity cb >= 1000)
      val () = checkInt "reserve keeps length 0" (0, Buffer.length cb)
      val () = Buffer.addString cb "hello"
      val capBefore = Buffer.capacity cb
      val () = Buffer.reserve cb 4
      val () = checkBool "reserve never shrinks" (true, Buffer.capacity cb = capBefore)

      val tb = Buffer.empty ()
      val () = Buffer.addString tb "abcdefgh"
      val () = Buffer.truncate tb 3
      val () = checkString "truncate to 3" ("abc", Buffer.contents tb)
      val () = Buffer.truncate tb 100
      val () = checkString "truncate beyond length is noop" ("abc", Buffer.contents tb)
      val () = Buffer.truncate tb ~1
      val () = checkInt "truncate negative clears" (0, Buffer.length tb)

      val () = section "Buffer addChars / addInt / addLine"

      val () = checkString "addChars repeats"
                 ("aaaaa", Buffer.build (fn b => Buffer.addChars b #"a" 5))
      val () = checkString "addChars zero is noop"
                 ("", Buffer.build (fn b => Buffer.addChars b #"a" 0))
      val () = checkString "addChars negative is noop"
                 ("x", Buffer.build (fn b => (Buffer.addString b "x"; Buffer.addChars b #"a" ~3)))
      val () = checkString "addInt positive"
                 ("42", Buffer.build (fn b => Buffer.addInt b 42))
      val () = checkString "addInt negative"
                 ("~7", Buffer.build (fn b => Buffer.addInt b ~7))
      val () = checkString "addInt sequence"
                 ("1,2,3", Buffer.build (fn b =>
                    (Buffer.addInt b 1; Buffer.addChar b #","; Buffer.addInt b 2;
                     Buffer.addChar b #","; Buffer.addInt b 3)))
      val () = checkString "addLine appends newline"
                 ("one\ntwo\n", Buffer.build (fn b =>
                    (Buffer.addLine b "one"; Buffer.addLine b "two")))

      val () = section "Buffer last / update / contentsSlice"

      val () = checkBool "last empty is NONE" (true, Buffer.last (Buffer.empty ()) = NONE)
      val lb = Buffer.empty ()
      val () = Buffer.addString lb "abcdef"
      val () = checkBool "last char" (true, Buffer.last lb = SOME #"f")
      val () = Buffer.update lb 0 #"Z"
      val () = checkString "update in place" ("Zbcdef", Buffer.contents lb)
      val () = checkInt "update keeps length" (6, Buffer.length lb)
      val () = checkRaises "update out of range raises" (fn () => Buffer.update lb 6 #"x")
      val () = checkRaises "update negative raises" (fn () => Buffer.update lb ~1 #"x")
      val () = checkString "contentsSlice mid" ("cde", Buffer.contentsSlice lb 2 3)
      val () = checkString "contentsSlice empty len" ("", Buffer.contentsSlice lb 2 0)
      val () = checkString "contentsSlice whole" ("Zbcdef", Buffer.contentsSlice lb 0 6)
      val () = checkRaises "contentsSlice overrun raises" (fn () => Buffer.contentsSlice lb 4 5)
      val () = checkRaises "contentsSlice negative start raises" (fn () => Buffer.contentsSlice lb ~1 2)

      val () = section "Buffer appChars / foldChars"

      val ab = Buffer.empty ()
      val () = Buffer.addString ab "hello"
      val collected = ref []
      val () = Buffer.appChars (fn c => collected := c :: !collected) ab
      val () = checkString "appChars visits in order"
                 ("hello", String.implode (List.rev (!collected)))
      val () = checkInt "foldChars counts" (5, Buffer.foldChars (fn (_, a) => a + 1) 0 ab)
      val () = checkString "foldChars reverse"
                 ("olleh", String.implode (Buffer.foldChars (fn (c, a) => c :: a) [] ab))
      val () = checkInt "foldChars empty" (0, Buffer.foldChars (fn (_, a) => a + 1) 0 (Buffer.empty ()))
    in
      ()
    end
end
