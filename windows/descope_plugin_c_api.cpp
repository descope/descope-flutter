#include "include/descope/descope_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "descope_plugin.h"

void DescopePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  descope::DescopePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
