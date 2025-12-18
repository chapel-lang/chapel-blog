use Debugger;

proc main() {
  on Locales[1] {
    var myArr = [i in 1..10] i;
    breakpoint;
    on Locales[0] {
      writeln(myArr);
      breakpoint;
    }
  }
}
