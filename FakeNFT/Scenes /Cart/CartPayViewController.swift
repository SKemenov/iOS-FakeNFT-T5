import UIKit
import Kingfisher

final class CartPayViewController: UIViewController, ErrorView {

    // MARK: - Private constants

    private let servicesAssembly = ServicesAssembly(
        networkClient: DefaultNetworkClient(),
        nftStorage: NftStorageImpl()
    )

    // MARK: - Private mutable properties

    private var orderId: String?

    private lazy var criptoArray: [CriptoResultModel] = []

    private lazy var criptoDetail = CriptoDetailImpl(
        servicesAssembly: servicesAssembly,
        service: servicesAssembly.criptoService,
        delegate: self
    )

    private lazy var payment: PaymentResultModel = PaymentResultModel(success: false, orderId: orderId ?? "", id: "")

    private lazy var paymentDetail = PaymentDetailImpl(
        servicesAssembly: servicesAssembly,
        service: servicesAssembly.paymentService,
        delegate: self
    )

    private var selectionArray: [CGFloat] = []
    private var selectedCripto: CriptoResultModel?

    private lazy var titleBackgroundView: UIView = {
        let view = UIView()
        view.layer.backgroundColor = UIColor.clear.cgColor
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 88)
        return view
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage.backward, for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.tintColor = UIColor.ypBlackDay
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var cartPayLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("cart.cartPayViewController.title", comment: "")
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = UIColor.ypBlackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ypLightGreyDay
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var userAgreementLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.text = NSLocalizedString("cart.cartPayViewController.agreement", comment: "")
        label.textColor = UIColor.ypBlackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var userAgreementLinkLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.text = NSLocalizedString("cart.cartPayViewController.agreementLink", comment: "")
        label.textColor = UIColor.ypBlueUniversal
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userAgreementTapped))
        label.addGestureRecognizer(tapGesture)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var payButton: UIButton = {
        let button = UIButton.systemButton(
            with: UIImage(),
            target: self,
            action: #selector(didTapPayButton)
        )
        button.backgroundColor = UIColor.ypBlackDay
        button.setTitle(NSLocalizedString("cart.cartPayViewController.pay", comment: ""), for: .normal)
        button.setTitleColor(UIColor.ypWhiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    init(orderId: String?) {
        self.orderId = orderId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View controller lifecycle methods
    override func loadView() {
        super.loadView()
        self.criptoDetail.startLoading(criptos: criptoArray, httpMethod: HttpMethod.get)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ypWhiteDay
        collectionViewConfig()
        configureConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    private func collectionViewConfig() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            CartPayCollectionViewCell.self,
            forCellWithReuseIdentifier: CartPayCollectionViewCell().cellIdentifier
        )
        collectionView.allowsMultipleSelection = false
    }

    // MARK: - Objective-C functions
    @objc
    private func didTapPayButton() {
        var selectedIndex = ""
        if let selectedCripto = selectionArray.firstIndex(of: 1) {
            selectedIndex = String(Int(selectedCripto))
        }
        let paymentToSend = PaymentResultModel(success: false, orderId: orderId ?? "", id: selectedIndex)
        self.paymentDetail.startLoading(payment: paymentToSend, httpMethod: HttpMethod.get)
    }

    @objc
    private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func userAgreementTapped() {
        let webViewController = WebViewViewController(
            urlString: "https://yandex.ru/legal/practicum_termsofuse/"
        )
        navigationController?.pushViewController(webViewController, animated: true)
    }
}

// MARK: - CriptoDetailProtocol
extension CartPayViewController: CriptoDetailProtocol {
    func sendLoaded(criptos: [CriptoResultModel]) {
        self.criptoArray = criptos
        criptoArray.enumerated().forEach { (_, _) in
            selectionArray.append(0)
        }
        collectionView.reloadData()
    }
}

// MARK: - PaymentDateilProtocol
extension CartPayViewController: PaymentDetailProtocol {
    func sendLoaded(payment: PaymentResultModel) {
        self.payment = payment
        switch payment.success {
        case false:
            var error = ErrorModel(
                title: NSLocalizedString("cart.cartPayViewController.errorMessage", comment: ""),
                message: "",
                actionText: NSLocalizedString("cart.cartPayViewController.errorCancel", comment: ""),
                action: {}
            )
            error.setSecondActionText(
                NSLocalizedString("cart.cartPayViewController.errorRepeat", comment: "")
            )
            error.setSecondAction {
                self.didTapPayButton()
            }
            return showError(error)
        default:
            let successViewController = CartPaySuccessViewController()
            navigationController?.pushViewController(successViewController, animated: true)
        }

    }
}

// MARK: - CollectionViewDelegate
extension CartPayViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var array: [CGFloat] = []
        criptoArray.enumerated().forEach { (_, _) in
            array.append(0)
        }
        let selectedItem = indexPath.row
        array.remove(at: selectedItem)
        array.insert(1, at: selectedItem)
        selectionArray = array
        selectedCripto = criptoArray[selectedItem]
        collectionView.reloadData()
    }
}

// MARK: - CollectionViewDataSource
extension CartPayViewController: UICollectionViewDataSource {
    /// Number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    /// Number of items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return criptoArray.count
    }

    /// Cell for item
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CartPayCollectionViewCell().cellIdentifier,
            for: indexPath
        ) as? CartPayCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(
            name: "\(criptoArray[indexPath.row].title)",
            title: "\(criptoArray[indexPath.row].id)",
            image: UIImage(),
            borderWidth: selectionArray[indexPath.row])

        updateImage(at: indexPath, cell: cell)

        return cell
    }

    private func updateImage(at indexPath: IndexPath, cell: CartPayCollectionViewCell) {
        if criptoArray.count > 0 {
            cell.activityIndicator.startAnimating()
            let processor = DownsamplingImageProcessor(size: CGSize(width: 36, height: 36))
            cell.cellCriptoImageView.kf.setImage(
                with: self.criptoArray[indexPath.row].image,
                options: [.processor(processor)]) { result in
                    cell.activityIndicator.stopAnimating()
                    switch result {
                    case .success:
                        return
                    case .failure:
                        cell.cellCriptoImageView.image = UIImage(systemName: "nosign") ?? UIImage()
                        cell.cellCriptoImageView.tintColor = UIColor.ypBlackDay
                    }
                }
        }
    }
}

// MARK: - CollectionViewDelegateFlowLayout
extension CartPayViewController: UICollectionViewDelegateFlowLayout {
    /// Set layout width and height
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellLeading: CGFloat = 16
        let cellSpacing: CGFloat = 7
        let cellCount: CGFloat = 2
        let cellHeight: CGFloat = 46
        let collectionViewWidth: CGFloat = collectionView.bounds.width
        let automaticCellWidth = (collectionViewWidth / cellCount - cellSpacing / cellCount) - cellLeading
        return CGSize(width: automaticCellWidth, height: cellHeight)
    }
    /// Set layout horizontal spacing
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }
    /// Set layout vertical spacing
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }
    /// Set section insets
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let sectionInsets = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        return sectionInsets
    }
}

// MARK: - Configure constraints
private extension CartPayViewController {

    func configureConstraints() {
        view.addSubview(titleBackgroundView)
        titleBackgroundView.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.heightAnchor.constraint(equalToConstant: 42),
            backButton.widthAnchor.constraint(equalToConstant: 42),
            backButton.leadingAnchor.constraint(equalTo: titleBackgroundView.leadingAnchor),
            backButton.bottomAnchor.constraint(equalTo: titleBackgroundView.bottomAnchor)
        ])
        titleBackgroundView.addSubview(cartPayLabel)
        NSLayoutConstraint.activate([
            cartPayLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            cartPayLabel.leadingAnchor.constraint(equalTo: titleBackgroundView.leadingAnchor),
            cartPayLabel.trailingAnchor.constraint(equalTo: titleBackgroundView.trailingAnchor)
        ])

        view.addSubview(bottomView)
        NSLayoutConstraint.activate([
            bottomView.heightAnchor.constraint(equalToConstant: 186),
            bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        bottomView.addSubview(payButton)
        NSLayoutConstraint.activate([
            payButton.heightAnchor.constraint(equalToConstant: 60),
            payButton.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 12),
            payButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -12),
            payButton.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor, constant: -50)
        ])

        bottomView.addSubview(userAgreementLabel)
        NSLayoutConstraint.activate([
            userAgreementLabel.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 16),
            userAgreementLabel.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -16),
            userAgreementLabel.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 16)
        ])

        bottomView.addSubview(userAgreementLinkLabel)
        NSLayoutConstraint.activate([
            userAgreementLinkLabel.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 16),
            userAgreementLinkLabel.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -16),
            userAgreementLinkLabel.topAnchor.constraint(equalTo: userAgreementLabel.bottomAnchor, constant: 4)
        ])

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: titleBackgroundView.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

    }
}
