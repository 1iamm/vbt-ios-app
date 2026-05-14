// Citations.swift
// VBTrainer · 2026-05
//
// All papers backing V1 algorithms and defaults. These are the canonical
// references — every algorithm constant in `Algorithms/` (Proposal 2+)
// must doc-cite at least one entry here.
//
// IMPORTANT: when adding a citation, also add the `id` to `Citations.all`
// at the bottom and verify the URL is reachable (HTTPS).

import Foundation

public enum Citations {
    // MARK: - Apple Watch validation

    public static let balshaw2023AppleWatch = PaperCitation(
        id: "balshaw2023AppleWatch",
        authors: "Balshaw, T.G., et al.",
        year: 2023,
        title: "Validity of an Apple Watch for determining bench press velocity",
        journal: "PMC",
        url: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10383699/",
        topic: .appleWatchValidation
    )

    // MARK: - Rep detection

    public static let oReilly2018InertialReview = PaperCitation(
        id: "oReilly2018InertialReview",
        authors: "O'Reilly, M.A., et al.",
        year: 2018,
        title: "Wearable Inertial Sensor Systems for Lower Limb Exercise Detection and Evaluation: A Systematic Review",
        journal: "Sports Medicine 48: 1221–1246",
        doi: "10.1007/s40279-018-0878-4",
        url: "https://link.springer.com/article/10.1007/s40279-018-0878-4",
        topic: .repDetection
    )

    // MARK: - Velocity integration / ZUPT

    public static let skog2010ZUPT = PaperCitation(
        id: "skog2010ZUPT",
        authors: "Skog, I., et al.",
        year: 2010,
        title: "Zero-Velocity Detection — An Algorithm Evaluation",
        journal: "IEEE Transactions on Biomedical Engineering 57(11): 2657-2666",
        doi: "10.1109/TBME.2010.2060723",
        url: "https://ieeexplore.ieee.org/document/5523938",
        topic: .velocityIntegration
    )

    public static let foxlin2005Pedestrian = PaperCitation(
        id: "foxlin2005Pedestrian",
        authors: "Foxlin, E.",
        year: 2005,
        title: "Pedestrian Tracking with Shoe-Mounted Inertial Sensors",
        journal: "IEEE Computer Graphics and Applications 25(6): 38-46",
        doi: "10.1109/MCG.2005.140",
        url: "https://ieeexplore.ieee.org/document/1528433",
        topic: .velocityIntegration
    )

    // MARK: - Velocity loss

    public static let sanchezMedina2011VL = PaperCitation(
        id: "sanchezMedina2011VL",
        authors: "Sánchez-Medina, L., González-Badillo, J.J.",
        year: 2011,
        title: "Velocity loss as an indicator of neuromuscular fatigue during resistance training",
        journal: "Medicine and Science in Sports and Exercise 43(9): 1725-34",
        doi: "10.1249/MSS.0b013e318213f880",
        url: "https://pubmed.ncbi.nlm.nih.gov/21311352/",
        topic: .velocityLoss
    )

    public static let parejaBlanco2017VLEffects = PaperCitation(
        id: "parejaBlanco2017VLEffects",
        authors: "Pareja-Blanco, F., et al.",
        year: 2017,
        title: "Effects of velocity loss during resistance training on athletic performance, strength gains and muscle adaptations",
        journal: "Scandinavian Journal of Medicine & Science in Sports 27(7): 724-735",
        doi: "10.1111/sms.12678",
        url: "https://pubmed.ncbi.nlm.nih.gov/27038416/",
        topic: .velocityLoss
    )

    // MARK: - V1RM

    public static let gonzalezBadillo2010Velocity = PaperCitation(
        id: "gonzalezBadillo2010Velocity",
        authors: "González-Badillo, J.J., Sánchez-Medina, L.",
        year: 2010,
        title: "Movement velocity as a measure of loading intensity in resistance training",
        journal: "International Journal of Sports Medicine 31(5): 347-352",
        doi: "10.1055/s-0030-1248333",
        url: "https://pubmed.ncbi.nlm.nih.gov/20180176/",
        topic: .v1RM
    )

    // MARK: - LVP / e1RM

    public static let jidovtseff2011LVP = PaperCitation(
        id: "jidovtseff2011LVP",
        authors: "Jidovtseff, B., et al.",
        year: 2011,
        title: "Using the load-velocity relationship for 1RM prediction",
        journal: "Journal of Strength and Conditioning Research 25(1): 267-270",
        doi: "10.1519/JSC.0b013e3181b62c5f",
        url: "https://pubmed.ncbi.nlm.nih.gov/19966589/",
        topic: .lvpAndE1RM
    )

    public static let garciaRamos2018LVPVariants = PaperCitation(
        id: "garciaRamos2018LVPVariants",
        authors: "García-Ramos, A., et al.",
        year: 2018,
        title: "Differences in the load-velocity profile between 4 bench-press variants",
        journal: "International Journal of Sports Physiology and Performance 13(3): 326-331",
        doi: "10.1123/ijspp.2017-0158",
        url: "https://pubmed.ncbi.nlm.nih.gov/28872384/",
        topic: .lvpAndE1RM
    )

    // MARK: - MV/MPV/PV variant

    public static let sanchezMedina2010Propulsive = PaperCitation(
        id: "sanchezMedina2010Propulsive",
        authors: "Sánchez-Medina, L., et al.",
        year: 2010,
        title: "Importance of the propulsive phase in strength assessment",
        journal: "International Journal of Sports Medicine 31(2): 123-129",
        doi: "10.1055/s-0029-1242815",
        url: "https://pubmed.ncbi.nlm.nih.gov/20222005/",
        topic: .velocityVariant
    )

    // MARK: - HRmax / heart rate

    public static let tanaka2001HRMax = PaperCitation(
        id: "tanaka2001HRMax",
        authors: "Tanaka, H., et al.",
        year: 2001,
        title: "Age-predicted maximal heart rate revisited",
        journal: "Journal of the American College of Cardiology 37(1): 153-156",
        doi: "10.1016/S0735-1097(00)01054-8",
        url: "https://pubmed.ncbi.nlm.nih.gov/11153730/",
        topic: .heartRate
    )

    // MARK: - HRV / readiness

    public static let plews2013HRV = PaperCitation(
        id: "plews2013HRV",
        authors: "Plews, D.J., et al.",
        year: 2013,
        title: "Training adaptation and heart rate variability in elite endurance athletes",
        journal: "Sports Medicine 43(9): 773-781",
        doi: "10.1007/s40279-013-0071-8",
        url: "https://pubmed.ncbi.nlm.nih.gov/23852425/",
        topic: .hrvReadiness
    )

    public static let flattEsco2016HRV = PaperCitation(
        id: "flattEsco2016HRV",
        authors: "Flatt, A.A., Esco, M.R.",
        year: 2016,
        title: "Smartphone-Derived Heart-Rate Variability and Training Load in a Female Soccer Team",
        journal: "International Journal of Sports Physiology and Performance 11(8): 994-1000",
        doi: "10.1123/ijspp.2015-0556",
        url: "https://pubmed.ncbi.nlm.nih.gov/26869210/",
        topic: .hrvReadiness
    )

    public static let buchheit2014HR = PaperCitation(
        id: "buchheit2014HR",
        authors: "Buchheit, M.",
        year: 2014,
        title: "Monitoring training status with HR measures: do all roads lead to Rome?",
        journal: "Frontiers in Physiology 5: 73",
        doi: "10.3389/fphys.2014.00073",
        url: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3936188/",
        topic: .hrvReadiness
    )

    // MARK: - Sleep

    public static let watson2017Sleep = PaperCitation(
        id: "watson2017Sleep",
        authors: "Watson, A.M.",
        year: 2017,
        title: "Sleep and athletic performance",
        journal: "Current Sports Medicine Reports 16(6): 413-418",
        doi: "10.1249/JSR.0000000000000418",
        url: "https://pubmed.ncbi.nlm.nih.gov/29135639/",
        topic: .sleep
    )

    // MARK: - CMJ / neuromuscular

    public static let claudino2017CMJ = PaperCitation(
        id: "claudino2017CMJ",
        authors: "Claudino, J.G., et al.",
        year: 2017,
        title: "The countermovement jump to monitor neuromuscular status: A meta-analysis",
        journal: "Journal of Science and Medicine in Sport 20(4): 397-402",
        doi: "10.1016/j.jsams.2016.08.011",
        url: "https://pubmed.ncbi.nlm.nih.gov/27663764/",
        topic: .cmjNeuromuscular
    )

    public static let watkins2017CMJReadiness = PaperCitation(
        id: "watkins2017CMJReadiness",
        authors: "Watkins, C.M., et al.",
        year: 2017,
        title: "Determination of Vertical Jump as a Measure of Neuromuscular Readiness and Fatigue",
        journal: "Journal of Strength and Conditioning Research 31(12): 3305-3310",
        doi: "10.1519/JSC.0000000000002231",
        url: "https://pubmed.ncbi.nlm.nih.gov/29189407/",
        topic: .cmjNeuromuscular
    )

    public static let linthorne2001Jump = PaperCitation(
        id: "linthorne2001Jump",
        authors: "Linthorne, N.P.",
        year: 2001,
        title: "Analysis of standing vertical jumps using a force platform",
        journal: "American Journal of Physics 69: 1198",
        doi: "10.1119/1.1397460",
        url: "https://aapt.scitation.org/doi/10.1119/1.1397460",
        topic: .cmjNeuromuscular
    )

    // MARK: - Public collection

    public static let all: [PaperCitation] = [
        balshaw2023AppleWatch,
        oReilly2018InertialReview,
        skog2010ZUPT,
        foxlin2005Pedestrian,
        sanchezMedina2011VL,
        parejaBlanco2017VLEffects,
        gonzalezBadillo2010Velocity,
        jidovtseff2011LVP,
        garciaRamos2018LVPVariants,
        sanchezMedina2010Propulsive,
        tanaka2001HRMax,
        plews2013HRV,
        flattEsco2016HRV,
        buchheit2014HR,
        watson2017Sleep,
        claudino2017CMJ,
        watkins2017CMJReadiness,
        linthorne2001Jump
    ]

    public static func byTopic(_ topic: CitationTopic) -> [PaperCitation] {
        all.filter { $0.topic == topic }
    }

    public static func byId(_ id: String) -> PaperCitation? {
        all.first { $0.id == id }
    }
}
