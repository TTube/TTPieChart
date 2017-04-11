//
//  TTPieView.swift
//  swiftTest
//
//  Created by Galvin on 16/4/12.
//  Copyright © 2016年 Galvin. All rights reserved.
//

import Foundation
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


//infix operator +  { associativity right precedence 110 }

typealias chartMaker = (CALayer) -> CALayer?
typealias reusePieLayer = (Int) -> CALayer?
typealias colorMaker = (UIColor) -> UIColor?

enum TTPieDirection {
    case normal
    case anti
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
        guard let pie = layer as? TTSectorLayer, (sector.minRadius < sector.maxRadius || sector.minRadius >= 0 || sector.maxRadius >= 0)
            else { return layer }
        let pieCenter = CGPoint.init(x: pieView.frame.size.width / 2.0 + sector.centerOffset.x, y: pieView.frame.size.height / 2.0 + sector.centerOffset.y)
        let sectorPath = UIBezierPath()
        //Get the sector startAngle and endAngle from sector's startPercent and endPercent
        let startAngle = pieView.startAngle + (sector.startPercent * Double.pi * 2) * (pieView.direction == TTPieDirection.normal ? 1 : -1);
        let endAngle = pieView.startAngle + (sector.endPercent * Double.pi * 2) * (pieView.direction == TTPieDirection.normal ? 1 : -1);
        //Get startPoint,endPoint to draw the path
        let startInnerPoint = CGPoint.init(x: CGFloat(sector.minRadius * cos(startAngle) + Double(pieCenter.x)), y: CGFloat(sector.minRadius * sin(startAngle) + Double(pieCenter.y)))
        let endOutterPoint = CGPoint.init(x: CGFloat(sector.maxRadius * cos(endAngle) + Double(pieCenter.x)), y: CGFloat(sector.maxRadius * sin(endAngle) + Double(pieCenter.y)))
        
        //Begin to draw the path
        if sector.minRadius > 0 {
            sectorPath.move(to: startInnerPoint)
            sectorPath.addArc(withCenter: pieCenter, radius: CGFloat(sector.minRadius), startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: pieView.direction == .normal)
            sectorPath.addLine(to: endOutterPoint);
            sectorPath.addArc(withCenter: pieCenter, radius: CGFloat(sector.maxRadius), startAngle: CGFloat(endAngle), endAngle: CGFloat(startAngle), clockwise: pieView.direction != .normal)
            
        }else {
            sectorPath.move(to: pieCenter)
            sectorPath.addLine(to: endOutterPoint)
            sectorPath.addArc(withCenter: pieCenter, radius: CGFloat(sector.maxRadius), startAngle: CGFloat(endAngle), endAngle: CGFloat(startAngle), clockwise: pieView.direction != .normal)
            sectorPath.addLine(to: pieCenter)
        }
        //draw end
        sectorPath.close()
        pie.path = sectorPath.cgPath
        if let fillColor = sector.fillColor {
            pie.fillColor = fillColor.cgColor
        }else {
            pie.fillColor = nil
        }
        if let borderColor = sector.borderColor {
            pie.strokeColor = borderColor.cgColor
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
   func numberOfSectorInPieView(_ pieView : TTPieView) -> Int
   func pieView(_ pieView : TTPieView, sectorModelForIndex index : Int) -> Sector
}

protocol TTPieViewDelegate : NSObjectProtocol {
    
    func pieView(_ pieView : TTPieView, didClickPieLayer layer : TTSectorLayer, atPoint point : CGPoint) -> Void
    func pieView(_ pieView : TTPieView, didUnClickPieLayer layer : TTSectorLayer) -> Void
}

class TTSectorLayer: CAShapeLayer {
    var sector : Sector?
    
}



class TTPieView: UIView {
    weak var dataSource : TTPieViewDataSource?
    weak var delegate : TTPieViewDelegate?
    fileprivate var oldRect = CGRect.zero
    
    var  currentSectorNum : Int = 0
    
    var startAngle = 0.0
    var direction : TTPieDirection = .normal
    
    //make reuseList
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
                    pieLayer.contentsScale = UIScreen.main.scale
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
        if !self.oldRect.size.equalTo(self.frame.size) {
            self.reloadCurrentPieLayer()
        }
        self.oldRect = self.frame
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
    
    func reloadCurrentPieLayer() -> Void {
        if self.reusePiesList.count > 0 {
            for pieLayer in reusePiesList {
                (pieLayer.sector! + self)(pieLayer)
            }
        }else {
            self .reloadView()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touchPoint = touches.first?.location(in: self) else {return}
        for pieLayer in self.reusePiesList {
            let path = UIBezierPath.init(cgPath: pieLayer.path!)
            if path.contains(touchPoint) {
                self.delegate?.pieView(self, didClickPieLayer: pieLayer, atPoint: touchPoint)
                break
            }
        }
    }
 
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
         guard let touchPoint = touches.first?.location(in: self) else {return}
        for pieLayer in self.reusePiesList {
            let path = UIBezierPath.init(cgPath: pieLayer.path!)
            if path.contains(touchPoint) {
                self.delegate?.pieView(self, didClickPieLayer: pieLayer, atPoint :touchPoint)
            }else {
                self.delegate?.pieView(self, didUnClickPieLayer: pieLayer)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
            for pieLayer in self.reusePiesList {
                self.delegate?.pieView(self, didUnClickPieLayer: pieLayer)
            }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        for pieLayer in self.reusePiesList {
            self.delegate?.pieView(self, didUnClickPieLayer: pieLayer)
        }
    }
}




extension UIColor {
    func brinessColor(_ brightnessOffset : CGFloat) -> colorMaker {
        return { [weak self]
            color in
            guard let strongSelf = self else {return nil}
            var hue : CGFloat = 0, saturation : CGFloat = 0, brightness : CGFloat = 0, alpha : CGFloat = 0
            strongSelf.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            brightness += brightnessOffset
            saturation -= 0.2
           return UIColor.init(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
    }
}


