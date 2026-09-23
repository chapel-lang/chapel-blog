use IO;
record myObject {
  var name: string;
  var id: int;
}
class ParseError: Error {
  proc init(msg: string) {
    super.init(msg);
  }
}
record parser {
  var reader: fileReader(?);
  proc init(filename: string) {
    reader = openReader(filename);
  }
  proc deinit() {
    reader.close();
  }
  proc hasMore() throws {
    reader.mark();
    defer reader.revert();
    try {
      reader.read(string);
    } catch e: EofError {
      return false;
    }
    return true;
  }
  proc next() throws {
    var line = reader.readLine(stripNewline=true);
    return parseLine(line);
  }
}
proc checkParts(parts) throws {
  if parts.size != 2 {
    throw new ParseError("Invalid line format: " + " ".join(parts));
  }
}
proc parseInt(s: string) throws {
  try {
    return s:int;
  } catch {
    throw new ParseError("Invalid ID format: " + s);
  }
  return 0;
}
proc parseLine(line: string) throws {
  var parts = line.split(" ");
  checkParts(parts);
  var obj = new myObject(parts[0], parseInt(parts[1]));
  return obj;
}
