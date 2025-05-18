//
//  FontEditSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 11/05/2025.
//

import UIKit

import UIKit

typealias FontClosure = (UIFont) -> Void

class FontEditSectionVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    // Create a collection view layout
    let layout = UICollectionViewFlowLayout()

    // Create the collection view
    var collectionView: UICollectionView!

    // The array of SpidFont objects
    var spidFonts: [SpidFont] = []
    let freeFonts: [String] = ["SYSTEM","Neo","Retrowrite"]
    var didSelectFont: FontClosure?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the layout for the collection view
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 140, height: 50)
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

        // Initialize the collection view with the layout
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear

        // Register the cell class for the collection view
        collectionView.register(FontCell.self, forCellWithReuseIdentifier: "FontCell")
        collectionView.backgroundColor = .clear
        view.backgroundColor = .clear
        
        // Set the view controller as the data source and delegate
        collectionView.dataSource = self
        collectionView.delegate = self

        // Add the collection view to the view hierarchy
        self.collectionView.attachToEdges(of: view)
        spidFonts = loadAllSpidFontsPrioritized()
//        self.view.addSubview(collectionView)
    }

    // MARK: - UICollectionViewDataSource methods

    // Return the number of items in the collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return spidFonts.count
    }

    // Configure and return the cell for each item
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontCell", for: indexPath) as! FontCell
        let spidFont = spidFonts[indexPath.item]

        // Set the label's font and text to show the font name
        cell.configure(with: spidFont, isPro: spidFont.isPro, tagText: "pro")

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedFont = spidFonts[indexPath.item]
        didSelectFont?(selectedFont.font!)
    }

    
    func loadAllSpidFontsPrioritized(size: CGFloat = 18) -> [SpidFont] {
        var spidFonts: [SpidFont] = []

        // Prioritized font names (PostScript names)
        let prioritizedFontNames: [String] = [
            ".SFUIText", // System font (San Francisco)
            "HelveticaNeue",
            "CourierNewPSMT",
            "HelveticaNeue-Bold",
            "AvenirNext-Regular",
            "Avenir-Book",
            "AvenirNext-Bold",
            "Futura-Medium",
            "Futura-CondensedMedium",
            "Georgia",
            "Georgia-Bold",
            "TimesNewRomanPSMT",
            "TimesNewRomanPS-BoldMT",
            "Menlo-Regular",
            "Menlo-Bold",
            "CourierNewPS-BoldMT",
            "AmericanTypewriter",
            "AmericanTypewriter-Bold",
            "ChalkboardSE-Regular",
            "ChalkboardSE-Bold",
            "MarkerFelt-Thin",
            "MarkerFelt-Wide",
            "Noteworthy-Bold",
            "Noteworthy-Light",
            "SnellRoundhand-Bold",
            "GillSans",
            "GillSans-Bold",
            "HoeflerText-Regular",
            "HoeflerText-Black",
            "Zapfino",
            "Baskerville",
            "Baskerville-Bold",
            "Palatino-Roman",
            "Palatino-Bold",
            "Didot",
            "Didot-Bold",
            "Optima-Regular",
            "Optima-Bold",
            "TrebuchetMS",
            "Verdana",
        ]
        
        let spidFontDisplayNames: [String: String] = [
                "HelveticaNeue": "Neo",
                "HelveticaNeue-Bold": "NeoBold",
                "AvenirNext-Regular": "Futuresoft",
                "Avenir-Book": "FuturesoftLite",
                "AvenirNext-Bold": "FuturesoftBold",
                "Futura-Medium": "Coretone",
                "Futura-CondensedMedium": "CoretoneNarrow",
                "Georgia": "Classicread",
                "Georgia-Bold": "ClassicreadBold",
                "TimesNewRomanPSMT": "Royalprint",
                "TimesNewRomanPS-BoldMT": "RoyalprintBold",
                "Menlo-Regular": "Codeblock",
                "Menlo-Bold": "CodeblockBold",
                "CourierNewPSMT": "Retrowrite",
                "CourierNewPS-BoldMT": "RetrowriteBold",
                "AmericanTypewriter": "Keystrike",
                "AmericanTypewriter-Bold": "KeystrikeBold",
                "ChalkboardSE-Regular": "Sketchnote",
                "ChalkboardSE-Bold": "SketchnoteBold",
                "MarkerFelt-Thin": "Inkwave",
                "MarkerFelt-Wide": "InkwaveWide",
                "Noteworthy-Bold": "Jotit",
                "Noteworthy-Light": "JotitLite",
                "SnellRoundhand-Bold": "Velvetscript",
                "GillSans": "Metrosans",
                "GillSans-Bold": "MetrosansBold",
                "HoeflerText-Regular": "Oldstyle",
                "HoeflerText-Black": "OldstyleBlack",
                "Zapfino": "Flourish",
                "Baskerville": "Serifedge",
                "Baskerville-Bold": "SerifedgeBold",
                "Palatino-Roman": "Versetext",
                "Palatino-Bold": "VersetextBold",
                "Didot": "Hauteline",
                "Didot-Bold": "HautelineBold",
                "Optima-Regular": "Optix",
                "Optima-Bold": "OptixBold",
                "TrebuchetMS": "Novabridge",
                "Verdana": "Clearsans",
                ".SFUIText": "SYSTEM"
            ]


        // Add prioritized fonts with custom names
         for name in prioritizedFontNames {
             if let font = UIFont(name: name, size: size) {
                 let displayName = spidFontDisplayNames[name] ?? name
                 if freeFonts.contains(displayName) {
                     spidFonts.append(SpidFont(name: displayName, font: font, isPro: false))
                 }
                 else {
                     spidFonts.append(SpidFont(name: displayName, font: font, isPro: true))
                 }
                 
             }
         }

        return spidFonts
    }
}

// Custom UICollectionViewCell to display font name and sample

class FontCell: UICollectionViewCell {

    static let reuseIdentifier = "FontCell"

    private let fontLabel = UILabel()
    private let tagLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Font name label setup
        fontLabel.translatesAutoresizingMaskIntoConstraints = false
        fontLabel.numberOfLines = 1
        fontLabel.textAlignment = .center
        fontLabel.textColor = .white
        fontLabel.adjustsFontSizeToFitWidth = true
        contentView.addSubview(fontLabel)

        // Tag label setup
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        tagLabel.textColor = .white
        tagLabel.backgroundColor = .systemBlue
        tagLabel.textAlignment = .center
        tagLabel.layer.cornerRadius = 8
        tagLabel.clipsToBounds = true
        tagLabel.isHidden = true
        contentView.addSubview(tagLabel)

        
        
        // Constraints
        NSLayoutConstraint.activate([
            fontLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            fontLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            fontLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            tagLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            tagLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            tagLabel.heightAnchor.constraint(equalToConstant: 16),
            tagLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
    }

    func configure(with spidFont: SpidFont, isPro: Bool = false, tagText: String = "New") {
        fontLabel.text = spidFont.name
        fontLabel.font = spidFont.font

        tagLabel.text = tagText.uppercased()
        tagLabel.isHidden = !isPro
    }
}

