//
//  ProcessingView.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import SwiftUI

/// 处理进度视图 - 简洁风格
struct ProcessingView: View {
    let progress: Double
    let totalCount: Int
    let isComplete: Bool
    let onDismiss: () -> Void
    
    var processedCount: Int {
        Int(Double(totalCount) * progress)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 20) {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                    
                    Text("处理完成")
                        .font(.headline)
                    
                    Text("已保存 \(totalCount) 张图片")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button("完成") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    
                } else {
                    ProgressView(value: progress) {
                        Text("\(Int(progress * 100))%")
                    }
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    
                    Text("正在处理 \(processedCount)/\(totalCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .frame(maxWidth: 240)
        }
    }
}
