# TTPieChart
一个用函数式编程实现的饼图
## DemoGif
![DemoGif](https://github.com/TTube/TTPieChart/blob/master/DemoGif/DemoGif.gif?raw=true)

## UseAge

+ 在dataSource 响应两个方法
 

``` swift
    numberOfSectorInPieView(_ : _) -> Int
    pieView(_ : _, sectorModelForIndex _ : _) -> Sector

```

+ 响应触摸则需要响应一下两个方法

``` swift
     pieView(_: _, didClickPieLayer _ : _, atPoint _ : _) -> Void
     pieView(_ : _, didUnClickPieLayer _ : _) -> Void

```
