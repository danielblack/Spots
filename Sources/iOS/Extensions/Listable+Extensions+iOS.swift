import UIKit
import Brick

// MARK: - Extensions for Spotable objects that also confirm to Listable
public extension Spotable where Self : Listable {

  /**
   - returns: UIScrollView: Returns a UITableView as a UIScrollView
   */
  public func render() -> UIScrollView {
    return tableView
  }

  /**
   - parameter size: A CGSize to set the width of the table view
   */
  public func layout(size: CGSize) {
    tableView.frame.size.width = size.width
    guard let componentSize = component.size else { return }
    tableView.frame.size.height = componentSize.height
  }

  /**
   - parameter includeElement: A filter predicate to find a view model
   - returns: A calculate CGFloat based on what the includeElement matches
   */
  public func scrollTo(@noescape includeElement: (Item) -> Bool) -> CGFloat {
    guard let item = items.filter(includeElement).first else { return 0.0 }

    return component.items[0...item.index]
      .reduce(0, combine: { $0 + $1.size.height })
  }
}
