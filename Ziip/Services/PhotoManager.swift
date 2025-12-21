//
//  PhotoManager.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import Photos
import PhotosUI
import SwiftUI

/// 照片管理器
@MainActor
@Observable
class PhotoManager {
    
    /// 保存图片到照片库
    /// - Parameter images: 要保存的图片数组
    /// - Returns: 保存是否成功
    func saveImages(_ images: [UIImage]) async -> Bool {
        // 请求保存权限
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        guard status == .authorized || status == .limited else {
            return false
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                for image in images {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
            }
            return true
        } catch {
            print("保存图片失败: \(error)")
            return false
        }
    }
}

/// PhotosPicker 配置
struct PhotoPickerConfiguration {
    static let maxSelectionCount = 50
    static let filter: PHPickerFilter = .images
}

