import Foundation

/// All questionnaires available in the app.
public enum InstrumentCatalog {
    public static let all: [Instrument] = [
        neckDisabilityIndex,
        lowBackDisabilityIndex,
        hipDisabilityIndex,
        kneeDisabilityIndex,
        shoulderDisabilityIndex,
        peg,
    ]

    public static func instrument(withID id: String) -> Instrument? {
        all.first { $0.id == id }
    }

    // MARK: Bands

    /// Vernon's NDI interpretation (0–4, 5–14, 15–24, 25–34, 35+ out of 50).
    static let ndiBands = [
        SeverityBand(label: "No disability", lowerBound: 0, level: 0),
        SeverityBand(label: "Mild disability", lowerBound: 10, level: 1),
        SeverityBand(label: "Moderate disability", lowerBound: 30, level: 2),
        SeverityBand(label: "Severe disability", lowerBound: 50, level: 3),
        SeverityBand(label: "Complete disability", lowerBound: 70, level: 4),
    ]

    /// The same cut-offs for the indexes modelled on the NDI. Labelled as
    /// "limitation" because they have not been validated.
    static let regionalBands = [
        SeverityBand(label: "Minimal limitation", lowerBound: 0, level: 0),
        SeverityBand(label: "Mild limitation", lowerBound: 10, level: 1),
        SeverityBand(label: "Moderate limitation", lowerBound: 30, level: 2),
        SeverityBand(label: "Severe limitation", lowerBound: 50, level: 3),
        SeverityBand(label: "Extreme limitation", lowerBound: 70, level: 4),
    ]

    /// Conventional 0–10 pain-rating bands (none, 1–3, 4–6, 7–10).
    static let pegBands = [
        SeverityBand(label: "No pain or interference", lowerBound: 0, level: 0),
        SeverityBand(label: "Mild", lowerBound: 1, level: 1),
        SeverityBand(label: "Moderate", lowerBound: 40, level: 2),
        SeverityBand(label: "Severe", lowerBound: 70, level: 3),
    ]

    static let sectionInstructions = """
        Each section has six statements. Pick the one that best describes you today. \
        If two seem to fit, pick the one closest to your situation. \
        The result is a score from 0% (no limitation) to 100% (completely limited).
        """

    // MARK: Instruments

    public static let neckDisabilityIndex = Instrument(
        id: "ndi",
        name: "Neck Disability Index",
        shortName: "NDI",
        region: .neck,
        summary: "The most widely used questionnaire for how neck pain affects everyday life: 10 sections, scored 0–50 and shown as a percentage.",
        instructions: sectionInstructions,
        items: [
            SectionLibrary.painIntensity("neck"),
            SectionLibrary.personalCare("washing, dressing, etc."),
            SectionLibrary.lifting("neck"),
            SectionLibrary.reading(),
            SectionLibrary.headaches(),
            SectionLibrary.concentration(),
            SectionLibrary.work(),
            SectionLibrary.driving("neck"),
            SectionLibrary.sleeping("neck"),
            SectionLibrary.recreation("neck"),
        ],
        display: .percent,
        bands: ndiBands,
        minimumAnswered: 8,
        meaningfulChange: 10,
        provenance: .validated(citation: "Vernon H, Mior S. The Neck Disability Index: a study of reliability and validity. J Manipulative Physiol Ther. 1991;14(7):409–415."),
        notes: "Section topics, structure and scoring follow the published NDI; statement wording is lightly adapted. The NDI is copyrighted by Howard Vernon; check the author’s licensing terms before distributing it commercially."
    )

    public static let lowBackDisabilityIndex = Instrument(
        id: "back-di",
        name: "Low Back Disability Index",
        shortName: "Back DI",
        region: .lowBack,
        summary: "10 sections on how low back pain affects lifting, walking, sitting, sleep, travel and work. Same format and scoring as the NDI.",
        instructions: sectionInstructions,
        items: [
            SectionLibrary.painIntensity("back"),
            SectionLibrary.personalCare("washing, dressing, etc."),
            SectionLibrary.lifting("back"),
            SectionLibrary.walking(),
            SectionLibrary.sitting(),
            SectionLibrary.standing(),
            SectionLibrary.sleeping("back"),
            SectionLibrary.travelling(),
            SectionLibrary.work(),
            SectionLibrary.recreation("back"),
        ],
        display: .percent,
        bands: regionalBands,
        minimumAnswered: 8,
        meaningfulChange: 10,
        provenance: .custom(modelledOn: "the Neck Disability Index and Oswestry Disability Index"),
        notes: "Use this to follow your own trend over time. Your clinician may ask you to fill in the validated Oswestry Disability Index (ODI) instead; the two are not interchangeable."
    )

    public static let hipDisabilityIndex = Instrument(
        id: "hip-di",
        name: "Hip Disability Index",
        shortName: "Hip DI",
        region: .hip,
        summary: "10 sections on how hip pain affects walking, stairs, sitting, getting up and down, sleep and work. Same format and scoring as the NDI.",
        instructions: sectionInstructions,
        items: [
            SectionLibrary.painIntensity("hip"),
            SectionLibrary.personalCare("washing, dressing, putting on socks and shoes"),
            SectionLibrary.walking(),
            SectionLibrary.stairs(),
            SectionLibrary.sitting(),
            SectionLibrary.standing(),
            SectionLibrary.transfers(),
            SectionLibrary.sleeping("hip"),
            SectionLibrary.work(),
            SectionLibrary.recreation("hip"),
        ],
        display: .percent,
        bands: regionalBands,
        minimumAnswered: 8,
        meaningfulChange: 10,
        provenance: .custom(modelledOn: "the Neck Disability Index"),
        notes: "Use this to follow your own trend over time. Validated hip questionnaires such as HOOS or the Oxford Hip Score are scored differently and are not interchangeable with this index."
    )

    public static let kneeDisabilityIndex = Instrument(
        id: "knee-di",
        name: "Knee Disability Index",
        shortName: "Knee DI",
        region: .knee,
        summary: "10 sections on how knee pain affects walking, stairs, kneeling, standing, getting up and down, sleep and work. Same format and scoring as the NDI.",
        instructions: sectionInstructions,
        items: [
            SectionLibrary.painIntensity("knee"),
            SectionLibrary.personalCare("washing, dressing, putting on socks and shoes"),
            SectionLibrary.walking(),
            SectionLibrary.stairs(),
            SectionLibrary.kneelingSquatting(),
            SectionLibrary.standing(),
            SectionLibrary.transfers(),
            SectionLibrary.sleeping("knee"),
            SectionLibrary.work(),
            SectionLibrary.recreation("knee"),
        ],
        display: .percent,
        bands: regionalBands,
        minimumAnswered: 8,
        meaningfulChange: 10,
        provenance: .custom(modelledOn: "the Neck Disability Index"),
        notes: "Use this to follow your own trend over time. Validated knee questionnaires such as KOOS or the Oxford Knee Score are scored differently and are not interchangeable with this index."
    )

    public static let shoulderDisabilityIndex = Instrument(
        id: "shoulder-di",
        name: "Shoulder Disability Index",
        shortName: "Shoulder DI",
        region: .shoulder,
        summary: "10 sections on how shoulder pain affects reaching, lifting, carrying, sleep, driving and work. Same format and scoring as the NDI.",
        instructions: sectionInstructions,
        items: [
            SectionLibrary.painIntensity("shoulder"),
            SectionLibrary.personalCare("washing, dressing, doing your hair"),
            SectionLibrary.reachingOverhead(),
            SectionLibrary.reachingBehind(),
            SectionLibrary.lifting("shoulder"),
            SectionLibrary.carrying(),
            SectionLibrary.sleeping("shoulder"),
            SectionLibrary.driving("shoulder"),
            SectionLibrary.work(),
            SectionLibrary.recreation("shoulder"),
        ],
        display: .percent,
        bands: regionalBands,
        minimumAnswered: 8,
        meaningfulChange: 10,
        provenance: .custom(modelledOn: "the Neck Disability Index"),
        notes: "Use this to follow your own trend over time. Validated shoulder questionnaires such as SPADI or QuickDASH are scored differently and are not interchangeable with this index."
    )

    /// PEG three-item pain scale. Public domain.
    public static let peg = Instrument(
        id: "peg",
        name: "PEG Pain Scale",
        shortName: "PEG",
        region: .general,
        summary: "Three quick 0–10 ratings of Pain, Enjoyment of life and General activity over the past week. Works for any chronic pain condition: fibromyalgia, migraine, arthritis, nerve pain and more.",
        instructions: "Think about the past week. For each question, tap the number that best describes you. The score is the average of the three answers, from 0 to 10.",
        items: [
            pegItem(
                "pain",
                "Pain",
                "What number best describes your pain on average in the past week?",
                low: "No pain",
                high: "Pain as bad as you can imagine"
            ),
            pegItem(
                "enjoyment",
                "Enjoyment of life",
                "What number best describes how, during the past week, pain has interfered with your enjoyment of life?",
                low: "Does not interfere",
                high: "Completely interferes"
            ),
            pegItem(
                "general-activity",
                "General activity",
                "What number best describes how, during the past week, pain has interfered with your general activity?",
                low: "Does not interfere",
                high: "Completely interferes"
            ),
        ],
        display: .mean(maximum: 10),
        bands: pegBands,
        minimumAnswered: 3,
        meaningfulChange: 10,
        provenance: .validated(citation: "Krebs EE, Lorenz KA, Bair MJ, et al. Development and initial validation of the PEG, a three-item scale assessing pain intensity and interference. J Gen Intern Med. 2009;24(6):733–738."),
        notes: "The PEG is in the public domain. A 30% drop is often treated as a meaningful improvement for an individual."
    )

    private static func pegItem(_ id: String, _ title: String, _ prompt: String, low: String, high: String) -> InstrumentItem {
        InstrumentItem(
            id: id,
            title: title,
            prompt: prompt,
            options: (0...10).map { ResponseOption(points: $0, text: "\($0)") },
            presentation: .scale(lowLabel: low, highLabel: high)
        )
    }
}
