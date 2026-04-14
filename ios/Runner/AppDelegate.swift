import Flutter
import UIKit
import Darwin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let logUpdateChannel = FlutterEventChannel(
        name: "qa_flutter/sdk_log_updates",
        binaryMessenger: controller.binaryMessenger
      )
      logUpdateChannel.setStreamHandler(SdkLogUpdateStreamHandler())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class SdkLogUpdateStreamHandler: NSObject, FlutterStreamHandler {
  private var watchedDirectoryPath: String?
  private var targetFileName: String?
  private var directoryFileDescriptor: Int32 = -1
  private var directorySource: DispatchSourceFileSystemObject?
  private let callbackQueue = DispatchQueue(label: "qa_flutter.sdk_log_updates")
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard let logPath = arguments as? String, !logPath.isEmpty else {
      return FlutterError(code: "invalid_args", message: "log path is required", details: nil)
    }

    let fileUrl = URL(fileURLWithPath: logPath)
    let directoryUrl = fileUrl.deletingLastPathComponent()
    let targetName = fileUrl.lastPathComponent

    var isDirectory: ObjCBool = false
    let directoryExists = FileManager.default.fileExists(
      atPath: directoryUrl.path,
      isDirectory: &isDirectory
    )
    guard directoryExists, isDirectory.boolValue else {
      return FlutterError(
        code: "invalid_path",
        message: "log parent directory is unavailable",
        details: nil
      )
    }

    stopWatching()

    let fd = open(directoryUrl.path, O_EVTONLY)
    guard fd >= 0 else {
      return FlutterError(
        code: "watch_failed",
        message: "failed to open log parent directory",
        details: nil
      )
    }

    watchedDirectoryPath = directoryUrl.path
    targetFileName = targetName
    directoryFileDescriptor = fd
    eventSink = events

    let source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: fd,
      eventMask: [.write, .rename, .delete, .extend, .attrib],
      queue: callbackQueue
    )

    source.setEventHandler { [weak self] in
      guard let self else { return }
      guard
        let sink = self.eventSink,
        let directoryPath = self.watchedDirectoryPath,
        let targetFileName = self.targetFileName
      else {
        return
      }

      let candidatePath = URL(fileURLWithPath: directoryPath)
        .appendingPathComponent(targetFileName)
        .path
      let fileExists = FileManager.default.fileExists(atPath: candidatePath)

      DispatchQueue.main.async {
        sink([
          "path": targetFileName,
          "exists": fileExists
        ])
      }
    }

    source.setCancelHandler { [weak self] in
      guard let self else { return }
      if self.directoryFileDescriptor >= 0 {
        close(self.directoryFileDescriptor)
        self.directoryFileDescriptor = -1
      }
    }

    directorySource = source
    source.resume()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopWatching()
    return nil
  }

  deinit {
    stopWatching()
  }

  private func stopWatching() {
    eventSink = nil
    watchedDirectoryPath = nil
    targetFileName = nil
    directorySource?.cancel()
    directorySource = nil
  }
}
