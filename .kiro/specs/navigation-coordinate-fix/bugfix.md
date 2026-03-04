# Bugfix Requirements Document

## Introduction

导航模块存在三个关键的坐标显示问题，影响用户的导航体验。当用户输入起点和终点进行路径规划时，地图上显示的导航路径位置不正确，出现明显偏移；输入的地点在地图上的标记位置也不准确；此外，进入导航模块时，地图上没有显示用户当前位置的标记点，导致用户无法直观看到自己的位置。

这些问题的根本原因是：
1. 高德地图API返回的polyline坐标和地点坐标可能存在坐标系不匹配
2. 坐标传递到WebView时的格式转换可能有误
3. 缺少当前位置标记的初始化逻辑

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN 用户输入起点和终点并触发路径规划 THEN 系统在地图上绘制的导航路径位置偏移，不在起点和终点之间的正确位置

1.2 WHEN 用户搜索地点并在地图上添加标记 THEN 系统显示的标记点位置偏移，不在指定的经纬度位置

1.3 WHEN 用户进入导航模块且地图加载完成 THEN 系统没有在地图上显示当前位置的标记点

### Expected Behavior (Correct)

2.1 WHEN 用户输入起点和终点并触发路径规划 THEN 系统SHALL在地图上准确绘制导航路径，路径应该精确显示在起点和终点之间的正确地理位置

2.2 WHEN 用户搜索地点并在地图上添加标记 THEN 系统SHALL在指定的经纬度位置准确显示标记点，标记点应该与实际地理位置一致

2.3 WHEN 用户进入导航模块且地图加载完成并获取到当前位置 THEN 系统SHALL自动在地图上添加一个标记点显示用户的当前位置

### Unchanged Behavior (Regression Prevention)

3.1 WHEN 用户进行POI搜索 THEN 系统SHALL CONTINUE TO正确返回搜索结果列表和距离信息

3.2 WHEN 用户点击地图控制按钮（缩放、回到当前位置、切换日夜模式） THEN 系统SHALL CONTINUE TO正确响应并执行相应的地图操作

3.3 WHEN 用户开始导航并移动 THEN 系统SHALL CONTINUE TO正确计算剩余距离、预计时间和提供语音导航指引

3.4 WHEN 用户停止导航 THEN 系统SHALL CONTINUE TO正确清除地图上的路线和标记，恢复到定位模式
