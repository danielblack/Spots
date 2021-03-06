import UIKit

extension CollectionAdapter : UICollectionViewDelegate {

  /**
   Asks the delegate for the size of the specified item’s cell.

   - parameter collectionView: The collection view object displaying the flow layout.
   - parameter collectionViewLayout: The layout object requesting the information.
   - parameter indexPath: The index path of the item.
   - returns: The width and height of the specified item. Both values must be greater than 0.
   */
  public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    return spot.sizeForItemAt(indexPath)
  }

  /**
   Tells the delegate that the item at the specified index path was selected.

   - parameter collectionView: The collection view object that is notifying you of the selection change.
   - parameter indexPath: The index path of the cell that was selected.
   */
  public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    guard let item = spot.item(indexPath) else { return }
    spot.spotsDelegate?.spotDidSelectItem(spot, item: item)
  }

  /**
   Asks the delegate whether the item at the specified index path can be focused.

   - parameter collectionView: The collection view object requesting this information.
   - parameter indexPath:      The index path of an item in the collection view.
   - returns: YES if the item can receive be focused or NO if it can not.
   */
  public func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }

  /**
   Asks the delegate whether a change in focus should occur.

   - parameter collectionView: The collection view object requesting this information.
   - parameter context:        The context object containing metadata associated with the focus change.
   This object contains the index path of the previously focused item and the item targeted to receive focus next. Use this information to determine if the focus change should occur.
   - returns: YES if the focus change should occur or NO if it should not.
   */
  @available(iOS 9.0, *)
  public func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
    guard let indexPaths = collectionView.indexPathsForSelectedItems() else { return true }
    return indexPaths.isEmpty
  }

  /**
   Perform animation before mutation

   - parameter spotAnimation: The animation that you want to apply
   - parameter withIndex: The index of the cell
   - parameter completion: A completion block that runs after applying the animation
   */
  public func perform(spotAnimation: SpotsAnimation, withIndex index: Int, completion: () -> Void) {
    guard let cell = spot.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0))
      else { completion(); return }

    let animation = CABasicAnimation()

    switch spotAnimation {
    case .Top:
      animation.keyPath = "position.y"
      animation.toValue = -cell.frame.height
    case .Bottom:
      animation.keyPath = "position.y"
      animation.toValue = cell.frame.height * 2
    case .Left:
      animation.keyPath = "position.x"
      animation.toValue = -cell.frame.width - spot.collectionView.contentOffset.x
    case .Right:
      animation.keyPath = "position.x"
      animation.toValue = cell.frame.width + spot.collectionView.frame.size.width + spot.collectionView.contentOffset.x
    case .Fade:
      animation.keyPath = "opacity"
      animation.toValue = 0.0
    case .Middle:
      animation.keyPath = "transform.scale.y"
      animation.toValue = 0.0
    case .Automatic:
      animation.keyPath = "transform.scale"
      animation.toValue = 0.0
    default:
      break
    }

    animation.duration = 0.3
    cell.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    cell.layer.addAnimation(animation, forKey: "SpotAnimation")
    completion()
  }
}
