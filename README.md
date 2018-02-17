This lists and extract the resources embedded inside an executable file (`.exe`, `.dll`, etc.).


To list the resources use, e.g.:

	ResourceExtractor list Procmon.exe

Which will show something like:

	BINRES/RCDRIVERNT/1033  73480
	BINRES/1308/1033        1186440
	RT_CURSOR/23/1033       308
	RT_CURSOR/24/1033       308
	RT_BITMAP/400/1033      2920
	RT_ICON/1/1033  3752

The first column is the resource id and the second the resource size.


To extract a specific resource into a file use, e.g.:

	ResourceExtractor extract Procmon.exe BINRES/1308/1033 ProcmonAmd64.exe


The single executable `ResourceExtractor.exe` was created using [LibZ](https://github.com/MiloszKrajewski/LibZ):

	libz inject-dll --assembly ResourceExtractor.exe --include *.dll --move


This uses the [Vestris.ResourceLib C# File Resource Management Library](https://github.com/resourcelib/resourcelib) library.
