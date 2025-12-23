//
//  MediaItem.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import UIKit
import AVFoundation

/// 媒体类型枚举
enum MediaType {
    case image
    case video
}

/// 统一的媒体项目模型
struct MediaItem: Identifiable {
    let id = UUID()
    let type: MediaType
    let thumbnail: UIImage
    let data: Data? // 图片数据
    let videoURL: URL? // 视频URL（临时文件）
    let duration: TimeInterval? // 视频时长
    
    /// 创建图片类型的媒体项
    static func image(thumbnail: UIImage, data: Data) -> MediaItem {
        MediaItem(
            type: .image,
            thumbnail: thumbnail,
            data: data,
            videoURL: nil,
            duration: nil
        )
    }
    
    /// 创建视频类型的媒体项
    static func video(thumbnail: UIImage, url: URL, duration: TimeInterval) -> MediaItem {
        MediaItem(
            type: .video,
            thumbnail: thumbnail,
            data: nil,
            videoURL: url,
            duration: duration
        )
    }
    
    /// 格式化的时长显示
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

