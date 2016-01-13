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

	onexit(exit_event);
	int retval = main(__argc, __argv);
	has_exception = false;
	return retval;
}

#else

int __stdcall
WinMain(HINSTANCE /*hInstance*/, HINSTANCE /*hPrevInstance*/, LPSTR /*lpCmdLine*/, int /*nCmdShow*/) {
	return main(__argc, __argv);
}

#endif
