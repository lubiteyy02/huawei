# 实施计划: 导航服务模块

## 概述

本实施计划旨在修复导航服务模块的核心问题:路线绘制和标记点显示功能。当前系统已成功集成高德地图Web Service API进行路径规划,但在HarmonyOS MapKit上的可视化呈现存在缺陷。本计划将实现完整的地图绘制功能,让导航按钮能够正常工作。

**核心目标**:
- 修复路线绘制功能,在地图上显示导航路径
- 修复标记点添加功能,显示起点、终点和POI位置
- 实现地图覆盖物管理(添加、移除、清除)
- 优化用户体验,提供清晰的视觉反馈

## 任务列表

- [x] 1. 实现MapService核心绘制功能
  - [x] 1.1 实现drawRoute()方法 - 绘制路线到地图
    - 解析RouteInfo中的polyline坐标
    - 创建MapPolyline选项对象(颜色、宽度、样式)
    - 调用mapController.addPolyline()添加到地图
    - 保存polyline引用以便后续管理
    - 添加起点和终点标记
    - 调整相机视角显示完整路线
    - _Requirements: FR-2.2.2.1_

  - [ ]* 1.2 编写drawRoute()的属性测试
    - **Property 1: 路线绘制完整性**
    - **Validates: Requirements FR-2.2.2.1**

  - [x] 1.3 实现addMarker()方法 - 添加标记点到地图
    - 创建MapMarker选项对象(位置、标题、图标)
    - 根据MarkerType设置不同的图标样式
    - 调用mapController.addMarker()添加到地图
    - 生成唯一markerId并保存引用
    - 返回markerId供后续管理使用
    - _Requirements: FR-2.4.2.3_

  - [ ]* 1.4 编写addMarker()的属性测试
    - **Property 3: 标记添加和移除往返**
    - **Validates: Requirements FR-2.4.2.3**

- [x] 2. 实现地图覆盖物管理功能
  - [x] 2.1 实现clearOverlays()方法 - 清除所有地图覆盖物
    - 移除当前polyline(如果存在)
    - 遍历并移除所有markers
    - 清空markers集合
    - 重置currentPolyline为null
    - _Requirements: FR-2.2.2.1_

  - [x] 2.2 实现removeMarker()方法 - 移除指定标记
    - 根据markerId查找marker对象
    - 调用mapController.removeMarker()移除
    - 从markers集合中删除引用
    - _Requirements: FR-2.4.2.3_

  - [x] 2.3 添加覆盖物管理的私有属性
    - 添加currentPolyline属性存储当前路线
    - 添加markers: Map<string, any>存储所有标记
    - 添加markerIdCounter用于生成唯一ID
    - _Requirements: FR-2.2.2.1, FR-2.4.2.3_

- [x] 3. 实现polyline解析和坐标处理
  - [x] 3.1 完善parsePolyline()方法 - 解析高德polyline编码
    - 处理空字符串和无效输入
    - 按分号分割坐标对
    - 解析每个坐标对(经度,纬度)
    - 转换为mapCommon.LatLng格式
    - 添加坐标有效性验证
    - 添加错误处理和日志
    - _Requirements: FR-2.2.2.1_

  - [ ]* 3.2 编写parsePolyline()的属性测试
    - **Property 2: Polyline解析正确性**
    - **Validates: Requirements FR-2.2.2.1**

  - [x] 3.3 实现simplifyPoints()方法 - 坐标点抽稀优化
    - 检查点数量是否超过阈值(500点)
    - 计算抽稀步长
    - 按步长选取坐标点
    - 确保保留最后一个点
    - 返回简化后的坐标数组
    - _Requirements: 3.1 (性能需求)_

- [x] 4. 实现相机视角控制
  - [x] 4.1 实现fitBounds()方法 - 自动调整地图视角
    - 计算所有坐标点的边界(最小/最大经纬度)
    - 计算中心点坐标
    - 根据边界范围计算合适的缩放级别
    - 创建CameraPosition对象
    - 调用mapController.animateCamera()平滑移动
    - _Requirements: FR-2.2.2.1_

  - [x] 4.2 优化moveToLocation()方法
    - 添加动画效果参数
    - 支持自定义缩放级别
    - 添加移动完成回调
    - _Requirements: FR-2.1.3.3_

- [x] 5. 添加MarkerType枚举和图标管理
  - [x] 5.1 在NavigationModels.ets中添加MarkerType枚举
    - 定义START(起点)类型
    - 定义END(终点)类型
    - 定义POI(兴趣点)类型
    - 定义CURRENT(当前位置)类型
    - _Requirements: FR-2.4.2.3_

  - [x] 5.2 实现getMarkerIcon()辅助方法
    - 根据MarkerType返回对应图标资源
    - 为不同类型设置不同颜色和样式
    - 处理图标加载失败的情况
    - _Requirements: FR-2.4.2.3_

  - [x] 5.3 实现generateMarkerId()辅助方法
    - 使用计数器生成唯一ID
    - 格式: "marker_" + timestamp + "_" + counter
    - 确保ID唯一性
    - _Requirements: FR-2.4.2.3_

- [x] 6. Checkpoint - 验证核心绘制功能
  - 确保所有测试通过,运行应用验证路线能正确显示在地图上,询问用户是否有问题。

- [ ] 7. 完善错误处理和日志
  - [ ] 7.1 在drawRoute()中添加完整错误处理
    - 验证mapController是否已初始化
    - 验证routeInfo参数有效性
    - 验证polyline字符串非空
    - 验证解析后的坐标点数量
    - 捕获并记录所有异常
    - 失败时清理部分绘制的覆盖物
    - _Requirements: 3.5.2_

  - [ ] 7.2 在addMarker()中添加完整错误处理
    - 验证mapController是否已初始化
    - 验证location参数有效性(经纬度范围)
    - 验证MarkerType有效性
    - 捕获并记录所有异常
    - 失败时返回空字符串
    - _Requirements: 3.5.2_

  - [ ] 7.3 在parsePolyline()中添加完整错误处理
    - 处理空字符串输入
    - 处理无效格式(缺少分号或逗号)
    - 处理非数字坐标值
    - 处理超出范围的坐标值
    - 记录解析失败的详细信息
    - _Requirements: 3.5.2_

  - [ ] 7.4 统一日志格式
    - 使用[MapService]前缀标识模块
    - 区分ERROR、WARN、INFO级别
    - 记录关键操作(绘制路线、添加标记、清除覆盖物)
    - 记录性能指标(坐标点数量、处理时间)
    - _Requirements: 3.5.2_

- [ ] 8. 实现距离计算功能
  - [ ] 8.1 实现calculateDistance()方法 - 计算两点距离
    - 使用Haversine公式计算球面距离
    - 输入两个Location对象
    - 返回距离(单位:米)
    - 处理相同点的情况(返回0)
    - _Requirements: FR-2.3.1.2, FR-2.4.2.1_

  - [ ]* 8.2 编写距离计算的属性测试
    - **Property 4: 距离计算对称性**
    - **Property 5: 距离计算非负性**
    - **Validates: Requirements FR-2.3.1.2, FR-2.4.2.1**

- [ ] 9. 优化NavigationService导航逻辑
  - [ ] 9.1 完善startNavigation()方法
    - 调用MapService.clearOverlays()清除旧路线
    - 获取当前位置作为起点
    - 调用MapService.planRoute()规划路线
    - 调用MapService.drawRoute()绘制路线
    - 更新导航状态为NAVIGATING
    - 启动位置追踪
    - 通知UI更新
    - _Requirements: FR-2.3.1.1_

  - [ ] 9.2 实现checkDeviation()方法 - 偏航检测
    - 获取当前位置和路线坐标点
    - 计算当前位置到路线的最短距离
    - 与偏航阈值(100米)比较
    - 返回是否偏航的布尔值
    - _Requirements: FR-2.3.3.1_

  - [ ]* 9.3 编写偏航检测的属性测试
    - **Property 7: 偏航检测正确性**
    - **Validates: Requirements FR-2.3.3.1**

  - [ ] 9.4 实现replanRoute()方法 - 重新规划路线
    - 检测到偏航时触发
    - 清除当前路线
    - 使用当前位置作为新起点
    - 调用planRoute()重新规划
    - 调用drawRoute()绘制新路线
    - 语音提示"正在重新规划路线"
    - _Requirements: FR-2.3.3.2_

  - [ ] 9.5 完善onLocationUpdate()方法
    - 更新当前位置
    - 计算剩余距离和时间
    - 检查是否偏航
    - 检查是否到达目的地
    - 更新导航步骤
    - 触发语音播报
    - 通知UI更新
    - _Requirements: FR-2.3.1.1_

  - [ ]* 9.6 编写到达检测的属性测试
    - **Property 8: 到达检测正确性**
    - **Validates: Requirements FR-2.3.4.1**

- [ ] 10. Checkpoint - 验证导航逻辑
  - 确保所有测试通过,运行应用验证导航过程正常,询问用户是否有问题。

- [ ] 11. 完善UI交互和用户体验
  - [ ] 11.1 更新EnhancedNavigationModule的导航面板
    - 显示剩余距离(格式化为公里或米)
    - 显示预计到达时间
    - 显示下一步转向指令
    - 显示当前道路名称
    - 添加停止导航按钮
    - _Requirements: FR-2.3.1.2, FR-2.3.1.3_

  - [ ] 11.2 添加导航状态视觉反馈
    - 规划中显示加载动画
    - 导航中高亮显示路线
    - 偏航时路线变为红色
    - 到达时显示完成提示
    - _Requirements: 3.2 (可用性需求)_

  - [ ] 11.3 优化搜索结果的POI标记
    - 点击搜索结果时在地图上添加标记
    - 使用POI类型的图标
    - 点击标记显示POI详情
    - 提供"导航到此"按钮
    - _Requirements: FR-2.4.2.3, FR-2.4.3.3_

  - [ ] 11.4 添加错误提示UI
    - 定位失败提示
    - 路径规划失败提示
    - 网络连接失败提示
    - 地图加载失败提示
    - 使用Toast或AlertDialog显示
    - _Requirements: 3.2 (可用性需求)_

- [ ] 12. 实现POI搜索和标记功能
  - [ ] 12.1 完善searchPOI()方法
    - 调用AmapService.searchPOI()获取结果
    - 在地图上为每个POI添加标记
    - 保存POI标记的ID列表
    - 点击标记显示POI信息
    - _Requirements: FR-2.4.1.1, FR-2.4.2.3_

  - [ ] 12.2 实现clearPOIMarkers()方法
    - 遍历POI标记ID列表
    - 调用removeMarker()移除每个标记
    - 清空POI标记ID列表
    - _Requirements: FR-2.4.2.3_

  - [ ] 12.3 优化POI搜索结果排序
    - 按距离从近到远排序
    - 计算每个POI到当前位置的距离
    - 更新UI显示排序后的结果
    - _Requirements: FR-2.4.2.2_

  - [ ]* 12.4 编写POI搜索的属性测试
    - **Property 9: POI搜索结果距离排序**
    - **Validates: Requirements FR-2.4.2.2**

- [ ] 13. 性能优化
  - [ ] 13.1 优化大量坐标点的处理
    - 在parsePolyline()中调用simplifyPoints()
    - 设置阈值为500点
    - 测试不同抽稀算法的效果
    - 确保路线平滑度
    - _Requirements: 3.1 (性能需求)_

  - [ ] 13.2 优化内存管理
    - 及时清除不用的覆盖物
    - 避免重复创建对象
    - 使用对象池管理marker
    - 定期检查内存使用
    - _Requirements: 3.1 (性能需求)_

  - [ ] 13.3 优化位置更新频率
    - 根据速度动态调整更新频率
    - 静止时降低更新频率
    - 高速时提高更新频率
    - 避免频繁的UI刷新
    - _Requirements: 3.1 (性能需求)_

- [ ] 14. 添加单元测试
  - [ ]* 14.1 编写MapService单元测试
    - 测试已知坐标的距离计算
    - 测试空polyline处理
    - 测试无效polyline格式
    - 测试边界坐标值
    - 测试覆盖物管理
    - _Requirements: 5.2 (质量验收)_

  - [ ]* 14.2 编写NavigationService单元测试
    - 测试导航状态转换
    - 测试停止未开始的导航
    - 测试偏航检测逻辑
    - 测试到达检测逻辑
    - _Requirements: 5.2 (质量验收)_

  - [ ]* 14.3 编写AmapService单元测试
    - 测试路径规划API调用
    - 测试无效坐标处理
    - 测试POI搜索API调用
    - 测试网络错误处理
    - _Requirements: 5.2 (质量验收)_

- [ ] 15. Final Checkpoint - 完整功能验证
  - 确保所有测试通过,运行完整的导航流程测试,询问用户是否满意。

## 注意事项

- 标记为`*`的任务是可选的测试任务,可以跳过以加快MVP开发
- 每个任务都引用了具体的需求编号,确保可追溯性
- Checkpoint任务用于阶段性验证,确保增量开发的质量
- 属性测试验证通用正确性属性,单元测试验证具体示例和边界情况
- 优先实现P0核心功能,确保导航按钮能正常工作

## 实施顺序说明

1. **任务1-6**: 核心绘制功能,这是最高优先级,必须首先完成
2. **任务7-8**: 错误处理和距离计算,提升稳定性
3. **任务9-10**: 导航逻辑优化,实现完整的导航流程
4. **任务11-12**: UI优化和POI功能,提升用户体验
5. **任务13-15**: 性能优化和测试,确保质量
