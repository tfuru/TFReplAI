//
//  ReplAi.swift
//  carekoma
//
//  Created by 古川信行 on 2016/05/05.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import Foundation
import Alamofire

//エラー
public enum TFReplAIError: ErrorType {
    case APP_USER_ID_NOT_SET
}

public class TFReplAI {
    // ReplAiSettings.plist を読み込んで保持する
    private var settings:NSDictionary?
    
    //ユーザID取得
    private static let API_URL_BASE:String = "https://api.repl-ai.jp/v1"
    
    //ユーザID取得
    private static let API_URL_REGISTRATION:String = "/registration"
    
    //対話
    private static let API_URL_DIALOGUE:String = "/dialogue"
    
    //ユーザーID
    private var appUserId:String?
    
    //最後にレスポンスを受信した時刻
    private var appRecvTime:String?
    
    //シナリオID
    private var initTopicId:String = ""
    
    //コンストラクタ
    public init(settingsFileName:String){
        self.settings = loadPlist(settingsFileName)
    }
    
    /** 設定ファイルを読み込んで NSDictionaryを生成して返す
     *
     */
    private func loadPlist(fileName:String!) -> NSDictionary {
        var result:NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource(fileName,ofType:"plist") {
            result = NSDictionary(contentsOfFile: path)!
        }
        return result!
    }
    
    //日付フォーマット指定して文字列を取得する
    private func dateToFormatString(format:String,date:NSDate,locale:String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: locale)
        dateFormatter.dateFormat = format
        return dateFormatter.stringFromDate(date)
    }
    
    //記録済みのユーザーIDを収得する
    public func setAppUserId(appUserId:String) {
        self.appUserId = appUserId
    }
    
    /** ユーザーID取得
     - parameter callback: 結果を受け取るコールバック
    */
    public func registration(callback:(String) -> Void){
        //記録済みの ユーザーID があるか確認する
        if let uid = self.appUserId {
            //会った場合、以下の処理をせず、すぐにコールバックする
            callback(uid)
            return
        }
        
        let url:String = "\(TFReplAI.API_URL_BASE)\(TFReplAI.API_URL_REGISTRATION)"
        let headers = [
            "Content-Type": "application/json",
            "x-api-key":self.settings?.objectForKey("apiKey") as! String
        ]
        let params:[String: AnyObject] = ["botId": self.settings?.objectForKey("botId") as! String]

        Alamofire.request(.POST, url, headers: headers, parameters:params, encoding: .JSON)
            .responseJSON { response in
                if let json = response.result.value as? NSDictionary {
                    //print("json: \(json)")
                    
                    //ユーザーIDを永続化する
                    self.appUserId = json.objectForKey("appUserId") as? String
                    //print("appUserId: \(self.appUserId)")
                }
                //コールバックする
                callback(self.appUserId!)
        }
    }
    
    /** 対話
     - parameter voiceText: 発話
     - parameter initTalkingFlag: 初回発話か否かを識別するフラグ
     - parameter initTopicId: シナリオIDを指定
     - parameter callback: 結果を受け取るコールバック
     */
    public func dialogue(voiceText:String,initTalkingFlag:Bool,initTopicId:String,callback:(NSDictionary,topicId:String) -> Void) throws {
        // appUserId が未定義の場合はエラーを通知
        if appUserId == nil {
            throw TFReplAIError.APP_USER_ID_NOT_SET
        }
        
        let url:String = "\(TFReplAI.API_URL_BASE)\(TFReplAI.API_URL_DIALOGUE)"
        let headers = [
            "Content-Type": "application/json",
            "x-api-key":self.settings?.objectForKey("apiKey") as! String
        ]
        
        var initTalkingFlagStr:String = "false"
        var voiceTextStr = voiceText
        var initTopicIdStr = initTopicId
        if initTalkingFlag {
            //はじめまして
            voiceTextStr = "init"
            initTalkingFlagStr = "true"
            initTopicIdStr = (self.settings?.objectForKey("initTopicId") as? String)!
        }
        //print("initTalkingFlagStr:\(initTalkingFlagStr)")
        
        //最後にレスポンスを受信した時刻
        if appRecvTime == nil {
            //未定義の場合 現在時刻を設定
            appRecvTime = dateToFormatString("yyyy/MM/dd HH:mm:ss", date: NSDate(), locale: "ja_JP")
        }
        
        //リクエストを送信した時刻
        let appSendTime = dateToFormatString("yyyy/MM/dd HH:mm:ss", date: NSDate(), locale: "ja_JP")
        
        let params:[String: AnyObject] = ["appUserId": self.appUserId!,
                                          "botId":(self.settings?.objectForKey("botId") as? String)!,
                                          "voiceText":voiceTextStr,
                                          "initTalkingFlag":initTalkingFlagStr,
                                          "initTopicId":initTopicIdStr,
                                          "appRecvTime":appRecvTime!,
                                          "appSendTime":appSendTime]
        
        Alamofire.request(.POST, url, headers: headers, parameters:params, encoding: .JSON)
            .responseJSON { response in
                if let json = response.result.value as? NSDictionary {
                    //サーバがレスポンスを送信した時刻
                    let serverSendTime = (json.objectForKey("serverSendTime") as? String)!

                    //最後にレスポンスを受信した時刻を更新
                    self.appRecvTime = self.dateToFormatString("yyyy/MM/dd HH:mm:ss", date: NSDate(), locale: "ja_JP")
                    
                    callback(json,topicId:initTopicIdStr)
                }
                
        }
    }
    
}