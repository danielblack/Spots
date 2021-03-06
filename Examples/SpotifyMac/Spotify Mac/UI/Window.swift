import Cocoa

class Window: NSWindow, NSWindowDelegate {

  lazy var customToolbar = Toolbar(identifier: "main-toolbar")

  override init (contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
    super.init (contentRect: contentRect, styleMask: aStyle, backing: bufferingType, defer: flag)

    self.titleVisibility = .Hidden
    self.styleMask =
      NSClosableWindowMask |
      NSMiniaturizableWindowMask |
      NSResizableWindowMask |
      NSBorderlessWindowMask |
      NSTitledWindowMask |
      NSFullSizeContentViewWindowMask
    self.opaque = false
    self.titlebarAppearsTransparent = true
    self.toolbar = customToolbar
    self.minSize = NSSize(width: 985, height: 640)
    self.movable = true
    self.delegate = self
    self.backgroundColor = NSColor(red:0.1, green:0.1, blue:0.1, alpha: 0.985)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension Window {

  func windowDidExitFullScreen(notification: NSNotification) {
    toolbar?.visible = true
  }

  func windowWillEnterFullScreen(notification: NSNotification) {
    toolbar?.visible = false
  }
}
