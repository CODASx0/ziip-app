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
    let imageCount: Int
    let videoCount: Int
    let isComplete: Bool
    let onDismiss: () -> Void
    
    var processedCount: Int {
        Int(Double(totalCount) * progress)
    }
    
    /// 完成提示文字
    private var completionText: String {
        var parts: [String] = []
        if imageCount > 0 {
            parts.append("\(imageCount) 张图片")
        }
        if videoCount > 0 {
            parts.append("\(videoCount) 个视频")
        }
        return "已保存 " + parts.joined(separator: "、")
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
                    
                    Text(completionText)
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
                    
                    if videoCount > 0 {
                        Text("视频处理可能需要较长时间")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
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

// MARK: - 兼容旧接口
extension ProcessingView {
    /// 兼容旧接口，默认都是图片
    init(progress: Double, totalCount: Int, isComplete: Bool, onDismiss: @escaping () -> Void) {
        self.progress = progress
        self.totalCount = totalCount
        self.imageCount = totalCount
        self.videoCount = 0
        self.isComplete = isComplete
        self.onDismiss = onDismiss
    }
}
