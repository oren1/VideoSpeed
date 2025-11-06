//
//  CaptionsSectionVC.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 12/08/2025.
//

import UIKit
import SwiftUI

class CaptionsSectionVC: SectionViewController {
    
    var captionsSectionHostingController: UIHostingController<CaptionsSectionView>!
    var viewModel: CaptionsViewModel!
    var editStyleTapped: (() -> Void)?
    
    override func viewDidLoad() {
            super.viewDidLoad()
        captionsSectionHostingController = UIHostingController(rootView: CaptionsSectionView(viewModel: viewModel, editStyleTapped: editStyleTapped))

            addChild(captionsSectionHostingController)
            captionsSectionHostingController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(captionsSectionHostingController.view)

            NSLayoutConstraint.activate([
                captionsSectionHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                captionsSectionHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                captionsSectionHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                captionsSectionHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        captionsSectionHostingController.view.backgroundColor = .black
          captionsSectionHostingController.didMove(toParent: self)
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
