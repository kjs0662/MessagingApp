//
//  JSInitialViewController.swift
//  MessagingApp
//
//  Created by Jinseon Kim on 2020/10/29.
//

import UIKit

class JSInitialViewController: UIViewController {
    
    var chatVC: JSChatViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Initial VC"
    }

    @IBAction func callee(_ sender: Any) {
        presentChatVC(isCaller: false)
    }
    
    @IBAction func caller(_ sender: Any) {
        presentChatVC(isCaller: true)
    }
    
    private func presentChatVC(isCaller: Bool) {
        let vc = storyboard?.instantiateViewController(identifier: "JSChatViewController") as! JSChatViewController
        vc.isCaller = isCaller
        navigationController?.pushViewController(vc, animated: true)
    }
}
