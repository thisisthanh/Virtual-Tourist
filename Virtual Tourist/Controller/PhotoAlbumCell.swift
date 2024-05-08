//
//  PhotoAlbumCell.swift
//  Virtual Tourist
//
//  Created by Thành Nguyễn on 8/5/24.
//

import UIKit
import Kingfisher

class PhotoAlbumCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        photoImageView.kf.indicatorType = .activity
    }
}
