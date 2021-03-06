import UIKit

/// A proxy cell that is used for composite views inside other Spotable objects
class GridComposite: UICollectionViewCell, SpotComposable {

  /**
   Performs any clean up necessary to prepare the view for use again.
   */
  override func prepareForReuse() {
    contentView.subviews.forEach { $0.removeFromSuperview() }
  }
}
