import Foundation

/// Building blocks for the six-statement (0–5 points) sections used by the
/// NDI and the region-specific indexes modelled on it.
enum SectionLibrary {
    static let defaultPrompt = "Choose the one statement that best describes you today."

    static func section(
        _ id: String,
        _ title: String,
        prompt: String = defaultPrompt,
        allowsNotApplicable: Bool = false,
        _ statements: [String]
    ) -> InstrumentItem {
        precondition(statements.count == 6, "Sections have six statements scored 0–5")
        return InstrumentItem(
            id: id,
            title: title,
            prompt: prompt,
            options: statements.enumerated().map { ResponseOption(points: $0.offset, text: $0.element) },
            allowsNotApplicable: allowsNotApplicable
        )
    }

    // MARK: Shared sections

    static func painIntensity(_ part: String) -> InstrumentItem {
        section("pain-intensity", "Pain intensity", prompt: "How strong is your \(part) pain at the moment?", [
            "I have no pain at the moment.",
            "The pain is very mild at the moment.",
            "The pain is moderate at the moment.",
            "The pain is fairly severe at the moment.",
            "The pain is very severe at the moment.",
            "The pain is the worst I can imagine at the moment.",
        ])
    }

    static func personalCare(_ examples: String) -> InstrumentItem {
        section("personal-care", "Personal care", prompt: "Looking after yourself (\(examples)).", [
            "I can look after myself normally without causing extra pain.",
            "I can look after myself normally, but it causes extra pain.",
            "Looking after myself is painful, and I am slow and careful.",
            "I need some help, but manage most of my personal care.",
            "I need help every day with most aspects of looking after myself.",
            "I cannot get dressed, I wash with difficulty and I stay in bed.",
        ])
    }

    static func lifting(_ part: String) -> InstrumentItem {
        section("lifting", "Lifting", prompt: "Lifting objects, and how your \(part) pain affects it.", [
            "I can lift heavy objects without extra pain.",
            "I can lift heavy objects, but it gives me extra pain.",
            "Pain stops me lifting heavy objects off the floor, but I can manage if they are conveniently placed (e.g. on a table).",
            "Pain stops me lifting heavy objects, but I can manage light to medium objects if they are conveniently placed.",
            "I can lift only very light objects.",
            "I cannot lift or carry anything at all.",
        ])
    }

    static func sleeping(_ part: String) -> InstrumentItem {
        section("sleeping", "Sleeping", prompt: "How much does your \(part) pain disturb your sleep?", [
            "I have no trouble sleeping because of pain.",
            "My sleep is slightly disturbed (less than 1 hour awake).",
            "My sleep is mildly disturbed (1–2 hours awake).",
            "My sleep is moderately disturbed (2–3 hours awake).",
            "My sleep is greatly disturbed (3–5 hours awake).",
            "My sleep is completely disturbed (5–7 hours awake).",
        ])
    }

    static func work() -> InstrumentItem {
        section("work", "Work", prompt: "Your usual work, paid or unpaid, including housework.", [
            "I can do as much work as I want to.",
            "I can do my usual work, but no more.",
            "I can do most of my usual work, but no more.",
            "I cannot do my usual work.",
            "I can hardly do any work at all.",
            "I cannot do any work at all.",
        ])
    }

    static func recreation(_ part: String) -> InstrumentItem {
        section("recreation", "Recreation & social life", prompt: "Hobbies, sport, going out and seeing people.", [
            "I can do all my usual recreational and social activities with no \(part) pain.",
            "I can do all my usual recreational and social activities with some \(part) pain.",
            "Pain stops me doing some of my usual recreational and social activities.",
            "Pain stops me doing most of my usual recreational and social activities.",
            "I can hardly do any recreational or social activities because of pain.",
            "I cannot do any recreational or social activities at all.",
        ])
    }

    static func driving(_ part: String) -> InstrumentItem {
        section("driving", "Driving", prompt: "Mark “not applicable” if you don’t drive.", allowsNotApplicable: true, [
            "I can drive as long as I want with no \(part) pain.",
            "I can drive as long as I want with slight \(part) pain.",
            "I can drive as long as I want with moderate \(part) pain.",
            "I can’t drive as long as I want because of moderate \(part) pain.",
            "I can hardly drive at all because of severe \(part) pain.",
            "I can’t drive at all.",
        ])
    }

    static func walking() -> InstrumentItem {
        section("walking", "Walking", [
            "Pain does not stop me walking any distance.",
            "Pain stops me walking more than about 1.5 km (1 mile).",
            "Pain stops me walking more than about 750 m (½ mile).",
            "Pain stops me walking more than about 100 m (100 yards).",
            "I can only walk using a stick, cane or crutches.",
            "I am in bed or a chair most of the time.",
        ])
    }

    static func sitting() -> InstrumentItem {
        section("sitting", "Sitting", [
            "I can sit in any chair for as long as I like.",
            "I can sit in my favourite chair for as long as I like.",
            "Pain stops me sitting for more than 1 hour.",
            "Pain stops me sitting for more than 30 minutes.",
            "Pain stops me sitting for more than 10 minutes.",
            "Pain stops me sitting at all.",
        ])
    }

    static func standing() -> InstrumentItem {
        section("standing", "Standing", [
            "I can stand for as long as I want without extra pain.",
            "I can stand for as long as I want, but it gives me extra pain.",
            "Pain stops me standing for more than 1 hour.",
            "Pain stops me standing for more than 30 minutes.",
            "Pain stops me standing for more than 10 minutes.",
            "Pain stops me standing at all.",
        ])
    }

    static func stairs() -> InstrumentItem {
        section("stairs", "Stairs", [
            "I can go up and down stairs normally without pain.",
            "I can go up and down stairs normally, but it causes some pain.",
            "I need a handrail or have to go slowly because of pain.",
            "I can only manage stairs one step at a time.",
            "I can manage only a few steps, with great difficulty.",
            "I cannot use stairs at all.",
        ])
    }

    static func transfers() -> InstrumentItem {
        section("transfers", "Getting up & down", prompt: "Getting in and out of a chair, bed or car.", [
            "I can get in and out of chairs, bed and the car normally without pain.",
            "I can get in and out normally, but it causes some pain.",
            "I have to move slowly and carefully because of pain.",
            "I need to push up with my arms or hold on to something.",
            "I sometimes need help from another person.",
            "I cannot get in or out of a chair, bed or car without help.",
        ])
    }

    // MARK: Neck-specific

    static func reading() -> InstrumentItem {
        section("reading", "Reading", prompt: "Reading, including screens.", [
            "I can read as much as I want with no neck pain.",
            "I can read as much as I want with slight neck pain.",
            "I can read as much as I want with moderate neck pain.",
            "I can’t read as much as I want because of moderate neck pain.",
            "I can hardly read at all because of severe neck pain.",
            "I cannot read at all.",
        ])
    }

    static func headaches() -> InstrumentItem {
        section("headaches", "Headaches", [
            "I have no headaches at all.",
            "I have slight headaches that come infrequently.",
            "I have moderate headaches that come infrequently.",
            "I have moderate headaches that come frequently.",
            "I have severe headaches that come frequently.",
            "I have headaches almost all the time.",
        ])
    }

    static func concentration() -> InstrumentItem {
        section("concentration", "Concentration", [
            "I can concentrate fully whenever I want with no difficulty.",
            "I can concentrate fully whenever I want with slight difficulty.",
            "I have a fair amount of difficulty concentrating when I want to.",
            "I have a lot of difficulty concentrating when I want to.",
            "I have a great deal of difficulty concentrating when I want to.",
            "I cannot concentrate at all.",
        ])
    }

    // MARK: Low back-specific

    static func travelling() -> InstrumentItem {
        section("travelling", "Travelling", prompt: "Journeys by car, bus, train or plane.", [
            "I can travel anywhere without pain.",
            "I can travel anywhere, but it gives me extra pain.",
            "Pain is bad, but I can manage journeys of over 2 hours.",
            "Pain restricts me to journeys of less than 1 hour.",
            "Pain restricts me to short necessary journeys of under 30 minutes.",
            "Pain stops me travelling except to receive treatment.",
        ])
    }

    // MARK: Knee-specific

    static func kneelingSquatting() -> InstrumentItem {
        section("kneeling-squatting", "Kneeling & squatting", [
            "I can kneel and squat normally without pain.",
            "I can kneel and squat normally, but it causes some pain.",
            "I can kneel and squat only slowly or with support.",
            "I can only go partway down.",
            "I can hardly kneel or squat at all.",
            "I cannot kneel or squat at all.",
        ])
    }

    // MARK: Shoulder-specific

    static func reachingOverhead() -> InstrumentItem {
        section("reaching-overhead", "Reaching overhead", prompt: "Reaching up, e.g. to a high shelf or to wash your hair.", [
            "I can reach overhead normally without pain.",
            "I can reach overhead normally, but it causes some pain.",
            "I can reach overhead, but only slowly because of pain.",
            "I can only reach part of the way up.",
            "I can barely lift my arm to shoulder height.",
            "I cannot raise my arm at all.",
        ])
    }

    static func reachingBehind() -> InstrumentItem {
        section("reaching-behind", "Reaching behind your back", prompt: "E.g. tucking in a shirt, fastening clothing or reaching a back pocket.", [
            "I can reach behind my back normally without pain.",
            "I can reach behind my back normally, but it causes some pain.",
            "I can reach behind my back, but only slowly and carefully.",
            "I can only reach part of the way.",
            "I can barely reach behind my back.",
            "I cannot reach behind my back at all.",
        ])
    }

    static func carrying() -> InstrumentItem {
        section("carrying", "Carrying", prompt: "Carrying with the affected arm.", [
            "I can carry a heavy bag (e.g. shopping) without pain.",
            "I can carry a heavy bag, but it causes some pain.",
            "I can only carry a medium-weight bag.",
            "I can only carry a light bag.",
            "I can only carry very light items.",
            "I cannot carry anything with the affected arm.",
        ])
    }
}
