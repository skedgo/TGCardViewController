//
//  TGCardStyleKit.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 29/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//
//  Generated by PaintCode
//  http://www.paintcodeapp.com
//



import UIKit

public class TGCardStyleKit : NSObject {

    //// Cache

    private struct Cache {
        static let darkColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)
        static let lightColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
    }

    //// Colors

    public dynamic class var darkColor: UIColor { return Cache.darkColor }
    public dynamic class var lightColor: UIColor { return Cache.lightColor }

    //// Drawing Methods

    public dynamic class func drawHeaderCloseIcon(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 20, height: 20), resizing: ResizingBehavior = .aspectFit, length: CGFloat = 20, lineWidth: CGFloat = 3, white: Bool = false) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 20, height: 20), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 20, y: resizedFrame.height / 20)



        //// Variable Declarations
        let iconScale: CGFloat = length / 20.0
        let padding: CGFloat = lineWidth / 2.0
        let iconOrigin = CGPoint(x: padding, y: padding)
        let strokeColor = white ? TGCardStyleKit.lightColor : TGCardStyleKit.darkColor

        //// Bezier Drawing
        context.saveGState()
        context.translateBy(x: iconOrigin.x, y: iconOrigin.y)
        context.scaleBy(x: iconScale, y: iconScale)

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: 0))
        bezierPath.addLine(to: CGPoint(x: 17, y: 17))
        strokeColor.setStroke()
        bezierPath.lineWidth = lineWidth
        bezierPath.stroke()

        context.restoreGState()


        //// Bezier 2 Drawing
        context.saveGState()
        context.translateBy(x: iconOrigin.x, y: iconOrigin.y)
        context.scaleBy(x: iconScale, y: iconScale)

        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 0, y: 17))
        bezier2Path.addLine(to: CGPoint(x: 17, y: 0))
        strokeColor.setStroke()
        bezier2Path.lineWidth = lineWidth
        bezier2Path.stroke()

        context.restoreGState()
        
        context.restoreGState()

    }

    public dynamic class func drawHeaderNextIcon(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 20, height: 20), resizing: ResizingBehavior = .aspectFit, length: CGFloat = 20, lineWidth: CGFloat = 3, white: Bool = false) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 20, height: 20), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 20, y: resizedFrame.height / 20)



        //// Variable Declarations
        let iconScale: CGFloat = length / 20.0
        let padding: CGFloat = lineWidth / 2.0
        let iconOrigin = CGPoint(x: padding, y: padding)
        let strokeColor = white ? TGCardStyleKit.lightColor : TGCardStyleKit.darkColor

        //// Bezier Drawing
        context.saveGState()
        context.translateBy(x: iconOrigin.x, y: iconOrigin.y)
        context.scaleBy(x: iconScale, y: iconScale)

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: 0))
        bezierPath.addLine(to: CGPoint(x: 8.5, y: 8.5))
        bezierPath.addLine(to: CGPoint(x: 0, y: 17))
        strokeColor.setStroke()
        bezierPath.lineWidth = lineWidth
        bezierPath.stroke()

        context.restoreGState()
        
        context.restoreGState()

    }

    public dynamic class func drawCardCloseIcon(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 20, height: 20), resizing: ResizingBehavior = .aspectFit, length: CGFloat = 20) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 20, height: 20), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 20, y: resizedFrame.height / 20)



        //// Variable Declarations
        let iconScale: CGFloat = length / 20.0
        let innerOrigin = CGPoint(x: length / 4.0, y: length / 4.0)
        let innerLength: CGFloat = length / 2.0

        //// Group
        context.saveGState()
        context.scaleBy(x: iconScale, y: iconScale)



        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: length, height: length))
        UIColor.gray.setFill()
        ovalPath.fill()


        //// Bezier Drawing
        context.saveGState()
        context.translateBy(x: innerOrigin.x, y: innerOrigin.y)

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: 0))
        bezierPath.addLine(to: CGPoint(x: innerLength, y: innerLength))
        TGCardStyleKit.lightColor.setStroke()
        bezierPath.lineWidth = 1
        bezierPath.stroke()

        context.restoreGState()


        //// Bezier 2 Drawing
        context.saveGState()
        context.translateBy(x: innerOrigin.x, y: innerOrigin.y)

        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 0, y: innerLength))
        bezier2Path.addLine(to: CGPoint(x: innerLength, y: 0))
        TGCardStyleKit.lightColor.setStroke()
        bezier2Path.lineWidth = 1
        bezier2Path.stroke()

        context.restoreGState()



        context.restoreGState()
        
        context.restoreGState()

    }




    @objc(TGCardStyleKitResizingBehavior)
    public enum ResizingBehavior: Int {
        case aspectFit /// The content is proportionally resized to fit into the target rectangle.
        case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
        case stretch /// The content is stretched to match the entire target rectangle.
        case center /// The content is centered in the target rectangle, but it is NOT resized.

        public func apply(rect: CGRect, target: CGRect) -> CGRect {
            if rect == target || target == CGRect.zero {
                return rect
            }

            var scales = CGSize.zero
            scales.width = abs(target.width / rect.width)
            scales.height = abs(target.height / rect.height)

            switch self {
                case .aspectFit:
                    scales.width = min(scales.width, scales.height)
                    scales.height = scales.width
                case .aspectFill:
                    scales.width = max(scales.width, scales.height)
                    scales.height = scales.width
                case .stretch:
                    break
                case .center:
                    scales.width = 1
                    scales.height = 1
            }

            var result = rect.standardized
            result.size.width *= scales.width
            result.size.height *= scales.height
            result.origin.x = target.minX + (target.width - result.width) / 2
            result.origin.y = target.minY + (target.height - result.height) / 2
            return result
        }
    }
}
