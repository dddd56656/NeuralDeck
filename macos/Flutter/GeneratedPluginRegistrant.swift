//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import device_info_plus
import flutter_tts
import screen_retriever_macos
import speech_to_text
import sqflite_darwin
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  FlutterTtsPlugin.register(with: registry.registrar(forPlugin: "FlutterTtsPlugin"))
  ScreenRetrieverMacosPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverMacosPlugin"))
  SpeechToTextPlugin.register(with: registry.registrar(forPlugin: "SpeechToTextPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
