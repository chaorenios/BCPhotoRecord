//
//  BCPhotoRecordControl.swift
//  BCPhotoRecord
//
//  Created by Bro.chao on 2018/11/28.
//  Copyright © 2018 王世超. All rights reserved.
//

import UIKit

@objc protocol BCPhotoRecordControlDelegate {
    func shoot()
    func startRecording()
    func stopRecording()
    func close()
    func back()
    func change()
    func confirm()
}

public class BCPhotoRecordControl: UIView, BCPhotoRecordButtonDelegate {
    
    weak var photoRecord: BCPhotoRecord? {
        didSet {
            prButton.photoRecord = photoRecord
            if let pr = photoRecord {
                switch pr.option {
                case .all:
                    messageLabel.text = "轻触拍照，长按拍摄"
                case .photo:
                    messageLabel.text = "轻触拍照"
                case .record:
                    messageLabel.text = "长按拍摄"
                }
            }
        }
    }
    
    @IBOutlet weak var prButton: BCPhotoRecordButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    weak var delegate: BCPhotoRecordControlDelegate?
    var isWillConfirm = false {
        didSet {
            let scale = Int(UIScreen.main.scale)
            var leftImageName = String(format: "close@%dx.png", scale)
            var rightImageName = String(format: "change@%dx.png", scale)
            messageLabel.isHidden = false
            prButton.isHidden = false
            if isWillConfirm {
                prButton.isHidden = true
                messageLabel.isHidden = true
                leftImageName = String(format: "back@%dx.png", scale)
                rightImageName = String(format: "confirm@%dx.png", scale)
            }
            let leftPath = Bundle.main.path(forResource: leftImageName, ofType: nil)
            let rightPath = Bundle.main.path(forResource: rightImageName, ofType: nil)
            backButton.setImage(UIImage(contentsOfFile: leftPath!), for: .normal)
            confirmButton.setImage(UIImage(contentsOfFile: rightPath!), for: .normal)
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        prButton.delegate = self
        isWillConfirm = false
    }
    
    func tap() {
        delegate?.shoot()
        isWillConfirm = true
    }
    
    func startLongPress() {
        delegate?.startRecording()
        messageLabel.isHidden = true
    }
    
    func stopLongPress() {
        delegate?.stopRecording()
        isWillConfirm = true
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        if isWillConfirm {
            delegate?.back()
            isWillConfirm = false
        } else {
            delegate?.close()
        }
    }
    
    @IBAction func confirmAction(_ sender: UIButton) {
        if isWillConfirm {
            delegate?.confirm()
        } else {
            delegate?.change()
        }
    }
}

protocol BCPhotoRecordButtonDelegate {
    func tap()
    func startLongPress()
    func stopLongPress()
}

public class BCPhotoRecordButton: UIView {
    
    weak var photoRecord: BCPhotoRecord?
    
    var delegate: BCPhotoRecordButtonDelegate?
    
    var outerView = UIView(frame: CGRect.zero)
    var centerView = UIView(frame: CGRect.zero)
    var progressLayer = CAShapeLayer()
    public var progressLayerColor = UIColor(red: 0, green: 220.0/255.0, blue: 0, alpha: 1)
    public var progressLayerWidth: CGFloat = 5
    public var progressLayerDuration: CGFloat = 10 // 最大秒数
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        initUI()
    }
    
    func initUI() {
        self.backgroundColor = UIColor.clear
        
        outerView.frame = bounds
        outerView.backgroundColor = UIColor(white: 0.9, alpha: 0.9)
        outerView.layer.cornerRadius = outerView.bounds.size.width / 2
        outerView.alpha = 0.7
        self.addSubview(outerView)
        
        centerView = UIView(frame: CGRect(x: 0, y: 0, width: outerView.bounds.size.width - 20, height: outerView.bounds.size.width - 20))
        centerView.backgroundColor = UIColor.white
        centerView.layer.cornerRadius = centerView.bounds.size.width / 2
        centerView.center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        self.addSubview(centerView)
        
        outerView.layer.addSublayer(progressLayer)
        progressLayer.fillColor = nil
        progressLayer.lineCap = CAShapeLayerLineCap.square
        progressLayer.frame = outerView.bounds
        progressLayer.lineWidth = progressLayerWidth
        progressLayer.strokeColor = progressLayerColor.cgColor
        
        // press
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
        let tapPress = UITapGestureRecognizer(target: self, action: #selector(tapPressAction(_:)))
        centerView.addGestureRecognizer(longPress)
        centerView.addGestureRecognizer(tapPress)
    }
    
    @objc func longPressAction(_ press: UILongPressGestureRecognizer) {
        guard let pr = photoRecord else {
            return
        }
        if pr.option != .photo {
            switch press.state {
            case .possible: break
            case .began:
                UIView.animate(withDuration: 0.3) {
                    self.centerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }
                startProgress()
                self.delegate?.startLongPress()
            case .changed: break
            case .ended:
                stopProgress()
                self.delegate?.stopLongPress()
            case .cancelled:
                stopProgress()
                self.delegate?.stopLongPress()
            case .failed: break
            }
        }
    }
    
    @objc func tapPressAction(_ press: UITapGestureRecognizer) {
        guard let pr = photoRecord else {
            return
        }
        if pr.option != .record {
            delegate?.tap()
        }
    }
    
    var timer: Timer?
    func startProgress()  {
        let time = 1 / (progressLayerDuration * progressLayerDuration)
        let inlc = 1 / (progressLayerDuration * progressLayerDuration * progressLayerDuration)
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(time), repeats: true, block: { [unowned self] (t) in
            self.progress = self.progress + inlc
            if self.progress > 1 {
                self.stopProgress()
                self.delegate?.stopLongPress()
            }
            self.updateProgress()
        })
    }
    
    func stopProgress() {
        timer?.invalidate()
        timer = nil
        resetProgress()
    }
    
    var progress: CGFloat = 0
    
    func resetProgress() {
        UIView.animate(withDuration: 0.3) {
            self.centerView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        progress = 0
        let radius: CGFloat = (outerView.frame.width - progressLayerWidth * 2) / 2
        let startAngle: CGFloat = CGFloat(Double.pi/2) * 3
        let endAngle: CGFloat = -CGFloat(Double.pi/2)
        let path = UIBezierPath(arcCenter: outerView.center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        progressLayer.path = path.cgPath
    }
    
    func updateProgress() {
        let radius = (outerView.frame.width - progressLayerWidth * 2) / 2
        let startAngle: CGFloat = CGFloat(Double.pi / 2) * 3
        let endAngle: CGFloat = CGFloat(Double.pi) * 2 * progress - CGFloat(Double.pi/2)
        let path = UIBezierPath(arcCenter: outerView.center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        progressLayer.path = path.cgPath
    }
}
