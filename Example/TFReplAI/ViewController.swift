//
//  ViewController.swift
//  TFReplAI
//
//  Created by tfuru on 05/30/2016.
//  Copyright (c) 2016 tfuru. All rights reserved.
//

import UIKit
import TFReplAI

class ViewController: UIViewController {

    //TFReplAIを定義
    let replAI:TFReplAI = TFReplAI(settingsFileName: "SampleSettings")
    
    //ユーザーID
    var appUserId:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //ユーザID取得のテスト
    @IBAction func btnRegistrationClick(sender: AnyObject) {
        //ユーザID取得
        self.replAI.registration { (appUserId) in
            //必要ならココで appUserId を永続化
            self.appUserId = appUserId
            print("appUserId:\(self.appUserId!)")
        }
    }
    
    //対話のテスト 初回発話
    @IBAction func btnDialogueInitClick(sender: AnyObject) {
        //発話テキスト
        let txt:String = "こんにちは"
        //初回発話か否かを識別するフラグ
        let initTalkingFlag:Bool = false
        //シナリオIDを指定
        let initTopicId:String = "K3bhuUjd"
        
        dialogue(txt,initTalkingFlag:initTalkingFlag,initTopicId:initTopicId)
    }
    
    //対話のテスト 次の会話
    @IBAction func btnDialogueClick(sender: AnyObject) {
        //発話テキスト
        let txt:String = "名前は太郎だよ"
        //初回発話か否かを識別するフラグ
        let initTalkingFlag:Bool = false
        //シナリオIDを指定
        let initTopicId:String = "K3bhuUjd"
        
        dialogue(txt,initTalkingFlag:initTalkingFlag,initTopicId:initTopicId)
    }
    
    //対話
    func dialogue(txt:String,initTalkingFlag:Bool,initTopicId:String){
        do {
            if appUserId == nil {
                //ユーザーID 未定義
                print("ユーザーID 未定義")
                return
            }
            
            //ユーザーIDを設定
            self.replAI.setAppUserId(self.appUserId!)

            //対話
            print("txt:\(txt)")
            try self.replAI.dialogue(txt, initTalkingFlag: initTalkingFlag,initTopicId:initTopicId) { (response, topicId) in
                //systemText
                // expression: システムからのレスポンス
                // utterance : 音声合成用テキスト
                if let resp:NSDictionary = response {
                    let systemText:NSDictionary? = resp.objectForKey("systemText") as? NSDictionary
                    if let systemText:NSDictionary = systemText {
                        let expression = systemText.objectForKey("expression")
                        let utterance  = systemText.objectForKey("utterance")
                        print("expression:\(expression!)")
                        print("utterance:\(utterance!)")
                    }
                }
            }
        }
        catch TFReplAIError.APP_USER_ID_NOT_SET {
            //ユーザーID未設定
            print("APP_USER_ID_NOT_SET Error")
        }
        catch{
            print("Unknown Error")
        }
    }
}

