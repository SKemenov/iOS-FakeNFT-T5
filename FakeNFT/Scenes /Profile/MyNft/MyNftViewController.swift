//
//  MyNftViewController.swift
//  FakeNFT
//
//  Created by Aleksey Kolesnikov on 11.12.2023.
//

import UIKit

enum MyNftsDetailState {
    case initial, loading, failed(Error), data([NftResult])
}

final class MyNftViewController: UIViewController {
    //MARK: - Layout variables
    private lazy var backButton: UIButton = {
        let imageButton = UIImage(named: "backward")
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.setImage(imageButton, for: .normal)
        button.addTarget(self, action: #selector(back), for: .touchUpInside)
        
        return button
    }()
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .ypBlackDay
        label.text = "Мои NFT"
        
        return label
    }()
    private lazy var filtersButton: UIButton = {
        let imageButton = UIImage(named: "Sort")
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.setImage(imageButton, for: .normal)
        button.addTarget(self, action: #selector(sort), for: .touchUpInside)
        
        return button
    }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(MyNftTableViewCell.self, forCellReuseIdentifier: "myNftTableViewCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .ypWhiteDay
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.rowHeight = 140
        
        return tableView
    }()
    private lazy var emptyNftsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .ypBlackDay
        label.text = "У Вас ещё нет NFT"
        
        return label
    }()
    
    //MARK: - Private variables
    private var nfts: [NftModel] = []
    private var profileId: String?
    private let nftService = NftServiceImpl.shared
    var state = MyNftsDetailState.initial {
        didSet {
            stateDidChanged()
        }
    }
    
    //MARK: - Initialization
    init(profileId: String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.profileId = profileId
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
}

//MARK: - UITableViewDataSource
extension MyNftViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nfts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "myNftTableViewCell",
            for: indexPath
        ) as? MyNftTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configureCell(name: nfts[indexPath.row].name)
        
        return cell
    }
}

//MARK: - UITableViewDelegate
extension MyNftViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectCell(cellIndex: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: - Private functions
private extension MyNftViewController{
    func setupView() {
        view.backgroundColor = .ypWhiteDay
        
        let showHideElements = nfts.isEmpty
        emptyNftsLabel.isHidden = !showHideElements
        filtersButton.isHidden = showHideElements
        headerLabel.isHidden = showHideElements
        tableView.isHidden = showHideElements
        
        addSubViews()
        configureConstraints()
    }
    
    func addSubViews() {
        view.addSubview(emptyNftsLabel)
        view.addSubview(backButton)
        view.addSubview(filtersButton)
        view.addSubview(headerLabel)
        view.addSubview(tableView)
    }
    
    func configureConstraints() {
        NSLayoutConstraint.activate([
            emptyNftsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyNftsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 9),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 9),
            
            filtersButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -9),
            filtersButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
    
            headerLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func selectCell(cellIndex: Int) {

    }
    
    func showSortAlert() {
        let alert = UIAlertController(
            title: "Сортировка",
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "По цене",
                                      style: .default) { _ in

        })
        alert.addAction(UIAlertAction(
            title: "По рейтингу",
            style: .default
        ) { _ in
        })
        alert.addAction(UIAlertAction(
            title: "По названию",
            style: .default
        ) { _ in
        })
        alert.addAction(UIAlertAction(
            title: "Закрыть",
            style: .cancel
        ) { _ in
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func stateDidChanged() {
        switch state {
            case .initial:
                assertionFailure("Can't move to initial state")
            case .loading:
                UIBlockingProgressHUD.show()
                fetchNfts(profileId: profileId)
                UIBlockingProgressHUD.dismiss()
            case .data(let nftResults):
                for nftResult in nftResults {
                    let nft = NftModel(
                        createdAt: DateFormatter.defaultDateFormatter.date(from: nftResult.createdAt),
                        name: nftResult.name,
                        images: nftResult.images,
                        rating: nftResult.rating,
                        description: nftResult.description,
                        price: nftResult.price,
                        author: nftResult.author,
                        id: nftResult.id
                    )
                    nfts.append(nft)
                    //обновить collectionView
                    UIBlockingProgressHUD.dismiss()
                }
                
            case .failed(let error):
                UIBlockingProgressHUD.dismiss()
                assertionFailure("Error: \(error)")
        }
    }
    
    func fetchNfts(profileId: String?) {
        guard let profileId = profileId,
              let profile = ProfileStorageImpl.shared.getProfile(id: profileId) else {
            UIBlockingProgressHUD.dismiss()
            return
        }
        
        let nftsId = [
            "739e293c-1067-43e5-8f1d-4377e744ddde",
            "77c9aa30-f07a-4bed-886b-dd41051fade2",
            "ca34d35a-4507-47d9-9312-5ea7053994c0",
            "739e293c-1067-43e5-8f1d-4377e744ddde"
        ]//profile.nfts
            
        var fetchedNFTs: [NftResult] = []
//        let group = DispatchGroup()
//        
//        for nftId in nftsId {
//            group.enter()
//            
//            nftService.loadNft(id: nftId) { (result) in
//                switch result {
//                    case .success(let nft):
//                        fetchedNFTs.append(nft)
//                    case .failure(let error):
//                        self.state = .failed(error)
//                        print("Failed to fetch NFT with ID \(nftId): \(error)")
//                }
//                group.leave()
//            }
//        }
//        group.notify(queue: .main) { [weak self] in
//            guard let self = self else { return }
//            self.state = .data(fetchedNFTs)
//        }
    }
    
    @objc
    func back() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc
    func sort() {
        showSortAlert()
    }
}
