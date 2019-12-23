//
//  ItemsTableInteractor.swift
//  TableInteraction
//
//  Created by anton on 10.12.2019.
//  Copyright © 2019 none. All rights reserved.
//

import Foundation
import RxSwift

final class ItemsTableInteractor {

    private let getPage: (_ offset: Int, _ count: Int) -> Single<[Item]>
    private let getDetail: (String) -> Single<(id: String, detail: String)>

    private let loadNext: Observable<Void>

    private let scheduler = ConcurrentDispatchQueueScheduler(
        queue: .init(label: "ItemTableInteractor-Work", qos: .default, attributes: .concurrent)
    )

    var tableUpdate: Observable<Update> {
        let firstPageSize = 20
        let pageSize = 10
        return loadNext
            .debounce(.seconds(3), scheduler: scheduler)
            .map { _ in pageSize }
            .startWith(firstPageSize)
            .scan((offset: 0, count: 0)) { previous, nextCount in
                (
                    offset: previous.offset + previous.count,
                    count: nextCount
                )
            }
            .concatMap(getPage)
            .observeOn(scheduler)
            .multicast(
                { PublishSubject<[Item]>() },
                selector: { [getDetail, scheduler] page in
                    let item = page.map(Update.appendItems)
                    let detail = page
                        .flatMap { Observable.from($0) }
                        .map { $0.id }
                        .flatMap(getDetail)
                        .observeOn(scheduler)
                        .map(Update.updateDetail)
                    return .merge(item, detail)
                }
            )
            .subscribeOn(scheduler)
    }

    init(
        getPage: @escaping (_ offset: Int, _ count: Int) -> Single<[Item]>,
        getDetail: @escaping (String) -> Single<String>,
        loadNext: Observable<Void>
    ) {
        self.getPage = getPage
        self.getDetail = { id in
            getDetail(id).map { detail in
                (id: id, detail: detail)
            }
        }
        self.loadNext = loadNext
    }

    enum Update {
        case appendItems([Item])
        case updateDetail(itemID: String, detail: String)
    }
}
