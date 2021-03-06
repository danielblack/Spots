import UIKit
import Spots

public class ListHeaderView: UITableViewHeaderFooterView, Componentable {

  public var defaultHeight: CGFloat = 44

  lazy var label: UILabel = { [unowned self] in
    let label = UILabel(frame: self.frame)
    label.font = UIFont.boldSystemFontOfSize(11)

    return label
  }()

  lazy var paddedStyle: NSParagraphStyle = {
    let style = NSMutableParagraphStyle()
    style.alignment = .Left
    style.firstLineHeadIndent = 15.0
    style.headIndent = 15.0
    style.tailIndent = -15.0

    return style
    }()

  public override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func configure(component: Component) {
    backgroundColor = UIColor.whiteColor()

    label.attributedText = NSAttributedString(string: component.title.uppercaseString,
      attributes: [NSParagraphStyleAttributeName : paddedStyle])
  }
}
