import Cocoa
import Brick

public class GridSpot: NSObject, Gridable {

  /**
   An enum layout type

   - Grid: Resolves to NSCollectionViewGridLayout
   - Left: Resolves to CollectionViewLeftLayout
   - Flow: Resolves to NSCollectionViewFlowLayout
   */
  public enum LayoutType: String {
    case Grid = "grid"
    case Left = "left"
    case Flow = "flow"
  }

  public struct Key {
    /// The key for minimum interitem spacing
    public static let minimumInteritemSpacing = "itemSpacing"
    /// The key for minimum line spacing
    public static let minimumLineSpacing = "lineSpacing"
    /// The key for title left margin
    public static let titleLeftMargin = "titleLeftMargin"
    /// The key for title font size
    public static let titleFontSize = "titleFontSize"
    /// The key for layout
    public static let layout = "layout"
    /// The key for grid layout maximum item width
    public static let gridLayoutMaximumItemWidth = "itemWidthMax"
    /// The key for grid layout maximum item height
    public static let gridLayoutMaximumItemHeight = "itemHeightMax"
    /// The key for grid layout minimum item width
    public static let gridLayoutMinimumItemWidth = "itemMinWidth"
    /// The key for grid layout minimum item height
    public static let gridLayoutMinimumItemHeight = "itemMinHeight"
  }

  public struct Default {

    public struct Flow {
      /// Default minimum interitem spacing
      public static var minimumInteritemSpacing: CGFloat = 0.0
      /// Default minimum line spacing
      public static var minimumLineSpacing: CGFloat = 0.0
    }

    /// Default title font size
    public static var titleFontSize: CGFloat = 18.0
    /// Default left inset of the title
    public static var titleLeftInset: CGFloat = 0.0
    /// Default top inset of the title
    public static var titleTopInset: CGFloat = 10.0
    /// Default layout
    public static var defaultLayout: String = LayoutType.Flow.rawValue
    /// Default grid layout maximum item width
    public static var gridLayoutMaximumItemWidth = 120
    /// Default grid layout maximum item height
    public static var gridLayoutMaximumItemHeight = 120
    /// Default grid layout minimum item width
    public static var gridLayoutMinimumItemWidth = 80
    /// Default grid layout minimum item height
    public static var gridLayoutMinimumItemHeight = 80
    /// Default top section inset
    public static var sectionInsetTop: CGFloat = 0.0
    /// Default left section inset
    public static var sectionInsetLeft: CGFloat = 0.0
    /// Default right section inset
    public static var sectionInsetRight: CGFloat = 0.0
    /// Default bottom section inset
    public static var sectionInsetBottom: CGFloat = 0.0
  }

  /// A Registry struct that contains all register components, used for resolving what UI component to use
  public static var views = Registry()
  public static var grids = GridRegistry()
  public static var configure: ((view: NSCollectionView) -> Void)?
  public static var defaultView: View.Type = NSView.self
  public static var defaultGrid: NSCollectionViewItem.Type = NSCollectionViewItem.self
  public static var defaultKind: StringConvertible = LayoutType.Grid.rawValue

  public weak var spotsCompositeDelegate: SpotsCompositeDelegate?
  public weak var spotsDelegate: SpotsDelegate?

  public var cachedViews = [String : SpotConfigurable]()
  public var component: Component
  public var configure: (SpotConfigurable -> Void)?
  public var index = 0
  /// Indicator to calculate the height based on content
  public var usesDynamicHeight = true

  public private(set) var stateCache: SpotCache?

  public var adapter: SpotAdapter? {
    return collectionAdapter
  }

  public lazy var collectionAdapter: CollectionAdapter = CollectionAdapter(spot: self)

  public var layout: NSCollectionViewLayout

  public lazy var titleView: NSTextField = {
    let titleView = NSTextField()
    titleView.editable = false
    titleView.selectable = false
    titleView.bezeled = false
    titleView.textColor = NSColor.grayColor()
    titleView.drawsBackground = false

    return titleView
  }()

  public lazy var scrollView: ScrollView = {
    let scrollView = ScrollView()
    let view = NSView()
    scrollView.documentView = view

    return scrollView
  }()

  public lazy var collectionView: NSCollectionView = {
    let collectionView = NSCollectionView()
    collectionView.backgroundColors = [NSColor.clearColor()]
    collectionView.selectable = true
    collectionView.allowsMultipleSelection = false
    collectionView.allowsEmptySelection = true
    collectionView.layer = CALayer()
    collectionView.wantsLayer = true

    return collectionView
  }()

  lazy var lineView: NSView = {
    let lineView = NSView()
    lineView.frame.size.height = 1
    lineView.wantsLayer = true
    lineView.layer?.backgroundColor = NSColor.grayColor().colorWithAlphaComponent(0.2).CGColor

    return lineView
  }()

  /**
   A required initializer for creating a GridSpot

   - parameter component: A component struct
   */
  public required init(component: Component) {
    self.component = component
    self.layout = GridSpot.setupLayout(component)
    super.init()
    registerAndPrepare()
    setupCollectionView()
    scrollView.addSubview(titleView)
    scrollView.addSubview(lineView)
    scrollView.contentView.addSubview(collectionView)

    if let layout = layout as? NSCollectionViewFlowLayout where !component.title.isEmpty {
      configureTitleView(layout.sectionInset)
    }
  }

  /**
   A convenience init for initializing a Gridspot with a title and a kind

   - parameter title: A string that is used as a title for the GridSpot
   - parameter kind:  An identifier to determine which kind should be set on the Component
   */
  public convenience init(title: String = "", kind: String? = nil) {
    self.init(component: Component(title: title, kind: kind ?? GridSpot.defaultKind.string))
  }

  /**
   A convenience init for initializing a Gridspot

   - parameter cacheKey: A cache key
   */
  public convenience init(cacheKey: String) {
    let stateCache = SpotCache(key: cacheKey)

    self.init(component: Component(stateCache.load()))
    self.stateCache = stateCache
  }

  deinit {
    collectionView.delegate = nil
    collectionView.dataSource = nil
  }

  private static func configureLayoutInsets(component: Component, layout: NSCollectionViewFlowLayout) -> NSCollectionViewFlowLayout {
    layout.sectionInset = NSEdgeInsets(
      top: component.meta(GridableMeta.Key.sectionInsetTop, Default.sectionInsetTop),
      left: component.meta(GridableMeta.Key.sectionInsetLeft, Default.sectionInsetLeft),
      bottom: component.meta(GridableMeta.Key.sectionInsetBottom, Default.sectionInsetBottom),
      right: component.meta(GridableMeta.Key.sectionInsetRight, Default.sectionInsetRight))

    layout.minimumInteritemSpacing = component.meta(GridSpot.Key.minimumInteritemSpacing, Default.Flow.minimumInteritemSpacing)
    layout.minimumLineSpacing = component.meta(GridSpot.Key.minimumLineSpacing, Default.Flow.minimumLineSpacing)

    return layout
  }

  /**
   A private method for configuring the layout for the collection view

   - parameter component: The component for the GridSpot

   - returns: A NSCollectionView layout determined by the Component
   */
  private static func setupLayout(component: Component) -> NSCollectionViewLayout {
    let layout: NSCollectionViewLayout

    switch LayoutType(rawValue: component.meta(Key.layout, Default.defaultLayout)) ?? LayoutType.Flow {
    case .Grid:
      let gridLayout = NSCollectionViewGridLayout()

      gridLayout.maximumItemSize = CGSize(width: component.meta(Key.gridLayoutMaximumItemWidth, Default.gridLayoutMaximumItemWidth),
                                          height: component.meta(Key.gridLayoutMaximumItemHeight, Default.gridLayoutMaximumItemHeight))
      gridLayout.minimumItemSize = CGSize(width: component.meta(Key.gridLayoutMinimumItemWidth, Default.gridLayoutMinimumItemWidth),
                                          height: component.meta(Key.gridLayoutMinimumItemHeight, Default.gridLayoutMinimumItemHeight))
      layout = gridLayout
    case .Left:
      let leftLayout = CollectionViewLeftLayout()
      configureLayoutInsets(component, layout: leftLayout)
      layout = leftLayout

    case .Flow:
      fallthrough
    default:
      let flowLayout = NSCollectionViewFlowLayout()
      configureLayoutInsets(component, layout: flowLayout)
      flowLayout.scrollDirection = .Vertical
      layout = flowLayout
    }

    return layout
  }

  /**
   Configure delegate, data source and layout for collection view
   */
  public func setupCollectionView() {
    collectionView.delegate = collectionAdapter
    collectionView.dataSource = collectionAdapter
    collectionView.collectionViewLayout = layout
  }

  /**
   The container view for the GridSpot

   - returns: A ScrollView object
   */
  public func render() -> ScrollView {
    return scrollView
  }

  /**
   Layout with size

   - parameter size: A CGSize from the GridSpot superview
   */
  public func layout(size: CGSize) {
    layout.prepareForTransitionToLayout(layout)

    var layoutInsets = NSEdgeInsets()
    if let layout = layout as? NSCollectionViewFlowLayout {
      layout.sectionInset.top = component.meta(GridableMeta.Key.sectionInsetTop, Default.sectionInsetTop) + titleView.frame.size.height + 8
      layoutInsets = layout.sectionInset
    }

    var layoutHeight = layout.collectionViewContentSize.height + layoutInsets.top + layoutInsets.bottom

    if component.items.isEmpty {
      layoutHeight = size.height + layoutInsets.top + layoutInsets.bottom
    }

    scrollView.frame.size.width = size.width - layoutInsets.right
    scrollView.frame.size.height = layoutHeight
    collectionView.frame.size.height = scrollView.frame.size.height - layoutInsets.top + layoutInsets.bottom
    collectionView.frame.size.width = size.width - layoutInsets.right

    GridSpot.configure?(view: collectionView)

    if !component.title.isEmpty {
      configureTitleView(layoutInsets)
    }
  }

  /**
   Perform setup with size

   - parameter size: A CGSize from the GridSpot superview
   */
  public func setup(size: CGSize) {
    var size = size
    size.height = layout.collectionViewContentSize.height
    layout(size)
  }

  /**
   A private setup method for configuring the title view

   - parameter layoutInsets: NSEdgeInsets used to configure the title and line view size and origin
   */
  private func configureTitleView(layoutInsets: NSEdgeInsets) {
    titleView.stringValue = component.title
    titleView.font = NSFont.systemFontOfSize(component.meta(Key.titleFontSize, Default.titleFontSize))
    titleView.sizeToFit()
    titleView.frame.size.width = collectionView.frame.width - layoutInsets.right - layoutInsets.left
    lineView.frame.size.width = scrollView.frame.size.width - (component.meta(Key.titleLeftMargin, Default.titleLeftInset) * 2)
    lineView.frame.origin.x = component.meta(Key.titleLeftMargin, Default.titleLeftInset)
    titleView.frame.origin.x = layoutInsets.left
    titleView.frame.origin.x = component.meta(Key.titleLeftMargin, titleView.frame.origin.x)
    titleView.frame.origin.y = titleView.frame.size.height / 2
    lineView.frame.origin.y = titleView.frame.maxY + 8
  }
}
