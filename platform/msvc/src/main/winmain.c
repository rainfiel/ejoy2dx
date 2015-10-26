#include <Windows.h>

int main(int argc, char *argv[]);

#if defined(_DEBUG)

#include <stdio.h>

bool has_exception = true;

static int
exit_event() {
	if (has_exception) {
		printf("\n\nThe process will exit.\n");
		system("pause");
	}
	return 0;
}

int __stdcall
WinMain(HINSTANCE /*hInstance*/, HINSTANCE /*hPrevInstance*/, LPSTR /*lpCmdLine*/, int /*nCmdShow*/) {
	int argc = __argc;
	if (strcmp(__argv[argc-1], "no_console") == 0) {
		argc--;
	} else {
		FILE* new_file;
		AllocConsole();
		freopen_s(&new_file, "CONIN$", "r", stdin);
		freopen_s(&new_file, "CONOUT$", "w", stdout);
		freopen_s(&new_file, "CONOUT$", "w", stderr);
		onexit(exit_event);
	}

	int retval = main(argc, __argv);
	has_exception = false;
	return retval;
}

#else

int __stdcall
WinMain(HINSTANCE /*hInstance*/, HINSTANCE /*hPrevInstance*/, LPSTR /*lpCmdLine*/, int /*nCmdShow*/) {
	return main(__argc, __argv);
}

#endif
