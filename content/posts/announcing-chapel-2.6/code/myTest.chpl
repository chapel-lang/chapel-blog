use UnitTest;

proc myTest1(test: borrowed Test) throws {
  // test code here
  writeln("Test 1 passed");
}

proc myTest2(test: borrowed Test) throws {
  // test code here
  writeln("Test 2 passed");
}

UnitTest.main();                                                              
