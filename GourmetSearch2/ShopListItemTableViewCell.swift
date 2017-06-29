//
//  ShopListItemTableViewCell.swift
//  GourmetSearch2
//
//  Created by tkwatanabe on 2017/06/20.
//  Copyright © 2017年 tkwatanabe. All rights reserved.
//

import UIKit

class ShopListItemTableViewCell: UITableViewCell {

    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var iconContainer: UIView!
    @IBOutlet weak var coupon: UILabel!
    @IBOutlet weak var station: UILabel!
    
    @IBOutlet weak var nameHeight: NSLayoutConstraint!
    @IBOutlet weak var stationWidth: NSLayoutConstraint!
    @IBOutlet weak var stationX: NSLayoutConstraint!
    
    var shop = Shop() {
        didSet {
            //URLがあれば画像を表示する
            if let url = shop.photoUrl {
                //セルが再利用される場合のための読み込みキャンセル
                photo.sd_cancelCurrentAnimationImagesLoad()
                //文字列に指定したURLから画像をphotoに設定するコード
                //「画像の取得」「UIImageViewへの画像の設定」を非同期で実行
                photo.sd_setImage(with: URL(string: url),
                                  placeholderImage: UIImage(named: "loading"),
                                  options: .retryFailed)
            }
            //店舗名をラベルに設定
            name.text = shop.name
            //クーポン表示
            var x: CGFloat = 0
            let margin: CGFloat = 10
            if shop.hasCoupon {
                coupon.isHidden = false
                x += coupon.frame.size.width + margin
                //ラベルを丸くする
                coupon.layer.cornerRadius = 4
                coupon.clipsToBounds = true
            } else {
                coupon.isHidden = true
            }
            //駅表示
            if shop.station != nil {
                station.isHidden = false
                station.text = shop.station
                //ラベルの位置を設定する
                stationX.constant = x
                //ラベルの幅を計算する
                let size = station.sizeThatFits(
                    CGSize(
                        width: CGFloat.greatestFiniteMagnitude,
                        height: CGFloat.greatestFiniteMagnitude
                    )
                )
                if x + size.width + margin > iconContainer.frame.width {
                    //ラベルの幅が右端を超える場合、最大サイズを設定する
                    stationWidth.constant = iconContainer.frame.width - x
                } else {
                    stationWidth.constant = size.width + margin
                }
                //ラベルを角丸にする
                station.layer.cornerRadius = 4
                station.clipsToBounds = true
            } else {
                station.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //AutoLayoutによって配置された後に実行されるメソッド
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //行数を最大2行に限定してラベルの高さを計算する
        let maxFrame = CGRect(
            x: 0,
            y: 0,
            width: name.frame.size.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        let actualFrame = name.textRect(forBounds: maxFrame,
                                        limitedToNumberOfLines: 2)
        //計算したサイズを設定
        nameHeight.constant = actualFrame.size.height
    }

}
