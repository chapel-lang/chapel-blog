use Reflection;
param lineNo = getLineNumber();

compilerWarning("This is bad, chief!", 0);
compilerError("It's so over. Error in file " + getFileName(), errorDepth=0);