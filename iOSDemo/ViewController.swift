//
//  ViewController.swift
//  iOSDemo
//
//  Created by Peng on 2021/7/14.
//

import UIKit
import RxSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let dispose = Observable<Any>.create { o in
            
            Disposables.create {
                
            }
        }
        .subscribe { e in
            print("\(e)")
        }
        var label = UILabel()
        label.rx
    }


}

