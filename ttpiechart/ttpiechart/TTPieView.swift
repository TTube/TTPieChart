//
//  TTPieView.swift
//  swiftTest
//
//  Created by Galvin on 16/4/12.
//  Copyright © 2016年 Galvin. All rights reserved.
//

import Foundation
import UIKit

infix operator +  { associativity right precedence 110 }

typealias chartMaker = CALayer -> CALayer?
typealias reusePieLayer = Int -> CALayer?
typealias brighterColor = CGFloat -> UIColor

enum TTPieDirection {
    case Normal
    case Anti
}

//一个扇形
struct Sector {
    var centerOffset = CGPoint.zero           //圆心偏移  //扇形圆心为当前View的中点
    var maxRadius = 0.0                               //外径
    var minRadius = 0.0                                 //内径
    var startPercent = 0.0                              //开始的百分比percent
    var endPercent = 0.0                                //结束的百分比
    
    var hasBorder = false
    var borderColor : UIColor?
    var fillColor : UIColor?
}

/*
 + get the chartMaker maker to make sectorLayer with sector
 @param startAngle: the pie startAngle
 @param direction: the pie direction
 @param center: the center of sectorLayer's container
 */
private func + (sector : Sector, pieView :TTPieView) -> chartMaker {
    return { layer in
        guard let pie = layer as? TTSectorLayer
            where (sector.minRadius < sector.maxRadius || sector.minRadius >= 0 || sector.maxRadius >= 0)
            else { return layer }
        let pieCenter = CGPoint.init(x: pieView.center.x + sector.centerOffset.x, y: pieView.center.y + sector.centerOffset.y)
        let sectorPath = UIBezierPath()
        //Get the sector startAngle and endAngle from sector's startPercent and endPercent
        let startAngle = pieView.startAngle + (sector.startPercent * M_PI * 2) * (pieView.direction == TTPieDirection.Normal ? 1 : -1);
        let endAngle = pieView.startAngle + (sector.endPercent * M_PI * 2) * (pieView.direction == TTPieDirection.Normal ? 1 : -1);
        //Get startPoint,endPoint to draw the path
        let startInnerPoint = CGPoint.init(x: CGFloat(sector.minRadius * cos(startAngle) + Double(pieCenter.x)), y: CGFloat(sector.minRadius * sin(startAngle) + Double(pieCenter.y)))
        let endOutterPoint = CGPoint.init(x: CGFloat(sector.maxRadius * cos(endAngle) + Double(pieCenter.x)), y: CGFloat(sector.maxRadius * sin(endAngle) + Double(pieCenter.y)))
        
        //Begin to draw the path
        if sector.minRadius > 0 {
            sectorPath.moveToPoint(startInnerPoint)
            sectorPath.addArcWithCenter(pieCenter, radius: CGFloat(sector.minRadius), startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: pieView.direction == .Normal)
            sectorPath.addLineToPoint(endOutterPoint);
            sectorPath.addArcWithCenter(pieCenter, radius: CGFloat(sector.maxRadius), startAngle: CGFloat(endAngle), endAngle: CGFloat(startAngle), clockwise: pieView.direction != .Normal)
            
        }else {
            sectorPath.moveToPoint(pieCenter)
            sectorPath.addLineToPoint(endOutterPoint)
            sectorPath.addArcWithCenter(pieCenter, radius: CGFloat(sector.maxRadius), startAngle: CGFloat(endAngle), endAngle: CGFloat(startAngle), clockwise: pieView.direction != .Normal)
            sectorPath.addLineToPoint(pieCenter)
        }
        //draw end
        sectorPath.closePath()
        pie.path = sectorPath.CGPath
        if let fillColor = sector.fillColor {
            pie.fillColor = fillColor.CGColor
        }else {
            pie.fillColor = nil
        }
        if let borderColor = sector.borderColor {
            pie.strokeColor = borderColor.CGColor
        }else {
            pie.strokeColor =  nil
        }
        pie.sector = sector
        pie.frame = pieView.bounds
        pieView.layer.addSublayer(pie)
        return pie
    }
}




 protocol TTPieViewDataSource : NSObjectProtocol {
   func numberOfSectorInPieView(pieView : TTPieView) -> Int
   func pieView(pieView : TTPieView, sectorModelForIndex index : Int) -> Sector
}

protocol TTPieViewDelegate : NSObjectProtocol {
    func pieView(pieView : TTPieView, didClickPieLayer layer : TTSectorLayer) -> Void
    func pieView(pieView : TTPieView, didUnClickPieLayer layer : TTSectorLayer) -> Void
}

class TTSectorLayer: CAShapeLayer {
    var sector : Sector?
}

class TTPieView: UIView {
    weak var dataSource : TTPieViewDataSource?
    weak var delegate : TTPieViewDelegate?
    var didLayoutFirst = false
    
    var  currentSectorNum : Int = 0
    
    var startAngle = 0.0
    var direction : TTPieDirection = .Normal
    
    lazy var reusePieLayerGetter : reusePieLayer? = {
        let reusePieLayerGetter : reusePieLayer = { [weak self]
            layerIndex in
            guard let strongSelf = self else { return nil }
            let numberOfReuseList = strongSelf.reusePiesList.count
            if Int(layerIndex) >= numberOfReuseList {
                //如果不存在layer则构造
                let cycleNum = Int(layerIndex) + 1 - numberOfReuseList
                for index in 1...cycleNum {
                    let pieLayer = TTSectorLayer()
                    pieLayer.contentsScale = UIScreen.mainScreen().scale
                    pieLayer.lineWidth = 1.0
                    pieLayer.strokeStart = 0.0
                    pieLayer.strokeEnd = 1.0
                    strongSelf.reusePiesList.append(pieLayer)
                }
            }
            return strongSelf.reusePiesList[layerIndex]
        }
        return reusePieLayerGetter
    }()
    
    var reusePiesList : Array <TTSectorLayer> = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (self.frame.size.width > 0) && !self.didLayoutFirst {
            self .reloadView()
            didLayoutFirst = true
        }
    }
    
    func reloadView() -> Void {
        for pieLayer in self.reusePiesList {
            pieLayer.removeFromSuperlayer()
        }
        let numberOfPie = dataSource?.numberOfSectorInPieView(self)
        if numberOfPie < currentSectorNum  {
            //clear reuse sector
            var newReuseList : Array <TTSectorLayer>  = []
            for index in 0...(numberOfPie!-1) {
                newReuseList.append(reusePiesList[index])
            }
            self.reusePiesList = newReuseList
        }
        for index in 0..<(numberOfPie!) {
            guard let sector = self.dataSource?.pieView(self, sectorModelForIndex: index) , let reuseLayer = self.reusePieLayerGetter?(index)  else {
                continue
            }
            (sector + self)(reuseLayer)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        let touchPoint = touches.first?.locationInView(self)
        for pieLayer in self.reusePiesList {
            let path = UIBezierPath.init(CGPath: pieLayer.path!)
            if path.containsPoint(touchPoint!) {
                self.delegate?.pieView(self, didClickPieLayer: pieLayer)
                break
            }
        }
    }
 
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
         let touchPoint = touches.first?.locationInView(self)
        for pieLayer in self.reusePiesList {
            let path = UIBezierPath.init(CGPath: pieLayer.path!)
            if path.containsPoint(touchPoint!) {
                self.delegate?.pieView(self, didClickPieLayer: pieLayer)
            }else {
                self.delegate?.pieView(self, didUnClickPieLayer: pieLayer)
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
            for pieLayer in self.reusePiesList {
                self.delegate?.pieView(self, didUnClickPieLayer: pieLayer)
            }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        for pieLayer in self.reusePiesList {
            self.delegate?.pieView(self, didUnClickPieLayer: pieLayer)
        }
    }
}




extension UIColor {
    func brinessColor() -> brighterColor {
        var hue : CGFloat = 0, saturation : CGFloat = 0, brightness : CGFloat = 0, alpha : CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return { lighterOffset in
            brightness += lighterOffset
            saturation -= 0.2
           return UIColor.init(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
    }
}


