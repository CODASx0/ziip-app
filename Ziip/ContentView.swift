//
//  ContentView.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import SwiftUI
import PhotosUI
import Photos

struct ContentView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var thumbnails: [UIImage] = []
    @State private var selectedRatio: AspectRatio = .ratio16_9
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0
    @State private var isComplete = false
    @State private var processedCount = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let imageProcessor = ImageProcessor()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. 比例选择器
                ratioSelector
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemBackground))
                
                
                
                // 2. 内容区域
                if thumbnails.isEmpty {
                    emptyState
                } else {
                    PhotoGridView(
                        images: thumbnails,
                        targetRatio: selectedRatio
                    ) { index in
                        withAnimation {
                            if index < thumbnails.count { thumbnails.remove(at: index) }
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
                        totalCount: selectedItems.count,
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
            
            Text("选择照片开始处理")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("点击下方按钮从相册中选择照片")
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
                // 选择照片按钮
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: PhotoPickerConfiguration.maxSelectionCount,
                    matching: PhotoPickerConfiguration.filter
                ) {
                    Label("选择照片", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
                .onChange(of: selectedItems) { oldValue, newValue in
                    Task {
                        await loadThumbnails(from: newValue)
                    }
                }
                .glassEffect()
                
                // 导出按钮
                Button {
                    Task {
                        await processImages()
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
    
    private func loadThumbnails(from items: [PhotosPickerItem]) async {
        var newThumbnails: [UIImage] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let thumbnail = imageProcessor.loadThumbnail(from: data) {
                newThumbnails.append(thumbnail)
            }
        }
        
        await MainActor.run {
            thumbnails = newThumbnails
        }
    }
    
    private func processImages() async {
        guard !selectedItems.isEmpty else { return }
        
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            alertMessage = "请在设置中允许访问照片库"
            showAlert = true
            return
        }
        
        isProcessing = true
        processingProgress = 0
        
        processedCount = await imageProcessor.processAndSaveImages(
            selectedItems,
            to: selectedRatio
        ) { progress in
            processingProgress = progress
        }
        
        if processedCount > 0 {
            isComplete = true
        } else {
            isProcessing = false
            alertMessage = "处理图片失败"
            showAlert = true
        }
    }
    
    private func resetState() {
        isProcessing = false
        isComplete = false
        processingProgress = 0
        processedCount = 0
        withAnimation {
            thumbnails = []
            selectedItems = []
        }
    }
}

#Preview {
    ContentView()
}
