import Foundation

struct TapGuideStep {
    let titleKey: String.LocalizationValue
    let bodyKey: String.LocalizationValue
}

let tapGuideSteps: [TapGuideStep] = [
    TapGuideStep(titleKey: "tap_guide.step1_title", bodyKey: "tap_guide.step1_body"),
    TapGuideStep(titleKey: "tap_guide.step2_title", bodyKey: "tap_guide.step2_body"),
    TapGuideStep(titleKey: "tap_guide.step3_title", bodyKey: "tap_guide.step3_body"),
    TapGuideStep(titleKey: "tap_guide.step4_title", bodyKey: "tap_guide.step4_body"),
    TapGuideStep(titleKey: "tap_guide.step5_title", bodyKey: "tap_guide.step5_body"),
]
