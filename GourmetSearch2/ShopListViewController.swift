//
//  ViewController.swift
//  GourmetSearch2
//
//  Created by tkwatanabe on 2017/06/20.
//  Copyright © 2017年 tkwatanabe. All rights reserved.
//

import UIKit

class ShopListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var yls = YahooLocalSearch()
    //Notificationの待ち受けを解除するためには待ち受け設定時に返されるオブジェクトが必要のため宣言
    var loadDataObserver: NSObjectProtocol?
    var refreshObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Pull to Refreshコントロール初期化
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.onRefresh(_:)), for: .valueChanged)
        self.tableView.addSubview(refreshControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //読み込み完了通知を受信した時の処理
        loadDataObserver = NotificationCenter.default.addObserver(
            forName: .apiLoadComplete,
            object: nil,
            queue: nil,
            using: { (notification) in
                print("APIリクエスト完了")
                self.tableView.reloadData()
                //エラーがあればダイアログを開く
                if notification.userInfo != nil {
                    if let userInfo = notification.userInfo as? [String: String?] {
                        if userInfo["error"] != nil {
                            let alert = UIAlertController(
                                title: "通信エラー",
                                message: "通信エラーが発生しました",
                                preferredStyle: .alert)
                            alert.addAction(
                                UIAlertAction(
                                    title: "OK",
                                    style: .default) { (action) -> Void in
                                        return
                                }
                            )
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        )
        
        //詳細画面から戻ってきた際にデータの再取得は行われない
        if yls.shops.count == 0 {
            if self.navigationController is FavoriteNavigationController {
                //お気に入りから検索条件を作って検索
                //ナビゲーションバータイトル設定
                self.navigationItem.title = "お気に入り"
            } else {
                //検索条件から検索
                //API実行
                yls.loadData(reset: true)
                //ナビゲーションバータイトル設定
                self.navigationItem.title = "店舗一覧"
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //待ち受けを終了する
        NotificationCenter.default.removeObserver(loadDataObserver!)
    }
    
    //MARK: - アプリケーションロジック
    func loadFavorites() {
        //お気にりをUserDefaultsから読み込む
        Favorite.load()
        //お気に入りがあれば店舗ID(Gid)一覧を作成して検索を実行する
        if Favorite.favorites.count > 0 {
            //お気に入り一覧を表現する検索条件オブジェクト
            var condition = QueryCondition()
            //favoritesプロパティの配列の中身を「,」で結合して文字列にする
            condition.gid = Favorite.favorites.joined(separator: ",")
            //検索条件を設定して検索実行
            yls.condition = condition
            yls.loadData(reset: true)
        } else {
            //お気に入りがなければ検索を実行せずAPI読み込み完了通知
            NotificationCenter.default.post(name: .apiLoadComplete, object: nil)
        }
    }
    
    
    //pull to refresh
    func onRefresh(_ refreshControl: UIRefreshControl) {
        //UIRefreshControlを読み込み状態にする
        refreshControl.beginRefreshing()
        //終了通知を受信したらUIRefreshControlを停止する
        refreshObserver = NotificationCenter.default.addObserver(forName: .apiLoadComplete, object: nil, queue: nil, using: {
            notification in
            //通知の待ち受けを終了
            NotificationCenter.default.removeObserver(self.refreshObserver!)
            //UIRefreshControlを停止する
            refreshControl.endRefreshing()
        })
        //再取得
        yls.loadData(reset: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PushShopDetail" {
            let vc = segue.destination as! ShopDetailViewController
            if let indexPath = sender as? IndexPath {
                vc.shop = yls.shops[indexPath.row]
            }
        }
    }
}

//MARK: - UITableViewDelefate
extension ShopListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //セルの選択状態を解除する(自動ではタップ状態は解除されないため)
        tabelView.deselectRow(at: indexPath, animated: true)
        //Segueを実行する
        performSegue(withIdentifier: "PushShopDetail", sender: indexPath)
    }

}

//MARK: - UITableViewDataSource
extension ShopListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //セルの数は店舗数
        if section == 0 {
            return yls.shops.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row < yls.shops.count {
                //指定セルが店舗数以下なら店舗セルを返す
                let cell = tableView.dequeueReusableCell(withIdentifier: "ShopListItem") as! ShopListItemTableViewCell
                cell.shop = yls.shops[indexPath.row]
                
                //まだ残りがあって、現在の列の下の店舗が3つ以下になったら追加取得
                if yls.shops.count < yls.total { //取得した店舗情報数 < 検索結果の店舗数
                    if yls.shops.count - indexPath.row <= 4 {
                        yls.loadData()
                    }
                }
                
                return cell
            }
        }
        return UITableViewCell()
    }
}
