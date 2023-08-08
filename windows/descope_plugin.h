#ifndef FLUTTER_PLUGIN_DESCOPE_PLUGIN_H_
#define FLUTTER_PLUGIN_DESCOPE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace descope {

class DescopePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DescopePlugin();

  virtual ~DescopePlugin();

  // Disallow copy and assign.
  DescopePlugin(const DescopePlugin&) = delete;
  DescopePlugin& operator=(const DescopePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace descope

#endif  // FLUTTER_PLUGIN_DESCOPE_PLUGIN_H_
