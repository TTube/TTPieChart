# TTPieChart
一个用函数式编程实现的饼图
## DemoGif
![DemoGif](https://github.com/TTube/TTPieChart/blob/master/DemoGif/DemoGif.gif?raw=true)

## UseAge

+ 如果你需要展示你的饼图，你需要在dataSource 响应两个方法
 

``` swift
    numberOfSectorInPieView(_ : _) -> Int
    pieView(_ : _, sectorModelForIndex _ : _) -> Sector

```

+ 响应触摸则需要响应以下两个方法

``` swift
     pieView(_: _, didClickPieLayer _ : _, atPoint _ : _) -> Void
     pieView(_ : _, didUnClickPieLayer _ : _) -> Void

```
