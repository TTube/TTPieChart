# TTPieChart
一个用函数式编程实现的饼图
## DemoGif
![DemoGif](https://github.com/TTube/TTPieChart/blob/master/DemoGif/DemoGif.gif?raw=true)

## UseAge

+ 在dataSource 响应两个方法
 

``` swift
   func numberOfSectorInPieView(_ : _) -> Int
   func pieView(_ : _, sectorModelForIndex _ : _) -> Sector

```

+ 响应触摸则需要响应一下两个方法

``` swift
    func pieView(pieView : TTPieView, didClickPieLayer layer : TTSectorLayer, atPoint point : CGPoint) -> Void
    func pieView(pieView : TTPieView, didUnClickPieLayer layer : TTSectorLayer) -> Void

```
