//
//  AllMediaViewController.swift
//  mastodon
//
//  Created by Shihab Mehboob on 24/04/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation
import UIKit
import PINRemoteImage
import AVKit
import AVFoundation

class AllMediaViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SKPhotoBrowserDelegate {
    
    var collectionView: UICollectionView!
    var profileStatusesHasImage: [Status] = []
    var chosenUser: Account!
    var player = AVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Colours.white
        
        self.fetchMoreImages()
        
        var tabHeight = Int(UITabBarController().tabBar.frame.size.height) + Int(34)
        var offset = 88
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2688:
                offset = 88
            case 2436:
                offset = 88
            default:
                offset = 64
                tabHeight = Int(UITabBarController().tabBar.frame.size.height)
            }
        }
        let wid = self.view.bounds.width
        let he = self.view.bounds.height
        
        let layout = ColumnFlowLayout(
            cellsPerRow: 3,
            minimumInteritemSpacing: 5,
            minimumLineSpacing: 5,
            sectionInset: UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        )
        self.collectionView = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(offset), width: CGFloat(wid), height: CGFloat(he) - CGFloat(offset) - CGFloat(tabHeight)), collectionViewLayout: layout)
        self.collectionView.backgroundColor = Colours.white
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(AllImagesCell.self, forCellWithReuseIdentifier: "AllImagesCell")
        self.view.addSubview(self.collectionView)
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.profileStatusesHasImage.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let x = 3
        let y = self.view.bounds.width
        let z = CGFloat(y)/CGFloat(x)
        return CGSize(width: z - 7.5, height: z - 7.5)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AllImagesCell", for: indexPath) as! AllImagesCell
        
        if indexPath.item == self.profileStatusesHasImage.count - 7 {
            self.fetchMoreImages()
        }
        
        if self.profileStatusesHasImage.isEmpty {} else {
            cell.configure()
            cell.image.image = nil
            cell.image.pin_updateWithProgress = true
            let z = self.profileStatusesHasImage[indexPath.item].mediaAttachments[0].previewURL
            let secureImageUrl = URL(string: z)!
            cell.image.pin_setImage(from: secureImageUrl)
            cell.image.contentMode = .scaleAspectFill
            cell.layer.cornerRadius = 12
            cell.image.layer.cornerRadius = 12
            cell.image.layer.masksToBounds = true
            
            if self.profileStatusesHasImage[indexPath.item].mediaAttachments[0].type == .video {
                cell.imageCountTag.setTitle("\u{25b6}", for: .normal)
                cell.imageCountTag.backgroundColor = Colours.tabSelected
                cell.imageCountTag.alpha = 1
            } else if self.profileStatusesHasImage[indexPath.item].mediaAttachments[0].type == .gifv {
                cell.imageCountTag.setTitle("GIF", for: .normal)
                cell.imageCountTag.backgroundColor = Colours.tabSelected
                cell.imageCountTag.alpha = 1
            } else if self.profileStatusesHasImage[indexPath.item].mediaAttachments.count > 1 { cell.imageCountTag.setTitle("\(self.profileStatusesHasImage[indexPath.item].mediaAttachments.count)", for: .normal)
                cell.imageCountTag.backgroundColor = Colours.tabSelected
                cell.imageCountTag.alpha = 1
            } else {
                cell.imageCountTag.alpha = 0
            }
        }
    
        cell.image.frame.size.width = cell.frame.size.width
        cell.image.frame.size.height = cell.frame.size.height
        cell.backgroundColor = Colours.clear
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (UserDefaults.standard.object(forKey: "hapticToggle") == nil) || (UserDefaults.standard.object(forKey: "hapticToggle") as! Int == 0) {
            let selection = UISelectionFeedbackGenerator()
            selection.selectionChanged()
        }
        
        var sto = self.profileStatusesHasImage
        StoreStruct.newIDtoGoTo = sto[indexPath.item].id
        StoreStruct.currentImageURL = sto[indexPath.item].reblog?.url ?? sto[indexPath.item].url
        
        if sto[indexPath.item].mediaAttachments[0].type == .video || sto[indexPath.item].mediaAttachments[0].type == .gifv {
            
            let videoURL = URL(string: sto[indexPath.item].reblog?.mediaAttachments[0].url ?? sto[indexPath.item].mediaAttachments[0].url)!
            if (UserDefaults.standard.object(forKey: "vidgif") == nil) || (UserDefaults.standard.object(forKey: "vidgif") as! Int == 0) {
                XPlayer.play(videoURL)
            } else {
                self.player = AVPlayer(url: videoURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = self.player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
            
        } else {
            
            if let cell = collectionView.cellForItem(at: indexPath) as? AllImagesCell {
                var images = [SKPhoto]()
                var coun = 0
                let _ = sto[indexPath.row].mediaAttachments.map({
                    if coun == 0 {
                        let photo = SKPhoto.photoWithImageURL($0.url, holder: cell.image.image ?? nil)
                        photo.shouldCachePhotoURLImage = true
                        if (UserDefaults.standard.object(forKey: "captionset") == nil) || (UserDefaults.standard.object(forKey: "captionset") as! Int == 0) {
                            photo.caption = sto[indexPath.row].reblog?.content.stripHTML() ?? sto[indexPath.row].content.stripHTML()
                        } else if UserDefaults.standard.object(forKey: "captionset") as! Int == 1 {
                            photo.caption = $0.description ?? ""
                        } else {
                            photo.caption = ""
                        }
                        images.append(photo)
                    } else {
                        let photo = SKPhoto.photoWithImageURL($0.url, holder: nil)
                        photo.shouldCachePhotoURLImage = true
                        if (UserDefaults.standard.object(forKey: "captionset") == nil) || (UserDefaults.standard.object(forKey: "captionset") as! Int == 0) {
                            photo.caption = sto[indexPath.row].reblog?.content.stripHTML() ?? sto[indexPath.row].content.stripHTML()
                        } else if UserDefaults.standard.object(forKey: "captionset") as! Int == 1 {
                            photo.caption = $0.description ?? ""
                        } else {
                            photo.caption = ""
                        }
                        images.append(photo)
                    }
                    coun += 1
                })
                let originImage = cell.image.image
                if originImage != nil {
                    let browser = SKPhotoBrowser(originImage: originImage ?? UIImage(), photos: images, animatedFromView: cell.image)
                    browser.displayToolbar = true
                    browser.displayAction = true
                    browser.delegate = self
                    browser.initializePageIndex(0)
                    present(browser, animated: true, completion: nil)
                }
            }
        }
    }
    
    func fetchMoreImages() {
        let request = Accounts.statuses(id: self.chosenUser.id, mediaOnly: true, pinnedOnly: nil, excludeReplies: true, excludeReblogs: true, range: .max(id: self.profileStatusesHasImage.last?.id ?? "", limit: 5000))
        StoreStruct.client.run(request) { (statuses) in
            if let stat = (statuses.value) {
                if stat.isEmpty {} else {
                    DispatchQueue.main.async {
                        self.profileStatusesHasImage = self.profileStatusesHasImage + stat
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
}