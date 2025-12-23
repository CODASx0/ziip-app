//
//  VideoProcessor.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import AVFoundation
import UIKit
import Photos

/// 视频处理服务
actor VideoProcessor {
    
    /// 从视频中提取缩略图
    nonisolated func generateThumbnail(from url: URL, maxSize: CGFloat = 200) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: maxSize, height: maxSize)
        
        // 使用同步方式生成缩略图（用于快速预览）
        var image: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        
        imageGenerator.generateCGImageAsynchronously(for: .zero) { cgImage, time, error in
            if let cgImage = cgImage {
                image = UIImage(cgImage: cgImage)
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return image
    }
    
    /// 获取视频时长
    nonisolated func getVideoDuration(from url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return 0
        }
    }
    
    /// 将视频拉伸到目标宽高比并保存到相册
    /// - Parameters:
    ///   - inputURL: 输入视频URL
    ///   - targetRatio: 目标宽高比
    /// - Returns: 是否成功
    func stretchAndSaveVideo(from inputURL: URL, to targetRatio: AspectRatio) async -> Bool {
        let asset = AVURLAsset(url: inputURL)
        
        // 获取视频轨道
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            print("无法获取视频轨道")
            return false
        }
        
        // 获取原始视频尺寸和变换
        let naturalSize: CGSize
        let preferredTransform: CGAffineTransform
        do {
            naturalSize = try await videoTrack.load(.naturalSize)
            preferredTransform = try await videoTrack.load(.preferredTransform)
        } catch {
            print("无法加载视频属性: \(error)")
            return false
        }
        
        // 计算实际尺寸（考虑旋转）
        let isPortrait = preferredTransform.a == 0 && preferredTransform.d == 0
        let originalWidth = isPortrait ? naturalSize.height : naturalSize.width
        let originalHeight = isPortrait ? naturalSize.width : naturalSize.height
        
        let originalRatio = originalWidth / originalHeight
        let targetRatioValue = targetRatio.value
        
        var newWidth = originalWidth
        var newHeight = originalHeight
        
        // 计算新尺寸
        if originalRatio > targetRatioValue {
            // 原视频更宽，需要在高度方向拉伸
            newHeight = originalWidth / targetRatioValue
        } else if originalRatio < targetRatioValue {
            // 原视频更高，需要在宽度方向拉伸
            newWidth = originalHeight * targetRatioValue
        }
        
        // 确保尺寸为偶数（视频编码要求）
        newWidth = ceil(newWidth / 2) * 2
        newHeight = ceil(newHeight / 2) * 2
        
        // 创建输出URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // 创建导出组合
        let composition = AVMutableComposition()
        
        // 添加视频轨道到组合
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            return false
        }
        
        // 获取视频时长
        let duration: CMTime
        do {
            duration = try await asset.load(.duration)
            try compositionVideoTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: videoTrack,
                at: .zero
            )
        } catch {
            print("添加视频轨道失败: \(error)")
            return false
        }
        
        // 添加音频轨道（如果有）
        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try? compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: audioTrack,
                at: .zero
            )
        }
        
        // 获取帧率
        let frameRate: Float
        do {
            frameRate = try await videoTrack.load(.nominalFrameRate)
        } catch {
            frameRate = 30
        }
        
        // 计算缩放变换以拉伸视频
        let scaleX = newWidth / originalWidth
        let scaleY = newHeight / originalHeight
        
        let finalTransform: CGAffineTransform
        if isPortrait {
            // 对于竖屏视频，需要特殊处理
            finalTransform = CGAffineTransform(rotationAngle: .pi / 2)
                .translatedBy(x: 0, y: -newWidth)
                .scaledBy(x: scaleY, y: scaleX)
        } else {
            finalTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        }
        
        // 创建视频组合
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: newWidth, height: newHeight)
        videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
        
        // 创建图层指令
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(finalTransform, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        // 导出视频
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            print("无法创建导出会话")
            return false
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        
        // 使用新的导出 API
        do {
            try await exportSession.export(to: outputURL, as: .mp4)
        } catch {
            print("视频导出失败: \(error)")
            return false
        }
        
        // 保存到相册
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
            }
            
            // 清理临时文件
            try? FileManager.default.removeItem(at: outputURL)
            return true
        } catch {
            print("保存视频到相册失败: \(error)")
            try? FileManager.default.removeItem(at: outputURL)
            return false
        }
    }
}
