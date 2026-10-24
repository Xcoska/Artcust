# Pain Tracker

An iOS app for tracking chronic pain with standard disability questionnaires. It starts with the
**Neck Disability Index (NDI)** and adds matching indexes for the **hip**, **low back**, **knee** and
**shoulder**, plus the **PEG** scale for any other chronic pain condition (fibromyalgia, migraine,
arthritis, nerve pain…).

## Features

- **Track several conditions** at once, each with its own questionnaire.
- **One-question-per-screen questionnaires** with a progress bar, "not applicable" handling
  (e.g. Driving on the NDI), and a review screen before saving.
- **Standard scoring**: 0–100% with severity bands, raw score (e.g. 18/50), and NDI-style handling
  of skipped sections (the maximum is reduced instead of counting them as zero).
- **Trends**: change since last time and since your baseline, marked as a meaningful improvement,
  a meaningful worsening, or normal variation.
- **Charts** (Swift Charts) of questionnaire scores and daily pain over time.
- **Quick daily pain log**: 0–10 rating, flare-up flag and notes on triggers or medication.
- **Weekly reminders** per condition (local notifications).
- **CSV export** of all results and pain logs to share with a clinician.
- All data stays on the device (SwiftData). No account and no network access.

## Questionnaires

| Region | Questionnaire | Items | Score | Status |
| --- | --- | --- | --- | --- |
| Neck | Neck Disability Index (NDI) | 10 × 0–5 | 0–100% | Validated (Vernon & Mior 1991) |
| Low back | Low Back Disability Index | 10 × 0–5 | 0–100% | Custom, NDI/ODI format |
| Hip | Hip Disability Index | 10 × 0–5 | 0–100% | Custom, NDI format |
| Knee | Knee Disability Index | 10 × 0–5 | 0–100% | Custom, NDI format |
| Shoulder | Shoulder Disability Index | 10 × 0–5 | 0–100% | Custom, NDI format |
| Any | PEG (Pain, Enjoyment, General activity) | 3 × 0–10 | mean 0–10 | Validated (Krebs et al. 2009), public domain |

The hip, back, knee and shoulder indexes use the same 10-section, six-statement format and scoring as
the NDI so that scores look and feel the same across body regions. They are **not validated
instruments**. They work well for following one person's trend, but they cannot be compared with
published norms. The app says this wherever those indexes appear.

### Licensing note

The NDI is copyrighted by Howard Vernon. The app uses the NDI's section topics, structure and scoring
with lightly adapted wording. **Check the author's licensing terms before publishing this app
commercially.** The same applies if you add other licensed instruments, such as the Oswestry
Disability Index, HOOS/KOOS, the Oxford Hip/Knee Scores or the Brief Pain Inventory.

## Project layout

```
App/                       SwiftUI app (iOS 17+, SwiftData, Swift Charts)
  Models/                  TrackedCondition, AssessmentRecord, PainLogEntry
  Views/                   Screens and shared components
  Services/                Notification reminders, CSV export
  Resources/               Asset catalog (app icon, accent colour)
Packages/PainTrackerKit/   Questionnaire definitions, scoring, trends, CSV (no UI; unit-tested)
project.yml                XcodeGen spec that generates PainTracker.xcodeproj
```

## Building

Requirements: macOS with Xcode 15 or later, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate          # creates PainTracker.xcodeproj
open PainTracker.xcodeproj
```

Pick an iPhone simulator and press Run. To run on your own iPhone, choose your team under
*Signing & Capabilities* and change the bundle identifier (`com.example.paintracker`) in `project.yml`.

Run the scoring tests:

```sh
cd Packages/PainTrackerKit
swift test
```

CI (`.github/workflows/ci.yml`) runs the package tests and builds the app for the iOS Simulator on
every push.

## Adding a questionnaire

Questionnaires are data. To add one, define an `Instrument` in
`Packages/PainTrackerKit/Sources/PainTrackerKit/InstrumentCatalog.swift`. You can build it from
`SectionLibrary` sections or from your own `InstrumentItem`s. Then add it to `InstrumentCatalog.all`.
The catalog tests check it automatically (unique IDs, contiguous option points, a reachable minimum
number of answers).

## Disclaimer

Scores are for personal tracking and are not a diagnosis or medical advice.
