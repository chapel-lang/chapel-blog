record myType : contextManager {
  proc enterContext(): int { return 42; }
  proc exitContext(in error: owned Error?) {}
}

manage (new myType()) as managedValue {
    
}

record myTypeNoContext : contextManager {}