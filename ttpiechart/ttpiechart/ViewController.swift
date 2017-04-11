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
        mainView.backgroundColor = UIColor.white
        return mainView
    }()
    var pieView : TTPieView?

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layoutIfNeeded()
        let pieView = TTPieView.init(frame: CGRect(x: 20.0, y: 64.0, width: (self.view.frame.size.width * 4.0 / 5.0), height: (self.view.frame.size.height * 4.0 / 5.0)))
        pieView.center = self.view.center
        pieView.backgroundColor = UIColor.lightGray
        pieView.delegate = self
        pieView.dataSource = self
        pieView.startAngle = -.pi/2
        self.view.addSubview(pieView)
        self.pieView = pieView
        
        let reloadBtn = UIButton.init(frame: CGRect(x: 20.0, y: 64.0, width: 100.0, height: 60.0))
        reloadBtn.backgroundColor = UIColor.darkGray
        reloadBtn.setTitle("reload", for: UIControlState())
        reloadBtn.addTarget(self, action: #selector(clickReload), for: .touchUpInside)
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.pieView?.frame = CGRect(x: (self.pieView?.frame)!.minX , y: (self.pieView?.frame)!.minY, width: (self.view.frame.size.width * 4.0 / 5.0), height: (self.view.frame.size.height * 4.0 / 5.0))
        self.pieView?.center = self.view.center;
    }
    
}

extension ViewController : TTPieViewDataSource, TTPieViewDelegate {
    func numberOfSectorInPieView(_ pieView: TTPieView) -> Int {
        return 6
    }
    
    func randomColor() -> UIColor {
        let  hue = CGFloat((Double(arc4random() % 256) / 256.0 )); //0.0 to 1.0
        let saturation = CGFloat((Double(arc4random() % 128) / 256.0 ) + 0.5); // 0.5 to 1.0,away from white
        let  brightness = CGFloat(( Double(arc4random() % 128) / 256.0 ) + 0.5); //0.5 to 1.0,away from black
        return UIColor.init(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
    
    func pieView(_ pieView: TTPieView, sectorModelForIndex index: Int) -> Sector {
        let percentArr = [
            [0.0,0.15],
            [0.15,0.3],
            [0.3, 0.4],
            [0.4, 0.7],
            [0.7, 0.8],
            [0.8, 1.0]
        ]
        var sector = Sector()
        sector.minRadius = 30.0
        sector.maxRadius = 100.0
        sector.fillColor = self.randomColor()
        sector.startPercent = percentArr[index][0]
        sector.endPercent = percentArr[index][1]
        return sector
    }
    
    func pieView(_ pieView: TTPieView, didClickPieLayer layer: TTSectorLayer, atPoint point : CGPoint) {
            layer.setAffineTransform(CGAffineTransform(scaleX: CGFloat(1.2), y: CGFloat(1.2)))
        if let fillColor = layer.sector?.fillColor {
            layer.fillColor = fillColor.brinessColor(0.2)(fillColor)?.cgColor
        }
    }
    
    func pieView(_ pieView: TTPieView, didUnClickPieLayer layer: TTSectorLayer) {
        layer.setAffineTransform(CGAffineTransform.identity)
        layer.fillColor = layer.sector?.fillColor?.cgColor
    }
    
    
}
