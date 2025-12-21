//
//  AspectRatioButton.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import SwiftUI

/// 宽高比选择按钮 - 简洁风格
struct AspectRatioButton: View {
    let ratio: AspectRatio
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // 比例预览矩形
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
                    )
                    .frame(
                        width: ratio.previewSize.width,
                        height: ratio.previewSize.height
                    )
                    .frame(width: 44, height: 44) // 容器固定大小
                
                // 比例文字
                Text(ratio.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        AspectRatioButton(ratio: .ratio16_9, isSelected: true) {}
        AspectRatioButton(ratio: .ratio1_1, isSelected: false) {}
    }
    .padding()
}
