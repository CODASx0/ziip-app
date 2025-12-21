//
//  PhotoGridView.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import SwiftUI

/// 照片网格视图 - 简洁风格
struct PhotoGridView: View {
    let images: [UIImage] // 实际上是缩略图
    let targetRatio: AspectRatio // 目标比例
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
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    PhotoGridItem(image: image, targetRatio: targetRatio) {
                        onRemove(index)
                    }
                }
            }
            .padding(.bottom, 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: columns.count) // 添加平滑过渡动画
        }
    }
}

/// 照片网格项目
struct PhotoGridItem: View {
    let image: UIImage
    let targetRatio: AspectRatio
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .aspectRatio(targetRatio.value, contentMode: .fit) // 使用 contentMode: .fit 让容器自适应比例
            .background(Color.gray.opacity(0.1))
            .clipped()
            
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
