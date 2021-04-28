//
//  MediaPreviewViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import Pageboy

final class MediaPreviewViewModel: NSObject {
    
    // input
    let context: AppContext
    let initialItem: PreviewItem
    weak var mediaPreviewImageViewControllerDelegate: MediaPreviewImageViewControllerDelegate?

    // output
    let viewControllers: [UIViewController]
    
    init(context: AppContext, meta: StatusImagePreviewMeta) {
        self.context = context
        self.initialItem = .status(meta)
        var viewControllers: [UIViewController] = []
        let managedObjectContext = self.context.managedObjectContext
        managedObjectContext.performAndWait {
            let status = managedObjectContext.object(with: meta.statusObjectID) as! Status
            guard let media = status.mediaAttachments?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }) else { return }
            for (entity, image) in zip(media, meta.preloadThumbnailImages) {
                let thumbnail: UIImage? = image.flatMap { $0.size != CGSize(width: 1, height: 1) ? $0 : nil }
                switch entity.type {
                case .image:
                    guard let url = URL(string: entity.url) else { continue }
                    let meta = MediaPreviewImageViewModel.StatusImagePreviewMeta(url: url, thumbnail: thumbnail)
                    let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
                    let mediaPreviewImageViewController = MediaPreviewImageViewController()
                    mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
                    viewControllers.append(mediaPreviewImageViewController)
                default:
                    continue
                }
            }
        }
        self.viewControllers = viewControllers
        super.init()
    }
    
}

extension MediaPreviewViewModel {
    
    enum PreviewItem {
        case status(StatusImagePreviewMeta)
        case local(LocalImagePreviewMeta)
    }
    
    struct StatusImagePreviewMeta {
        let statusObjectID: NSManagedObjectID
        let initialIndex: Int
        let preloadThumbnailImages: [UIImage?]
    }
    
    struct LocalImagePreviewMeta {
        let image: UIImage
    }
        
}

// MARK: - PageboyViewControllerDataSource
extension MediaPreviewViewModel: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        let viewController = viewControllers[index]
        if let mediaPreviewImageViewController = viewController as? MediaPreviewImageViewController {
            mediaPreviewImageViewController.delegate = mediaPreviewImageViewControllerDelegate
        }
        return viewController
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        guard case let .status(meta) = initialItem else { return nil }
        return .at(index: meta.initialIndex)
    }
    
}
