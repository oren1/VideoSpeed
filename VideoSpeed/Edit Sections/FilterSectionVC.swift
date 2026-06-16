//
//  FilterSectionVC.swift
//  VideoSpeed
//

import UIKit
import CoreImage

typealias FilterSelectionClosure = (VideoFilter) -> Void

final class FilterSectionVC: SectionViewController {

    var filterDidChange: FilterSelectionClosure?

    private let filters = VideoFilter.allCases
    private var previewImages: [VideoFilter: UIImage] = [:]
    private var selectedFilter: VideoFilter = .none
    private var previewGenerationTask: Task<Void, Never>?
    private let sectionInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

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
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
        previewGenerationTask?.cancel()
    }

    @objc private func videoSelectionChanged() {
        Task {
            await reloadFromCurrentAsset()
        }
    }

    @MainActor
    func reloadFromCurrentAsset() async {
        previewGenerationTask?.cancel()
        previewImages = [:]
        collectionView.reloadData()

        guard let spidAsset = UserDataManager.main.currentSpidAsset else { return }

        selectedFilter = await spidAsset.videoFilter
        let thumbnailImage = await spidAsset.thumbnailImage
        collectionView.reloadData()
        scrollToSelectedFilter(animated: false)

        previewGenerationTask = Task.detached(priority: .userInitiated) { [filters, thumbnailImage] in
            let context = CIContext(options: [.useSoftwareRenderer: false])
            var generatedPreviews: [VideoFilter: UIImage] = [:]

            for filter in filters {
                if Task.isCancelled { return }

                if let preview = FilterCompositor.previewImage(
                    for: filter,
                    from: thumbnailImage,
                    context: context
                ) {
                    generatedPreviews[filter] = preview
                }
            }

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.previewImages = generatedPreviews
                self.collectionView.reloadData()
                self.scrollToSelectedFilter(animated: false)
            }
        }
    }

    private func scrollToSelectedFilter(animated: Bool) {
        guard let index = filters.firstIndex(of: selectedFilter) else { return }
        collectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
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
            title: filter.displayName,
            image: previewImages[filter],
            isSelected: filter == selectedFilter
        )
        return cell
    }
}

extension FilterSectionVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filter = filters[indexPath.item]
        guard filter != selectedFilter else { return }

        selectedFilter = filter
        collectionView.reloadData()
        scrollToSelectedFilter(animated: true)
        filterDidChange?(filter)
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
