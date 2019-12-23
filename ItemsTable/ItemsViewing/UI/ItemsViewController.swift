//
//  ItemsViewController.swift
//  TableInteraction
//
//  Created by anton on 10.12.2019.
//  Copyright © 2019 none. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ItemsViewController: UITableViewController {

    // MARK: - View Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = workaround_bindingsSetUp
        // After fix in bug mentioned below, bindings setup code
        // should be places in `viewDidLoad`.
    }

    // MARK: - Rx Bindings

    private let disposeBag = DisposeBag()

    private func setupBindings(on tableView: UITableView) -> Disposable {
        let loadNext = tableView.rx.scrolledDown.publish()
        let tableUpdate = makeItemsTableInteractor(loadNext: loadNext)
            .tableUpdate
            .publish()

        let tableUpdateBinding = bind(
            tableUpdate: tableUpdate,
            tableView: tableView
        )
        let showActivityIndicatorBinding = bind(
            loadNext: loadNext,
            showActivityIndicatorBinder: self.rx.showActivityIndicator
        )
        let hideActivityIndiatorBinding = bind(
            tableUpdate: tableUpdate,
            hideActivityIndicatorBinder: self.rx.hideActivityIndicator
        )
            
        return CompositeDisposable(
            tableUpdateBinding,
            showActivityIndicatorBinding,
            hideActivityIndiatorBinding,
            loadNext.connect(),
            tableUpdate.connect()
        )
    }

    private func bind(
        tableUpdate: Observable<ItemsTableInteractor.Update>,
        tableView: UITableView,
        dataSource: DataSource = .init()
    ) -> Disposable {
        let binder: (Observable<ItemsTableInteractor.Update>) -> Disposable
            = tableView.rx.items(dataSource: dataSource)
        tableView.delegate = nil
        tableView.dataSource = nil
        return tableUpdate.bind(to: binder)
    }

    private func bind(
        loadNext: Observable<Void>,
        showActivityIndicatorBinder: Binder<Void>
    ) -> Disposable {
        return loadNext
            .toVoid()
            .bind(to: showActivityIndicatorBinder)
    }

    private func bind(
        tableUpdate: Observable<ItemsTableInteractor.Update>,
        hideActivityIndicatorBinder: Binder<Void>
    ) -> Disposable {
        return tableUpdate
            .filter { update in
                switch update {
                case .appendItems: return true
                case .updateDetail: return false
                }
            }
            .toVoid()
            .bind(to: hideActivityIndicatorBinder)
    }

    // MARK: - Core Instantiation

    private func makeItemsTableInteractor(loadNext: Observable<Void>) -> ItemsTableInteractor {
        let itemsService = ItemsService()
        let interactor = ItemsTableInteractor(
            getPage: itemsService.items(forOffset:count:),
            getDetail: itemsService.detail(forId:),
            loadNext: loadNext
        )
        return interactor
    }

    // MARK: - Workaround

    // Fixes UITableViewAlertForLayoutOutsideViewHierarchy warning.
    // Affected: RxSwift 5.0.1
    // https://github.com/RxSwiftCommunity/RxDataSources/issues/331
    private lazy var workaround_bindingsSetUp: Bool = {
        setupBindings(on: self.tableView)
            .disposed(by: self.disposeBag)
        return true
    } ()

    // MARK: - Activity Indicator

    fileprivate func showActivityIndicator() {
        guard isViewLoaded else { return }
        switch tableView.tableFooterView {
        case nil:
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.color = .gray
            tableView.tableFooterView = activityIndicator
            activityIndicator.startAnimating()
        case let activityIndicator as UIActivityIndicatorView where !activityIndicator.isAnimating:
            activityIndicator.startAnimating()
        case is UIActivityIndicatorView:
            break
        case .some:
            assertionFailure("Wrong footer")
        }
    }

    fileprivate func hideActivityIndicator() {
        guard
            isViewLoaded,
            let activityIndicator = tableView.tableFooterView as? UIActivityIndicatorView
        else { return }
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        tableView.tableFooterView = nil
    }
}

// MARK: - Binders

private extension Reactive where Base == ItemsViewController {

    var showActivityIndicator: Binder<Void> {
        return Binder(base) { target, _ in
            target.showActivityIndicator()
        }
    }

    var hideActivityIndicator: Binder<Void> {
        return Binder(base) { target, _ in
            target.hideActivityIndicator()
        }
    }
}

// MARK: - Data Source

private final class DataSource: NSObject, UITableViewDataSource, RxTableViewDataSourceType {

    struct CellModel {
        var id: String
        var title: String
        var detail: String? = nil
        init(item: Item) {
            self.id = item.id
            self.title = item.title
        }
    }

    var cellModels: [CellModel] = []

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let model = cellModels[indexPath.row]
        cell.textLabel?.text = model.title
        cell.detailTextLabel?.text = model.detail
        return cell
    }

    func tableView(_ tableView: UITableView, observedEvent: Event<ItemsTableInteractor.Update>) {
        switch observedEvent {
        case let .next(.appendItems(items)):
            appendItems(items, in: tableView)
        case let .next(.updateDetail(itemID, detail)):
            updateDetail(detail, forId: itemID, in: tableView)
        case .error, .completed:
            break
        }
    }

    private func appendItems(_ items: [Item], in tableView: UITableView) {
        guard !items.isEmpty else { return }
        let newModels = items.map(CellModel.init(item:))
        let from = cellModels.count
        let to = from + newModels.count
        cellModels += newModels
        guard tableView.superview != nil else { return }
        let indexPaths = (from..<to).map { IndexPath(row: $0, section: 0) }
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    private func updateDetail(_ detail: String, forId id: String, in tableView: UITableView) {
        guard let index = cellModels.firstIndex(where: { $0.id == id }) else { return }
        cellModels[index].detail = detail
        guard tableView.superview != nil else { return }
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
}
