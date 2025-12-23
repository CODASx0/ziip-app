//
//  PhotoGridView.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import SwiftUI

/// 媒体网格视图 - 简洁风格
struct PhotoGridView: View {
    let mediaItems: [MediaItem]
    let targetRatio: AspectRatio
    let onRemove: (Int) -> Void
    
    // 根据当前比例动态计算列配置
    private var columns: [GridItem] {
        let count: Int
        switch targetRatio {
        case .ratio16_9, .ratio3_2:
            count = 2
        case .ratio4_3, .ratio1_1, .ratio3_4:
            count = 3
        case .ratio2_3, .ratio9_16:
            count = 4
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                    MediaGridItem(item: item, targetRatio: targetRatio) {
                        onRemove(index)
                    }
                }
            }
            .padding(.bottom, 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: columns.count)
        }
    }
}

/// 媒体网格项目
struct MediaGridItem: View {
    let item: MediaItem
    let targetRatio: AspectRatio
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                Image(uiImage: item.thumbnail)
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .aspectRatio(targetRatio.value, contentMode: .fit)
            .background(Color.gray.opacity(0.1))
            .clipped()
            .overlay(alignment: .bottomLeading) {
                // 视频标识和时长
                if item.type == .video {
                    HStack(spacing: 4) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 10))
                        if let duration = item.formattedDuration {
                            Text(duration)
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.6))
                    .cornerRadius(4)
                    .padding(4)
                }
            }
            
            // 删除按钮
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            .offset(x: -4, y: 4)
        }
    }
}

// MARK: - 兼容旧接口（便于过渡）
extension PhotoGridView {
    /// 兼容旧的图片数组接口
    init(images: [UIImage], targetRatio: AspectRatio, onRemove: @escaping (Int) -> Void) {
        self.mediaItems = images.map { MediaItem.image(thumbnail: $0, data: Data()) }
        self.targetRatio = targetRatio
        self.onRemove = onRemove
    }
}
