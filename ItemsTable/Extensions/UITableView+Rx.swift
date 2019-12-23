//
//  UITableView+Rx.swift
//  TableInteraction
//
//  Created by anton on 13.12.2019.
//  Copyright © 2019 none. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UITableView {

    var scrolledDown: ControlEvent<Void> {
        let contentHeight = observe(CGSize.self, "contentSize")
            .startWith(base.contentSize)
            .flatMap(Observable.from(optional:))
            .map { $0.height }
        let frameHeight = observe(CGRect.self, "frame")
            .startWith(base.frame)
            .flatMap(Observable.from(optional:))
            .map { $0.height }
        let scrolledDown =
            contentOffset.withLatestFrom(
                Observable.combineLatest(contentHeight, frameHeight),
                resultSelector: { contentOffset, heights in
                    let (contentHeight, frameHeight) = heights
                    return (contentOffset.y, contentHeight, frameHeight)
                }
            )
            .filter(isScrolledDown(offset:contentHeight:frameHeight:))
            .toVoid()
        return ControlEvent(events: scrolledDown)
    }
}

private func isScrolledDown(offset: CGFloat, contentHeight: CGFloat, frameHeight: CGFloat) -> Bool {
    return offset + frameHeight >= contentHeight
}
