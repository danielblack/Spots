import Cocoa
import Brick

/// A view registry that is used internally when resolving kind to the corresponding spot.
public struct GridRegistry {

  public enum Item {
    case classType(NSCollectionViewItem.Type)
    case nib(Nib)
  }

  /// A Key-value dictionary of registred types
  var storage = [String : Item]()

  /// The default item for the registry
  var defaultItem: Item? {
    didSet {
      storage[defaultIdentifier] = defaultItem
    }
  }

  /// The default identifier for the registry
  var defaultIdentifier: String {
    return String(defaultItem)
  }

  /**
   A subscripting method for getting a value from storage using a StringConvertible key

   - returns: An optional UIView type
   */
  public subscript(key: StringConvertible) -> Item? {
    get {
      return storage[key.string]
    }
    set(value) {
      storage[key.string] = value
    }
  }

  // MARK: - Template

  /// A cache that stores instances of created views
  private var cache: NSCache = NSCache()

  /**
   Empty the current view cache
   */
  func purge() {
    cache.removeAllObjects()
  }

  /**
   Create a view for corresponding identifier

   - parameter identifier: A reusable identifier for the view
   - returns: A tuple with an optional registry type and view
   */
  func make(identifier: String) -> (type: RegistryType?, item: NSCollectionViewItem?)? {
    guard let item = storage[identifier] else { return nil }

    let registryType: RegistryType?
    var view: NSCollectionViewItem? = nil

    switch item {
    case .classType(let classType):
      registryType = .Regular
      if let item = cache.objectForKey(registryType!.rawValue + identifier) as? NSCollectionViewItem {
        return (type: registryType, item: item)
      }

      view = classType.init()

    case .nib(let nib):
      registryType = .Nib
      if let view = cache.objectForKey(registryType!.rawValue + identifier) as? NSCollectionViewItem {
        return (type: registryType, item: view)
      }

      var views: NSArray?
      if nib.instantiateWithOwner(nil, topLevelObjects: &views) {
        view = views?.filter({ $0 is NSCollectionViewItem }).first as? NSCollectionViewItem
      }
    }

    if let view = view {
      cache.setObject(view, forKey: identifier)
    }

    return (type: registryType, item: view)
  }
}
