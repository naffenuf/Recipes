//
//  ImageCache.swift
//  Recipes
//
//  Created by Craig Boyce on 3/16/25.
//

import Foundation
import SwiftUI
import Combine

class ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 1 week in seconds
    
    private init() {
        // Set up memory cache limits
        memoryCache.countLimit = 100 // Max number of images to keep in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Set up disk cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Set up notification to clear memory cache when app receives memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Set up notification to clear expired cache when app enters background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearExpiredCache),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Set up notification to clear memory cache when app terminates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        // Clear expired cache on startup
        clearExpiredCache()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func image(for url: URL) -> UIImage? {
        // Check memory cache first
        let key = cacheKey(for: url)
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        let fileURL = cacheFileURL(for: url)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Update access time
            try? fileManager.setAttributes(
                [.modificationDate: Date()],
                ofItemAtPath: fileURL.path
            )
            
            // Store in memory cache
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    func storeImage(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: key as NSString)
        
        // Store in disk cache
        let fileURL = cacheFileURL(for: url)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    func removeImage(for url: URL) {
        let key = cacheKey(for: url)
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk cache
        let fileURL = cacheFileURL(for: url)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clearAllCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for url: URL) -> String {
        return url.absoluteString
    }
    
    private func cacheFileURL(for url: URL) -> URL {
        let key = cacheKey(for: url)
        let filename = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
        return cacheDirectory.appendingPathComponent(filename)
    }
    
    @objc private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    private func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    @objc private func clearExpiredCache() {
        let resourceKeys: [URLResourceKey] = [.contentModificationDateKey, .totalFileAllocatedSizeKey]
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: resourceKeys,
            options: .skipsHiddenFiles
        ) else {
            return
        }
        
        let expirationDate = Date().addingTimeInterval(-maxCacheAge)
        
        for fileURL in fileURLs {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  let modificationDate = resourceValues.contentModificationDate else {
                continue
            }
            
            if modificationDate < expirationDate {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
}

// MARK: - SwiftUI Image Extension

extension Image {
    static func cached(url: URL) -> Image {
        if let cachedImage = ImageCache.shared.image(for: url) {
            return Image(uiImage: cachedImage)
        }
        return Image(systemName: "photo")
    }
}

// MARK: - ImageLoader

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let url: URL?
    
    init(url: URL?) {
        self.url = url
        if url != nil {
            loadImage()
        }
    }
    
    func loadImage() {
        guard let url = url else {
            self.error = NSError(domain: "ImageLoader", code: 0, userInfo: [NSLocalizedDescriptionKey: "No URL provided"])
            return
        }
        
        // Check cache first
        if let cachedImage = ImageCache.shared.image(for: url) {
            self.image = cachedImage
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] image in
                guard let self = self, let image = image else { return }
                self.image = image
                ImageCache.shared.storeImage(image, for: url)
            }
            .store(in: &cancellables)
    }
    
    func cancel() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

// MARK: - CachedAsyncImage View

struct CachedAsyncImage<Content: View>: View {
    @StateObject private var loader: ImageLoader
    private let content: (AsyncImagePhase) -> Content
    private let url: URL?
    
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(.success(Image(uiImage: image)))
            } else if loader.isLoading {
                content(.empty)
            } else if loader.error != nil {
                content(.failure(loader.error!))
            } else {
                content(.empty)
            }
        }
        .onAppear {
            if url != nil {
                loader.loadImage()
            }
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
