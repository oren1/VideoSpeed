//
//  FilterSectionVC.swift
//  VideoSpeed
//

import UIKit
import CoreImage

typealias FilterSelectionClosure = (VideoFilter) -> Void

final class FilterSectionVC: SectionViewController {

    var filterDidChange: FilterSelectionClosure?
    var applyToAllTapped: FilterSelectionClosure?

    private let filters = VideoFilter.displayOrder
    private var previewImages: [VideoFilter: UIImage] = [:]
    private var previewTasks: [VideoFilter: Task<Void, Never>] = [:]
    private var thumbnailImage: CGImage?
    private var previewGenerationToken = UUID()
    private var selectedFilter: VideoFilter = .none
    private let sectionInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    private let applyToAllButtonHeight: CGFloat = 36

    private lazy var applyToAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply to All", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(applyToAllButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            FilterCollectionViewCell.self,
            forCellWithReuseIdentifier: FilterCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        view.addSubview(applyToAllButton)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            applyToAllButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            applyToAllButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            applyToAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            applyToAllButton.heightAnchor.constraint(equalToConstant: applyToAllButtonHeight),

            collectionView.topAnchor.constraint(equalTo: applyToAllButton.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoSelectionChanged),
            name: Notification.Name.VideoSelectionChanged,
            object: nil
        )

        Task {
            await reloadFromCurrentAsset()
        }
    }

    deinit {
        cancelAllPreviewTasks()
    }

    @objc private func videoSelectionChanged() {
        Task {
            await reloadFromCurrentAsset()
        }
    }

    @objc private func applyToAllButtonTapped() {
        applyToAllTapped?(selectedFilter)
    }

    @MainActor
    func reloadFromCurrentAsset() async {
        cancelAllPreviewTasks()
        previewImages = [:]
        previewGenerationToken = UUID()
        updateApplyToAllButtonVisibility()
        collectionView.reloadData()

        guard let spidAsset = UserDataManager.main.currentSpidAsset else { return }

        selectedFilter = await spidAsset.videoFilter
        thumbnailImage = await spidAsset.thumbnailImage
        collectionView.reloadData()
        scrollToSelectedFilter(animated: false)
        collectionView.layoutIfNeeded()
        prefetchVisiblePreviews(highPriority: true)
    }

    @MainActor
    private func updateApplyToAllButtonVisibility() {
        applyToAllButton.isHidden = UserDataManager.main.spidAssets.count <= 1
    }

    private func scrollToSelectedFilter(animated: Bool) {
        guard let index = filters.firstIndex(of: selectedFilter) else { return }
        collectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
    }

    private func cancelAllPreviewTasks() {
        previewTasks.values.forEach { $0.cancel() }
        previewTasks.removeAll()
    }

    private func cancelPreview(for filter: VideoFilter) {
        previewTasks[filter]?.cancel()
        previewTasks[filter] = nil
    }

    private func requestPreview(for filter: VideoFilter, priority: TaskPriority) {
        guard previewImages[filter] == nil else { return }
        guard previewTasks[filter] == nil else { return }
        guard let thumbnailImage else { return }

        let token = previewGenerationToken
        let thumbnail = thumbnailImage

        previewTasks[filter] = Task.detached(priority: priority) { [weak self] in
            let context = CIContext(options: [.useSoftwareRenderer: false])
            guard let preview = FilterCompositor.previewImage(
                for: filter,
                from: thumbnail,
                context: context
            ) else { return }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.previewGenerationToken == token else { return }
                self.previewTasks[filter] = nil
                self.previewImages[filter] = preview
                self.updateCellPreview(preview, for: filter)
            }
        }
    }

    private func prefetchVisiblePreviews(highPriority: Bool) {
        let priority: TaskPriority = highPriority ? .userInitiated : .utility
        for indexPath in collectionView.indexPathsForVisibleItems {
            requestPreview(for: filters[indexPath.item], priority: priority)
        }

        if let selectedIndex = filters.firstIndex(of: selectedFilter) {
            requestPreview(for: filters[selectedIndex], priority: .high)
        }
    }

    private func updateCellPreview(_ image: UIImage, for filter: VideoFilter) {
        guard let index = filters.firstIndex(of: filter) else { return }
        let indexPath = IndexPath(item: index, section: 0)

        guard let cell = collectionView.cellForItem(at: indexPath) as? FilterCollectionViewCell,
              cell.representedFilter == filter else {
            return
        }

        cell.configure(
            filter: filter,
            title: filter.displayName,
            image: image,
            isSelected: filter == selectedFilter
        )
    }
}

extension FilterSectionVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FilterCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as! FilterCollectionViewCell

        let filter = filters[indexPath.item]
        cell.configure(
            filter: filter,
            title: filter.displayName,
            image: previewImages[filter],
            isSelected: filter == selectedFilter
        )

        if previewImages[filter] == nil {
            requestPreview(for: filter, priority: .userInitiated)
        }

        return cell
    }
}

extension FilterSectionVC: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        requestPreview(for: filters[indexPath.item], priority: .userInitiated)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filter = filters[indexPath.item]
        guard filter != selectedFilter else { return }

        selectedFilter = filter
        collectionView.reloadData()
        scrollToSelectedFilter(animated: true)
        filterDidChange?(filter)
    }
}

extension FilterSectionVC: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            requestPreview(for: filters[indexPath.item], priority: .utility)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            let filter = filters[indexPath.item]
            if previewImages[filter] == nil {
                cancelPreview(for: filter)
            }
        }
    }
}

extension FilterSectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let labelHeight: CGFloat = 28
        let verticalInsets = sectionInsets.top + sectionInsets.bottom
        let availableHeight = collectionView.bounds.height - verticalInsets
        let squareSize = max(56, availableHeight - labelHeight)
        return CGSize(width: squareSize, height: availableHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        sectionInsets
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        8
    }
}
