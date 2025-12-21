//
//  AspectRatio.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import Foundation

/// 支持的图片宽高比
enum AspectRatio: String, CaseIterable, Identifiable {
    case ratio16_9 = "16:9"
    case ratio3_2 = "3:2"
    case ratio4_3 = "4:3"
    case ratio1_1 = "1:1"
    case ratio3_4 = "3:4"
    case ratio2_3 = "2:3"
    case ratio9_16 = "9:16"
    
    var id: String { rawValue }
    
    /// 宽高比值 (宽/高)
    nonisolated var value: CGFloat {
        switch self {
        case .ratio16_9: return 16.0 / 9.0
        case .ratio3_2: return 3.0 / 2.0
        case .ratio4_3: return 4.0 / 3.0
        case .ratio1_1: return 1.0
        case .ratio3_4: return 3.0 / 4.0
        case .ratio2_3: return 2.0 / 3.0
        case .ratio9_16: return 9.0 / 16.0
        }
    }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .ratio16_9: return "16:9 横屏"
        case .ratio3_2: return "3:2 横屏"
        case .ratio4_3: return "4:3 横屏"
        case .ratio1_1: return "1:1 方形"
        case .ratio3_4: return "3:4 竖屏"
        case .ratio2_3: return "2:3 竖屏"
        case .ratio9_16: return "9:16 竖屏"
        }
    }
    
    /// 图标示意图的宽高比例
    var previewSize: (width: CGFloat, height: CGFloat) {
        let baseSize: CGFloat = 40
        switch self {
        case .ratio16_9: return (baseSize, baseSize * 9 / 16)
        case .ratio3_2: return (baseSize, baseSize * 2 / 3)
        case .ratio4_3: return (baseSize, baseSize * 3 / 4)
        case .ratio1_1: return (baseSize * 0.8, baseSize * 0.8)
        case .ratio3_4: return (baseSize * 3 / 4, baseSize)
        case .ratio2_3: return (baseSize * 2 / 3, baseSize)
        case .ratio9_16: return (baseSize * 9 / 16, baseSize)
        }
    }
}
