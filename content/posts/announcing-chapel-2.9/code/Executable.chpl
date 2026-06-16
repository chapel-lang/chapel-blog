use DynamicLoading;

proc main() {
  const path = "./lib/libLibrary." + chapelLibraryExtension;
  var lib = binary.load(path);
  type testType = proc(): void;
  const testProc = try! lib.retrieve("test1", testType);
  testProc();
}

// Provides the correct extension based on platform, e.g., '.dylib' or '.so'.
inline proc chapelLibraryExtension param {
  use ChplConfig;
  return if CHPL_TARGET_PLATFORM == 'darwin' then 'dylib' else 'so';
}
