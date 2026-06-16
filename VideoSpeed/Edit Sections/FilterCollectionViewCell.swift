//
//  FilterCollectionViewCell.swift
//  VideoSpeed
//

import UIKit

final class FilterCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "FilterCollectionViewCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = 8
    }

    func configure(title: String, image: UIImage?, isSelected: Bool) {
        titleLabel.text = title
        imageView.image = image

        if isSelected {
            contentView.layer.borderColor = UIColor.white.cgColor
            contentView.layer.borderWidth = 2
            contentView.layer.cornerRadius = 10
            titleLabel.textColor = .white
        } else {
            contentView.layer.borderColor = UIColor.clear.cgColor
            contentView.layer.borderWidth = 0
            contentView.layer.cornerRadius = 0
            titleLabel.textColor = UIColor(white: 0.85, alpha: 1)
        }
    }
}
