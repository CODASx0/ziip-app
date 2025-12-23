//
//  ContentView.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import SwiftUI
import PhotosUI
import Photos
import AVFoundation

struct ContentView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var mediaItems: [MediaItem] = []
    @State private var selectedRatio: AspectRatio = .ratio16_9
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0
    @State private var isComplete = false
    @State private var processedImageCount = 0
    @State private var processedVideoCount = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let imageProcessor = ImageProcessor()
    private let videoProcessor = VideoProcessor()
    
    /// 当前选择的图片数量
    private var imageCount: Int {
        mediaItems.filter { $0.type == .image }.count
    }
    
    /// 当前选择的视频数量
    private var videoCount: Int {
        mediaItems.filter { $0.type == .video }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. 比例选择器
                ratioSelector
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemBackground))
                
                
                
                // 2. 内容区域
                if mediaItems.isEmpty {
                    emptyState
                } else {
                    PhotoGridView(
                        mediaItems: mediaItems,
                        targetRatio: selectedRatio
                    ) { index in
                        withAnimation {
                            if index < mediaItems.count { 
                                // 清理视频临时文件
                                if let url = mediaItems[index].videoURL {
                                    try? FileManager.default.removeItem(at: url)
                                }
                                mediaItems.remove(at: index) 
                            }
                            if index < selectedItems.count { selectedItems.remove(at: index) }
                        }
                    }
                }
                
                // 3. 底部操作栏
                bottomBar
            }
            .navigationTitle("Ziip")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black) // 纯黑背景
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .overlay {
                // 处理遮罩
                if isProcessing || isComplete {
                    ProcessingView(
                        progress: processingProgress,
                        totalCount: mediaItems.count,
                        imageCount: processedImageCount,
                        videoCount: processedVideoCount,
                        isComplete: isComplete
                    ) {
                        resetState()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Views
    
    private var ratioSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AspectRatio.allCases) { ratio in
                    AspectRatioButton(
                        ratio: ratio,
                        isSelected: ratio == selectedRatio
                    ) {
                        withAnimation {
                            selectedRatio = ratio
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            Text("选择照片或视频开始处理")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("点击下方按钮从相册中选择")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            
            
            HStack(spacing: 16) {
                // 选择媒体按钮
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: PhotoPickerConfiguration.maxSelectionCount,
                    matching: PhotoPickerConfiguration.filter
                ) {
                    Label("选择媒体", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
                .onChange(of: selectedItems) { oldValue, newValue in
                    Task {
                        await loadMediaItems(from: newValue)
                    }
                }
                .glassEffect()
                
                // 导出按钮
                Button {
                    Task {
                        await processMedia()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .imageScale(.medium)
                            .offset(y: -1) // 向上微调图标以视觉居中
                        Text("导出")
                        
                        Spacer()
                    }
                    .padding(.bottom, 2)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedItems.isEmpty)
                .glassEffect()
                
            }
            .padding(16)
            
            
        }
    }
    
    // MARK: - Methods
    
    private func loadMediaItems(from items: [PhotosPickerItem]) async {
        var newMediaItems: [MediaItem] = []
        
        for item in items {
            // 检查是否为视频
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) }) {
                // 加载视频
                if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                    let thumbnail = videoProcessor.generateThumbnail(from: movie.url) ?? UIImage(systemName: "video")!
                    let duration = await videoProcessor.getVideoDuration(from: movie.url)
                    newMediaItems.append(.video(thumbnail: thumbnail, url: movie.url, duration: duration))
                }
            } else {
                // 加载图片
                if let data = try? await item.loadTransferable(type: Data.self),
                   let thumbnail = imageProcessor.loadThumbnail(from: data) {
                    newMediaItems.append(.image(thumbnail: thumbnail, data: data))
                }
            }
        }
        
        await MainActor.run {
            mediaItems = newMediaItems
        }
    }
    
    private func processMedia() async {
        guard !mediaItems.isEmpty else { return }
        
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            alertMessage = "请在设置中允许访问照片库"
            showAlert = true
            return
        }
        
        isProcessing = true
        processingProgress = 0
        processedImageCount = 0
        processedVideoCount = 0
        
        let total = mediaItems.count
        var currentIndex = 0
        
        for item in mediaItems {
            var success = false
            
            switch item.type {
            case .image:
                if let data = item.data,
                   let originalImage = UIImage(data: data),
                   let processedImage = imageProcessor.stretchImage(originalImage, to: selectedRatio) {
                    do {
                        try await PHPhotoLibrary.shared().performChanges {
                            PHAssetChangeRequest.creationRequestForAsset(from: processedImage)
                        }
                        success = true
                        processedImageCount += 1
                    } catch {
                        print("保存图片失败: \(error)")
                    }
                }
                
            case .video:
                if let url = item.videoURL {
                    success = await videoProcessor.stretchAndSaveVideo(from: url, to: selectedRatio)
                    if success {
                        processedVideoCount += 1
                    }
                }
            }
            
            currentIndex += 1
            let progress = Double(currentIndex) / Double(total)
            await MainActor.run {
                processingProgress = progress
            }
        }
        
        if processedImageCount > 0 || processedVideoCount > 0 {
            isComplete = true
        } else {
            isProcessing = false
            alertMessage = "处理失败"
            showAlert = true
        }
    }
    
    private func resetState() {
        isProcessing = false
        isComplete = false
        processingProgress = 0
        processedImageCount = 0
        processedVideoCount = 0
        
        // 清理视频临时文件
        for item in mediaItems {
            if let url = item.videoURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        withAnimation {
            mediaItems = []
            selectedItems = []
        }
    }
}

// MARK: - Video Transferable

/// 用于从 PhotosPicker 加载视频的 Transferable
struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            // 将视频复制到临时目录
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

#Preview {
    ContentView()
}
