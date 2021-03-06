//
//  YahooLocal.swift
//  GourmetSearch2
//
//  Created by tkwatanabe on 2017/06/21.
//  Copyright © 2017年 tkwatanabe. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


public extension Notification.Name {
    //読み込み開始Notification
    public static let apiLoadStart = Notification.Name("ApiLoadStart")
    //読み込み完了Notification
    public static let apiLoadComplete = Notification.Name("ApiLoadComplete")
}

//APIから取得した店舗情報表現する
public struct Shop: CustomStringConvertible {
    
    public var gid: String? = nil
    public var name: String? = nil
    public var photoUrl: String? = nil
    public var yomi: String? = nil
    public var tel: String? = nil
    public var address: String? = nil
    public var lat: Double? = nil
    public var lon: Double? = nil
    public var catchCopy: String? = nil
    public var hasCoupon = false
    public var station: String? = nil
    
    //MARK: - CustomStringConvertible
    //CustomStringCOnvertibleプロトコルはdescriptionメソッドの返り値を表示する。print()で利用
    public var description: String {
        get {
            var string = "\nGid: \(gid)\n"
            string += "Name: \(name)\n"
            string += "PhotoUrl: \(photoUrl)\n"
            string += "Yomi: \(yomi)\n"
            string += "Tel: \(tel)\n"
            string += "Address: \(address)\n"
            string += "Lat & Lon: (\(lat), \(lon))\n"
            string += "CatchCopy: \(catchCopy)\n"
            string += "hasCoupon: \(hasCoupon)\n"
            string += "Station: \(station)\n"
            return string
        }
    }
}

//検索条件を表現する
public struct QueryCondition {
    
    //キーワード
    public var query: String? = nil
    //店舗ID
    public var gid: String? = nil
    //ソート順
    public enum Sort: String {
        case score = "score"
        case geo = "geo"
    }
    public var sort: Sort = .score
    //緯度
    public var lat: Double? = nil
    //経度
    public var lon: Double? = nil
    //距離
    public var dist: Double? = nil
    
    //検索パラメータディクショナリ
    public var queryParams: [String: String] {
        get {
            var params = Dictionary<String, String>() //[String: String]()
            //キーワード
            if let unwrapped = query {
                params["query"] = unwrapped
            }
            //店舗ID
            if let unwrapped = gid {
                params["gid"] = unwrapped
            }
            //ソート順
            switch sort {
            case .score: params["sort"] = "score"
            case .geo: params["sort"] = "geo"
            }
            //緯度
            if let unwrapped = lat {
                params["lat"] = "\(unwrapped)"
            }
            //経度
            if let unwrapped = lon {
                params["lon"] = "\(unwrapped)"
            }
            //距離
            if let unwrapped = dist {
                params["dist"] = "\(unwrapped)"
            }
            //固定の項目
            //デバイス: mobile
            params["device"] = "mobile"
            //グルーピング: gid
            params["group"] = "gid"
            //画像があるデータのみ検索する: true
            params["image"] = "true"
            //業種コード: 01(グルメ)固定
            params["gc"] = "01"
            
            return params
        }
    }
}

public class YahooLocalSearch {
    //Yahoo!ローカルサーチAPIのアプリケーションID
    let apiId = "dj0zaiZpPWVrYmdaYVFpbURhQSZzPWNvbnN1bWVyc2VjcmV0Jng9ZTQ-"
    //APIのベースURL
    let apiUrl = "http://search.olp.yahooapis.jp/OpenLocalPlatform/V1/localSearch"
    //1ページのレコード数
    let perPage = 10
    //読み込み済みの店舗
    public var shops = [Shop]()
    //trueだと読込中
    var loading = false
    //全何件か
    public var total = 0
    //検索条件
    var condition: QueryCondition = QueryCondition() {
        //新しい値がセットされた後に読み込み済みの店舗を捨てる
        didSet {
            shops = []
            total = 0
        }
    }
    
    //パラメータ無しのイニシャライザ
    public init() {}
    
    //検索条件をパラメータとして持つイニシャライザ
    public init(condition: QueryCondition) { self.condition = condition }
    
    //APIからデータを読み込む
    //reset = trueならデータを捨てて最初から読み込む
    public func loadData(reset: Bool = false) {
        
        //読み込み中の場合は処理を行わない
        if loading {
            return
        }
        
        if reset {
            shops = []
            total = 0
        }
        
        //API実行中フラグをON
        loading = true
        
        //条件ディクショナリを取得 イニシャライザで設定される
        var params: Dictionary<String, String> = condition.queryParams
        //検索条件以外のAPIパラメタを取得
        params["appid"] = apiId
        params["output"] = "json"
        params["start"] = String(shops.count + 1)
        params["results"] = String(perPage)
        
        //API実行開始を通知
        NotificationCenter.default.post(name: .apiLoadStart, object: nil)
        
        //APIリクスト実行
        Alamofire.request(apiUrl, parameters: params).response {
            //リクエストが完了した時に実行されるクロージャ
            (response) -> Void in
            
            var json = JSON.null
            //エラーがあれば終了
            if response.error != nil {
                //API実行中フラグをOFF
                self.loading = false
                //API実行を終了する
                var message = "UnKnown error."
                if let error = response.error {
                    message = "\(error)"
                }
                NotificationCenter.default.post(
                    name: .apiLoadComplete, object: nil, userInfo: ["error": message])
                return
            }
            
            if response.data == nil {
                return
            }
            //レスポンスからJSONデータを取得
            json = SwiftyJSON.JSON(data: response.data!)
            //店舗データをself.shopsに追加していく
            for(_, item) in json["Feature"] {
                var shop = Shop()
                //店舗ID
                shop.gid = item["Gid"].string
                //店舗名(「'」が「&#39;」という形でエンコードされているのでデコードする)
                shop.name = item["Name"].string?.replacingOccurrences(of: "&#39;", with: "'")
                //読み
                shop.yomi = item["Property"]["Yomi"].string
                //電話
                shop.tel = item["Property"]["Tel1"].string
                //住所
                shop.address = item["Property"]["Address"].string
                //緯度＆経度
                if let geometry = item["Geometory"]["Coordinates"].string {
                    let components = geometry.components(separatedBy: ",")
                    //緯度
                    shop.lat = (components[1] as NSString).doubleValue
                    //経度
                    shop.lon = (components[0] as NSString).doubleValue
                }
                //キャッチコピー
                shop.catchCopy = item["Property"]["CatchCopy"].string
                //店舗写真
                shop.photoUrl = item["Property"]["LeadImage"].string
                //クーポンの有無
                if item["Property"]["CouponFlag"].string == "true" {
                    shop.hasCoupon = true
                }
                //駅
                if let stations = item["Property"]["Station"].array {
                    var line = ""
                    if let lineString = stations[0]["Railway"].string {
                        let lines = lineString.components(separatedBy: "/")
                        line = lines[0]
                    }
                    if let station = stations[0]["Name"].string {
                        shop.station = "\(line) \(station)"
                    } else {
                        //駅名がない場合路線名のみ入れる
                        shop.station = "\(line)"
                    }
                }
                print(shop)
                self.shops.append(shop)
            }
            // 総件数を反映
            if let total = json["ResultInfo"]["Total"].int {
                self.total = total
            } else {
                self.total = 0
            }
            //API実行中フラグをOFF
            self.loading = false
            //API実行終了を通知
            NotificationCenter.default.post(name: .apiLoadComplete, object: nil)
        }
    }
}
