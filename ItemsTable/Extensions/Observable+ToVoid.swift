//
//  ObservableType+ToVoid.swift
//  TableInteraction
//
//  Created by anton on 19.12.2019.
//  Copyright © 2019 none. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableConvertibleType {

    func toVoid() -> Observable<Void> {
        return asObservable()
            .map { _ in () }
    }
}
