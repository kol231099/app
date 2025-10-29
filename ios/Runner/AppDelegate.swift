// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import GoogleMaps   // ← 加在這裡

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBspNpJs-VUTRFbnSjX22SefWXX5vnnWkg")  // ← 把你的 Key 放這行
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
