//
//  SpidFont+Catalog.swift
//  VideoSpeed
//
//  Shared prioritized font list (same order/rules as FontEditSectionVC).
//

import UIKit

extension SpidFont {

    /// Prioritized caption/text fonts with display names and pro flags.
    static func loadAllPrioritized(size: CGFloat = 18) -> [SpidFont] {
        var spidFonts: [SpidFont] = []

        let freeFontDisplayNames: [String] = ["SYSTEM", "Neo", "Retrowrite"]

        let prioritizedFontNames: [String] = [
            "TimesNewRomanPSMT",
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
            "TimesNewRomanPSMT": "SYSTEM",
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
        ]

        for postscriptName in prioritizedFontNames {
            guard let font = UIFont(name: postscriptName, size: size) else { continue }
            let displayName = spidFontDisplayNames[postscriptName] ?? postscriptName
            let isPro = !freeFontDisplayNames.contains(displayName)
            spidFonts.append(SpidFont(name: postscriptName, displayName: displayName, font: font, isPro: isPro))
        }

        return spidFonts
    }
}
