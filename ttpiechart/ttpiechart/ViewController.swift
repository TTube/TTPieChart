//
//  ViewController.swift
//  ttpiechart
//
//  Created by Galvin on 16/4/12.
//  Copyright © 2016年 Galvin. All rights reserved.
//

import UIKit


class ViewController: UIViewController  {
    lazy var mainView : UITableView  = {
        var mainView : UITableView = UITableView.init()
        mainView.backgroundColor = UIColor.whiteColor()
        return mainView
    }()
    var pieView : TTPieView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layoutIfNeeded()
        let pieView = TTPieView.init(frame: self.view.frame)
        pieView.backgroundColor = UIColor.whiteColor()
        pieView.delegate = self
        pieView.startAngle = -M_PI_2
        self.view.addSubview(pieView)
        self.pieView = pieView
        
        let reloadBtn = UIButton.init(frame: CGRectMake(20.0, 64.0, 100.0, 60.0))
        reloadBtn.backgroundColor = UIColor.darkGrayColor()
        reloadBtn.setTitle("reload", forState: .Normal)
        reloadBtn.addTarget(self, action: Selector("clickReload"), forControlEvents: .TouchUpInside)
        self.view.addSubview(reloadBtn)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func clickReload() -> Void {
        if let pieView = pieView {
            pieView.reloadView()
        }
    }
}

extension ViewController : TTPieViewDelegate {
    func numberOfSectorInPieView(pieView: TTPieView) -> Int {
        return Int(arc4random() % 6) + 1
    }
    
    func randomColor() -> UIColor {
        let  hue = CGFloat((Double(arc4random() % 256) / 256.0 )); //0.0 to 1.0
        let saturation = CGFloat((Double(arc4random() % 128) / 256.0 ) + 0.5); // 0.5 to 1.0,away from white
        let  brightness = CGFloat(( Double(arc4random() % 128) / 256.0 ) + 0.5); //0.5 to 1.0,away from black
        return UIColor.init(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
    
    func pieView(pieView: TTPieView, sectorModelForIndex index: Int) -> Sector {
        let percentArr = [
            [0.0,0.15],
            [0.15,0.3],
            [0.3, 0.4],
            [0.4, 0.7],
            [0.7, 0.8],
            [0.8, 1.0]
        ]
        var sector = Sector()
        sector.minRadius = 60.0
        sector.maxRadius = 160.0
        sector.fillColor = self.randomColor()
        sector.startPercent = percentArr[index][0]
        sector.endPercent = percentArr[index][1]
        return sector
    }
}
