//
//  BCPhotoRecord.swift
//  BCPhotoRecord
//
//  Created by Bro.chao on 2018/11/28.
//  Copyright © 2018 王世超. All rights reserved.
//

import UIKit
import AVFoundation

public enum BCPhotoRecordOption {
    case all
    case photo
    case record
}

public typealias BCPhotoRecordCompletion = (UIImage?, URL?) -> Void

public class BCPhotoRecord: UIViewController, BCPhotoRecordControlDelegate, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {

    public var option = BCPhotoRecordOption.all
    public var completion: BCPhotoRecordCompletion?
    
    // 显示方法
    public class func show(option: BCPhotoRecordOption = .all, with viewController: UIViewController, completion: @escaping BCPhotoRecordCompletion) {
        let bundle = Bundle(for: BCPhotoRecord.self)
        let pr = UIStoryboard(name: "PhotoRecord", bundle: bundle).instantiateInitialViewController() as! BCPhotoRecord
        pr.option = option
        pr.completion = completion
        viewController.present(pr, animated: true, completion: nil)
    }
    
    // mov压缩并转mp4
    public class func videoTransformMOVtoMP4(url videoUrl: URL, completion: @escaping (Bool, URL) -> Void) {
        let asset = AVURLAsset(url: videoUrl, options: nil)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)
        exportSession?.shouldOptimizeForNetworkUse = true
        let newName = NSUUID().uuidString
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(newName).mp4")
        exportSession?.outputURL = url
        exportSession?.outputFileType = AVFileType.mp4
        exportSession?.shouldOptimizeForNetworkUse = true // 适合网络传输
        exportSession?.exportAsynchronously(completionHandler: {
            let status = exportSession!.status
            if status == AVAssetExportSession.Status.unknown ||
                status == AVAssetExportSession.Status.cancelled ||
                status == AVAssetExportSession.Status.waiting ||
                status == AVAssetExportSession.Status.exporting ||
                status == AVAssetExportSession.Status.failed{
                completion(false, url)
            } else {
                completion(true, url)
            }
        })
    }
    
    @IBOutlet public weak var authLabel: UILabel!
    @IBOutlet public weak var authColseButton: UIButton!
    
    // 预览图
    @IBOutlet public weak var previewView: UIView!
    @IBOutlet public weak var previewPhotoView: UIView!
    @IBOutlet public weak var previewPhotoImageView: UIImageView!
    @IBOutlet public weak var previewRecordView: UIView!
    
    // 控制图
    @IBOutlet public weak var controlView: BCPhotoRecordControl!
    
    public var confirmPhoto: UIImage?
    public var confirmRecordURL: URL?
    public var avPlayer: AVPlayer?
    public var avPlayerLayer: AVPlayerLayer?
    
    deinit {
        captureSession.stopRunning()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        avPlayer?.pause()
        avPlayer = nil
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        controlView.photoRecord = self
        controlView.delegate = self
        authBegin()
    }
    
    func authEnd() {
        previewView.isHidden = false
        controlView.isHidden = false
        initCapture()
    }
    
    // MARK: - 预览
    func previewPhoto(_ image: UIImage) {
        confirmPhoto = image
        previewPhotoView.isHidden = false
        previewPhotoImageView.image = image
        DispatchQueue.main.async {
            self.captureSession.stopRunning()
        }
    }
    
    func previewVideo(_ url: URL) {
        confirmRecordURL = url
        
        avPlayer = AVPlayer(url: url)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.frame = previewRecordView.bounds
        previewRecordView.layer.addSublayer(avPlayerLayer!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(avPlayerDidEndTime(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        DispatchQueue.main.async {
            self.captureSession.stopRunning()
            self.previewRecordView.isHidden = false
            self.avPlayer?.play()
        }
    }
    
    @objc func avPlayerDidEndTime(_ n: Notification) {
        avPlayer?.seek(to: CMTime(value: 0, timescale: 1))
        avPlayer?.play()
    }
    
    // MARK: - 拍摄控制
    public func shoot() {
        let output = captureImageOutput as! AVCapturePhotoOutput
        var setting: AVCapturePhotoSettings
        if #available(iOS 11.0, *) {
            setting = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            setting = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
        }
        output.capturePhoto(with: setting, delegate: self)
        // if ios.version < 10
//        let output = captureImageOutput as! AVCaptureStillImageOutput
//        let connection = output.connection(with: .video)
//        output.captureStillImageAsynchronously(from: connection!) { [unowned self] (buffer, error) in
//            if buffer != nil {
//                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!) {
//                    let image = UIImage(data: imageData)
//                    self.previewPhoto(image!)
//                }
//            }
//        }
    }
    
    func startRecording() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("cMovie.mov")
        captureVideoOutput.startRecording(to: url, recordingDelegate: self)
    }
    
    func stopRecording() {
        captureVideoOutput.stopRecording()
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }
    
    func back() {
        // 拍照还原
        confirmPhoto = nil
        
        // 拍摄还原
        confirmRecordURL = nil
        avPlayer?.pause()
        avPlayerLayer?.removeFromSuperlayer()
        avPlayerLayer = nil
        avPlayer = nil
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        self.previewRecordView.isHidden = true
        self.previewPhotoView.isHidden = true
        // 重新拍摄
        DispatchQueue.main.async {
            self.captureSession.startRunning()
        }
    }
    
    func change() {
        DispatchQueue.main.async {
            self.captureSession.stopRunning()
            let position = self.captureDeviceInput.device.position
            var device: AVCaptureDevice?
            let newPosition = position == .back ? AVCaptureDevice.Position.front:AVCaptureDevice.Position.back
            if#available(iOS 10.0, *) {
                let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: newPosition)
                device = session.devices.first
            } else {
                let devices = AVCaptureDevice.devices(for: .video)
                for dev in devices {
                    if newPosition == dev.position {
                        device = dev
                        break
                    }
                }
            }
            let deviceInput = try! AVCaptureDeviceInput(device: device!)
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(self.captureDeviceInput)
            self.captureSession.addInput(deviceInput)
            self.captureSession.commitConfiguration()
            self.captureDeviceInput = deviceInput
            self.captureSession.startRunning()
        }
    }
    
    func confirm() {
        completion?(confirmPhoto, confirmRecordURL)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - 加载拍摄
    /*会话*/
    fileprivate var captureSession: AVCaptureSession!
    /*输入*/
    fileprivate var captureDeviceInput: AVCaptureDeviceInput!
    /*图片输出*/
    fileprivate var captureImageOutput: AVCaptureOutput!
    /*预览*/
    fileprivate var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!
    /*视频输出*/
    fileprivate var captureVideoOutput: AVCaptureMovieFileOutput!
    
    func initCapture() {
        // 创建会话
        captureSession = AVCaptureSession()
        
        // 创建图像(图片、视频)输入设备
        let device = AVCaptureDevice.default(for: .video)
        captureDeviceInput = try! AVCaptureDeviceInput(device: device!)
        
        // 创建音频输入设备
        let audioDevice = AVCaptureDevice.default(for: .audio)
        let audioDeviceInput = try! AVCaptureDeviceInput(device: audioDevice!)
        
        // 创建图片输出
        if#available(iOS 10, *) {
            captureImageOutput = AVCapturePhotoOutput()
        } else {
            captureImageOutput = AVCaptureStillImageOutput()
        }
        
        // 创建视频输出
        captureVideoOutput = AVCaptureMovieFileOutput()
        
        // 连接图像输入
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }
        // 连接音频输入
        if captureSession.canAddInput(audioDeviceInput) {
            captureSession.addInput(audioDeviceInput)
        }
        
        // 连接图片输出
        if captureSession.canAddOutput(captureImageOutput) {
            captureSession.addOutput(captureImageOutput)
        }
        
        // 连接视频输出
        if captureSession.canAddOutput(captureVideoOutput) {
            captureSession.addOutput(captureVideoOutput)
        }
        
        // 设置预览层
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        captureVideoPreviewLayer.frame = previewView.bounds
        previewView.layer.insertSublayer(captureVideoPreviewLayer, at: 0)
        
        // 创建视频预览播放
//        avPlayer = AVPlayer(playerItem: nil)
//        let playLayer = AVPlayerLayer(player: avPlayer)
//        previewVideoView.layer.addSublayer(playLayer)
        
        DispatchQueue.main.async {
            self.captureSession.startRunning()
        }
    }
    
    // MARK: - 拍摄完成代理方法
    /*拍照*/
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            self.previewPhoto(UIImage(data: imageData)!)
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
            self.previewPhoto(UIImage(data: imageData)!)
        }
    }
    
    // MARK: - 录制视频
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        previewVideo(outputFileURL)
    }
    
    // MARK: - 隐私验证
    // 验证摄像头权限
    func authBegin() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            // 未选择，请求摄像头授权
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                DispatchQueue.main.async {
                    if status {
                        // 允许，验证麦克风权限
                        self.authAudio()
                    } else {
                        // 拒绝
                        self.showAuthResult("您已拒绝访问相机权限，如需使用请在设置->隐私->相机中打开访问权限")
                    }
                }
            }
            break
        case .restricted, .denied:
            self.showAuthResult("您已拒绝访问相机权限，如需使用请在设置->隐私->相机中打开访问权限")
            break
        case .authorized:
            authAudio()
            break
        }
    }
    // 验证麦克风权限
    func authAudio() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { (status) in
                DispatchQueue.main.async {
                    if status {
                        self.authEnd()
                    } else {
                        self.showAuthResult("您已拒绝访问麦克风权限，如需使用请在设置->隐私->麦克风中打开访问权限")
                    }
                }
            }
            break
        case .restricted, .denied:
            self.showAuthResult("您已拒绝访问麦克风权限，如需使用请在设置->隐私->麦克风中打开访问权限")
            break
        case .authorized:
            hideAuthResult()
            authEnd()
            break
        }
    }
    
    func showAuthResult(_ string: String) {
        authColseButton.isHidden = false
        authLabel.isHidden = false
        authLabel.text = string
    }
    
    func hideAuthResult() {
        authLabel.isHidden = true
        authColseButton.isHidden = true
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
