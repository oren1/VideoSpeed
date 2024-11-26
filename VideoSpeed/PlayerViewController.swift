//
//  PlayerViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 24/11/2024.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    var minVerticalMargin = 20.0
    var minHorizontalMargin = 20.0
    var videoAspectRatio: CGFloat = 736 / 1407
    var playerItem: AVPlayerItem!
    var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)

        player.play()
        // Do any additional setup after loading the view.
    }

    func updatePlayerItem(playerItem: AVPlayerItem) async {
        playerLayer.removeFromSuperlayer()
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        player.play()
    }
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews")
        playerLayer.frame = view.bounds
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
