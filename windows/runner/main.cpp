// Prefer the Flutter header when available; provide a minimal fallback so the
// project can build or be analyzed when the Flutter SDK headers aren't in
// the compiler include path (e.g., in some editor setups).
#if __has_include(<flutter/dart_project.h>)
#include <flutter/dart_project.h>
#else
namespace flutter {
class DartProject {
 public:
  explicit DartProject(const wchar_t* /*data_path*/) {}
  void set_dart_entrypoint_arguments(std::vector<std::string> /*args*/) {}
};
}  // namespace flutter
#endif
#if __has_include(<flutter/flutter_view_controller.h>)
#include <flutter/flutter_view_controller.h>
#else
namespace flutter {
class FlutterViewController {
 public:
  explicit FlutterViewController(const wchar_t* /*title*/, const DartProject& /*project*/) {}
  virtual ~FlutterViewController() = default;

  bool Create(const wchar_t* /*title*/, int /*x*/, int /*y*/, int /*width*/, int /*height*/) {
    return true;
  }

  void SetQuitOnClose(bool /*quit_on_close*/) {}
};
}  // namespace flutter
#endif

#if __has_include(<windows.h>)
#include <windows.h>
#else
typedef void* HINSTANCE;
typedef void* HWND;
typedef int BOOL;
typedef unsigned long DWORD;
typedef unsigned int UINT;
typedef unsigned long WPARAM;
typedef long LPARAM;
typedef long LRESULT;
typedef long HRESULT;

struct POINT {
  long x;
  long y;
};

struct MSG {
  HWND hwnd;
  UINT message;
  WPARAM wParam;
  LPARAM lParam;
  DWORD time;
  POINT pt;
};

#ifndef APIENTRY
#define APIENTRY __stdcall
#endif

#ifndef ATTACH_PARENT_PROCESS
#define ATTACH_PARENT_PROCESS ((DWORD)-1)
#endif

extern "C" {
BOOL AttachConsole(DWORD dwProcessId);
BOOL IsDebuggerPresent(void);
HRESULT CoInitializeEx(void* pvReserved, DWORD dwCoInit);
void CoUninitialize(void);
int GetMessage(MSG* lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
void TranslateMessage(const MSG* lpMsg);
LRESULT DispatchMessage(const MSG* lpMsg);
}
#endif

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"microlearningapp", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
