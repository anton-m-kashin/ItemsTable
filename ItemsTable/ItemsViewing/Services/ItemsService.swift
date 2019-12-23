//
//  ItemsService.swift
//  TableInteraction
//
//  Created by anton on 10.12.2019.
//  Copyright © 2019 none. All rights reserved.
//

import Foundation
import RxSwift

final class ItemsService {

    private let itemsRepository = ItemsRepository()
    private let scheduler = ConcurrentDispatchQueueScheduler(
        queue: .init(label: "ItemService", qos: .default, attributes: .concurrent)
    )

    func items(forOffset offset: Int, count: Int) -> Single<[Item]> {
        return Single.create { [itemsRepository] single in
            let items = itemsRepository.items(forOffset: offset, count: count)
            single(.success(items))
            return Disposables.create()
        }
        .subscribeOn(scheduler)
    }

    func detail(forId id: String) -> Single<String> {
        return Single.create { [itemsRepository] single in
            if let detail = itemsRepository.detail(forItemId: id) {
                single(.success(detail))
            } else {
                single(.error(Error.detailNotFound))
            }
            return Disposables.create()
        }
        .subscribeOn(scheduler)
    }

    enum Error: Swift.Error {
        case detailNotFound
    }
}
