use DynamicLoading;

proc main() {
  // specify the dynamic library's name and load it:
  const libName = "./lib/libLibrary." + chapelLibraryExtension,
        lib = binary.load(libName);

  // capture the type signature of the procedure we want to call
  type testType = proc(): void;

  // load a procedure named "test1" with the specified signature...
  const testProc = try! lib.retrieve("test1", testType);

  // ...and call it
  testProc();
}

// Based on the platform, compute the appropriate file extension to use.
// (e.g., '.dylib' or '.so')
//
inline proc chapelLibraryExtension param {
  use ChplConfig;
  return if CHPL_TARGET_PLATFORM == 'darwin' then 'dylib' else 'so';
}
