//
//  ShopDetailViewController.swift
//  GourmetSearch2
//
//  Created by tkwatanabe on 2017/06/27.
//  Copyright © 2017年 tkwatanabe. All rights reserved.
//

import UIKit
import MapKit

class ShopDetailViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var tel: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var favoriteIcon: UIImageView!
    @IBOutlet weak var favoriteLabel: UILabel!
    
    @IBOutlet weak var nameHeight: NSLayoutConstraint!
    @IBOutlet weak var addressContainerHeight: NSLayoutConstraint!
    
    var shop = Shop()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 写真
        if let url = shop.photoUrl {
            photo.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "loading"))
        } else {
            photo.image = UIImage(named: "loading")
        }
        
        //店舗名
        name.text = shop.name
        //電話番号
        tel.text = shop.tel
        //住所
        address.text = shop.address
        
        updateFavoriteButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.scrollView.delegate = self
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.scrollView.delegate = nil
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //AutoLayoutの制約に従ってビューが配置された後に実行されるメソッド
    override func viewDidLayoutSubviews() {
        
        //[sizeThatFits]パラメータで与えられたサイズから中のコンテンツに応じたサイズを計算して返す
        //[greatestFiniteMagnitude]横幅を取得したい場合の例。高さを取得したい場合はwidthに設定する
        let nameFrame: CGSize = name.sizeThatFits(
            CGSize(width: name.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
        )
        nameHeight.constant = nameFrame
        
        let addressFrame = address.sizeThatFits(
            CGSize(width: address.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
        )
        addressContainerHeight.constant = addressFrame
    }
    
    //MARK: - アプリケーションロジック
    func updateFavoriteButton() {
        guard let gid = shop.gid else {
            return
        }
        
        if Favorite.inFavorites(gid) {
            //お気にりに入っている
            favoriteIcon.image = UIImage(named: "star-on")
            favoriteLabel.text = "お気に入りからはずす"
        } else {
            //お気に入りに入っていない
            favoriteIcon.image = UIImage(named: "star-off")
            favoriteLabel.text = "お気に入りに入れる"
        }
    }

    //MARK: - IBAction
    @IBAction func telTapped(_ sender: UIButton) {
        print("telTapped")
    }
    
    @IBAction func addressTapped(_ sender: UIButton) {
        print("addressTapped")
    }
    
    @IBAction func favoriteTapped(_ sender: UIButton) {
        guard let gid = shop.gid else {
            return
        }
        //お気に入りセル: お気に入り状態に変更する
        Favorite.toggle(gid)
        updateFavoriteButton()
    }
    
}

extension ShopDetailViewController: UIScrollViewDelegate {
    
    //スクロールした時に実行されるメソッド
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //初期位置からどの方向にどれくらいスクロールしたかを計算
        //contentOffset.y scrollViewの左上を(0,0)とした場合のスクロール位置
        //contentInset ステータスバー、ナビゲーションバーなどの余白を計算した値
        let scrollOffset = scrollView.contentOffset.y + scrollView.contentInset.top
        if scrollOffset <= 0 {
            photo.frame.origin.y = scrollOffset
            photo.frame.size.height = 200 - scrollOffset
        }
    }
}
