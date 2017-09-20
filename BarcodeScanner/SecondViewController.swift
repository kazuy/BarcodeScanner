//
//  SecondViewController.swift
//  BarcodeScanner
//
//  Created by kazuy on 2017/09/19.
//  Copyright © 2017年 kazuy. All rights reserved.
//

import UIKit
import AVFoundation

class SecondViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var label: UILabel!
    
    // バーコード検知エリア
    let detectionArea = UIView()
    // 定期実行するタスク
    var task: Timer!
    // バーコードを検知していない場合にカウントアップする
    var counter = 0
    // バーコードを検知したか？
    var isDetected = false

    override func viewDidLoad() {
        super.viewDidLoad()

        label.text = ""
        setUpCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // カメラのセットアップ
    // 参考：http://dev.classmethod.jp/smartphone/ios-avfoundation-avcapturemetadataoutput-ean13-ean8/
    private func setUpCamera() {
        let captureSession = AVCaptureSession()
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        // Input
        do {
            let captureInput: AVCaptureInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureInput)
        } catch let error as NSError {
            print(error)
        }
        
        // Output
        let captureOutput: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureOutput)
        captureOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureOutput.metadataObjectTypes = [AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code]
        
        // 検出エリアの設定
        captureOutput.rectOfInterest = createRectOfInterest()
        detectionArea.frame = createRectOfDetectionArea()
        detectionArea.layer.borderColor = UIColor.red.cgColor
        detectionArea.layer.borderWidth = 3
        view.addSubview(detectionArea)
        
        // プレビュー
        if let videoLayer = AVCaptureVideoPreviewLayer.init(session: captureSession) {
            videoLayer.frame = previewView.bounds
            videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            previewView.layer.addSublayer(videoLayer)
        }
        
        // セッションの開始
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        
        task = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        task.fire()
        
    }
    
    // バーコードを検知していない場合
    func update(tm: Timer) {
        counter += 1
        print(counter)
        if 1 < counter {
            detectionArea.layer.borderColor = UIColor.red.cgColor
            detectionArea.layer.borderWidth = 3
            label.text = ""
        }
    }
    
    // MARK: - Rectangle
    let x: CGFloat = 0.05
    let y: CGFloat = 0.3
    let width: CGFloat = 0.9
    let height: CGFloat = 0.2
    
    // 検出エリア(横向き指定となるためx,yが逆転する)
    private func createRectOfInterest() -> CGRect {
        return CGRect(x: y,y: 1-x-width,width: height,height: width)
    }
    
    // 検出エリアの枠
    private func createRectOfDetectionArea() -> CGRect {
        return CGRect(x: view.frame.size.width * x, y: view.frame.size.height * y, width: view.frame.size.width * width, height: view.frame.size.height * height)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}

// MARK: - ViewController拡張
extension SecondViewController: AVCaptureMetadataOutputObjectsDelegate {

    // captureOutput.metadataObjectTypesに指定したオブジェクトを検知した場合に呼び出されるデリゲートメソッド
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        // 複数のメタデータを検出できる
        for metadata in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            // EAN-13Qコードのデータかどうかの確認
            if metadata.type == AVMetadataObjectTypeEAN13Code || metadata.type == AVMetadataObjectTypeEAN8Code{
                if metadata.stringValue != nil {
                    // 検出データを取得
                    counter = 0
                    if !isDetected || label.text != metadata.stringValue! {
                        isDetected = true
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // バイブレーション
                        label.text = metadata.stringValue!
                        detectionArea.layer.borderColor = UIColor.white.cgColor
                        detectionArea.layer.borderWidth = 5
                    }
                }
            }
        }
    }
    
}
