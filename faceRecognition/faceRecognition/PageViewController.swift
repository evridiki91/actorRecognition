//
//  PageViewController.swift
//  faceRecognition
//
//  Created by Evridiki Christodoulou on 04/04/2018.
//  Copyright © 2018 Evridiki Christodoulou. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    lazy var viewControllerList: [UIViewController] = {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        
        let vc0 = storyBoard.instantiateViewController(withIdentifier: "zeroVC")
        let vc1 = storyBoard.instantiateViewController(withIdentifier: "firstVC")
        let vc2 = storyBoard.instantiateViewController(withIdentifier: "secondVC")
        let vc3 = storyBoard.instantiateViewController(withIdentifier: "thirdVC")
        let vc4 = storyBoard.instantiateViewController(withIdentifier: "fourthVC")
        let vc5 = storyBoard.instantiateViewController(withIdentifier: "fifthVC")
        
        return [vc0,vc1,vc2,vc3,vc4,vc5]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        
        if let firstVC = viewControllerList.first {
            self.setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
        // Do any additional setup after loading the view.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = viewControllerList.index(of: viewController) else {return nil}
        let prevIndex = vcIndex - 1
        guard prevIndex >= 0 else {return nil}
        guard viewControllerList.count > prevIndex else {return nil}
        return viewControllerList[prevIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = viewControllerList.index(of: viewController) else {return nil}
        let nextIndex = vcIndex + 1
        guard viewControllerList.count != nextIndex else {return nil}
        guard viewControllerList.count > nextIndex else {return nil}
        return viewControllerList[nextIndex]
    }
    

   

   

}
