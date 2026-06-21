(* entry.sml

   Defines `main : unit -> unit`, the entry point used by both compilers.
   Runs every suite, prints the harness summary, and exits with a status
   code reflecting success. Kept apart from main.sml so Poly/ML can `use`
   it (defining `main`) and export it without running the suite at compile
   time. *)

fun runAllSuites () =
  ( Harness.reset ()
  ; BufferTests.run ()
  ; Harness.run () )

fun main () =
  OS.Process.exit
    (if runAllSuites () then OS.Process.success else OS.Process.failure)
