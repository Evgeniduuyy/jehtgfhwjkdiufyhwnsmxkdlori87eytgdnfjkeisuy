import UIKit

/// A small pill with a rounded app icon and a label, drawn in the style of the
/// built-in profile subtitle badges. Plain UIKit so the module stays standalone.
public final class TeleFlowBadgeView: UIView {
    public enum Icon {
        case app
        case gram
    }

    private let iconImageView = UIImageView()
    private let labelNode = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = false

        self.iconImageView.contentMode = .scaleAspectFit
        self.addSubview(self.iconImageView)

        self.labelNode.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        self.labelNode.textColor = .white
        self.labelNode.isUserInteractionEnabled = false
        self.addSubview(self.labelNode)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    /// Recreates the contents for the given text. Returns the size the pill needs.
    @discardableResult
    public func update(text: String, icon: Icon) -> CGSize {
        self.labelNode.text = text
        self.labelNode.sizeToFit()
        let labelSize = self.labelNode.frame.size

        let iconSide: CGFloat = 15.0
        self.iconImageView.image = TeleFlowBadgeView.iconImage(icon: icon, size: iconSide)

        let horizontalInset: CGFloat = 7.0
        let iconTextGap: CGFloat = 4.0
        let size = CGSize(width: horizontalInset * 2.0 + iconSide + iconTextGap + ceil(labelSize.width), height: max(iconSide, ceil(labelSize.height)) + 8.0)

        self.frame.size = size
        self.layer.cornerRadius = size.height * 0.5
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.32)

        let contentLeft = horizontalInset
        let contentCenterY = size.height * 0.5
        self.iconImageView.frame = CGRect(x: contentLeft, y: contentCenterY - iconSide * 0.5, width: iconSide, height: iconSide)
        self.labelNode.frame = CGRect(x: contentLeft + iconSide + iconTextGap, y: contentCenterY - labelSize.height * 0.5, width: ceil(labelSize.width) + 2.0, height: labelSize.height)

        return size
    }

    private static func iconImage(icon: Icon, size: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            let rect = CGRect(x: 0.0, y: 0.0, width: size, height: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: size * 0.28)
            path.addClip()

            let colors: [CGColor]
            switch icon {
            case .app:
                colors = [UIColor(red: 0.25, green: 0.47, blue: 0.94, alpha: 1.0).cgColor, UIColor(red: 0.16, green: 0.32, blue: 0.78, alpha: 1.0).cgColor]
            case .gram:
                colors = [UIColor(red: 1.0, green: 0.62, blue: 0.10, alpha: 1.0).cgColor, UIColor(red: 0.93, green: 0.38, blue: 0.05, alpha: 1.0).cgColor]
            }
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size), options: [])

            switch icon {
            case .app:
                // A white paper plane, like the app icon.
                let plane = UIBezierPath()
                plane.move(to: CGPoint(x: size * 0.80, y: size * 0.20))
                plane.addLine(to: CGPoint(x: size * 0.20, y: size * 0.47))
                plane.addLine(to: CGPoint(x: size * 0.42, y: size * 0.55))
                plane.addLine(to: CGPoint(x: size * 0.48, y: size * 0.78))
                plane.addLine(to: CGPoint(x: size * 0.58, y: size * 0.64))
                plane.addLine(to: CGPoint(x: size * 0.74, y: size * 0.72))
                plane.close()
                UIColor.white.setFill()
                plane.fill()
            case .gram:
                // A stylised flame.
                let flame = UIBezierPath()
                flame.move(to: CGPoint(x: size * 0.50, y: size * 0.16))
                flame.addCurve(to: CGPoint(x: size * 0.30, y: size * 0.58), controlPoint1: CGPoint(x: size * 0.26, y: size * 0.36), controlPoint2: CGPoint(x: size * 0.28, y: size * 0.50))
                flame.addCurve(to: CGPoint(x: size * 0.50, y: size * 0.84), controlPoint1: CGPoint(x: size * 0.32, y: size * 0.72), controlPoint2: CGPoint(x: size * 0.42, y: size * 0.84))
                flame.addCurve(to: CGPoint(x: size * 0.70, y: size * 0.58), controlPoint1: CGPoint(x: size * 0.58, y: size * 0.84), controlPoint2: CGPoint(x: size * 0.68, y: size * 0.72))
                flame.addCurve(to: CGPoint(x: size * 0.50, y: size * 0.16), controlPoint1: CGPoint(x: size * 0.72, y: size * 0.50), controlPoint2: CGPoint(x: size * 0.74, y: size * 0.36))
                UIColor.white.setFill()
                flame.fill()
            }
        }
    }
}
