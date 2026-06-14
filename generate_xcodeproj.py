#!/usr/bin/env python3
"""Generate TossUp.xcodeproj/project.pbxproj."""

from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT / "TossUp.xcodeproj" / "project.pbxproj"

SOURCES = [
    "TossUp/TossUpApp.swift",
    "TossUp/Models/NSBQuestion.swift",
    "TossUp/Models/PersistenceModels.swift",
    "TossUp/Services/AnswerNormalizer.swift",
    "TossUp/Services/PDFParser.swift",
    "TossUp/Services/QuestionBank.swift",
    "TossUp/Services/SettingsStore.swift",
    "TossUp/ViewModels/QuizViewModel.swift",
    "TossUp/ViewModels/ProgressViewModel.swift",
    "TossUp/Views/RootView.swift",
    "TossUp/Views/StudyView.swift",
    "TossUp/Views/QuizTabView.swift",
    "TossUp/Views/QuizSessionView.swift",
    "TossUp/Views/ProgressTabView.swift",
    "TossUp/Views/SettingsTabView.swift",
    "TossUp/Views/Components/SharedComponents.swift",
]

TESTS = ["TossUpTests/ParserTests.swift"]

RESOURCES = [
    "TossUp/Assets.xcassets",
    "NSB_PDFs",
]

def uid(prefix: str, index: int) -> str:
    return f"TU{prefix}{index:03d}"

PROJECT_ID = "TUP000"
CONTAINER_PROXY_ID = "TUX001"


def main() -> None:
    lines = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        "",
        "/* Begin PBXBuildFile section */",
    ]

    build_files = []
    file_refs = []
    source_phase = []
    resource_phase = []
    test_build_files = []
    test_sources = []

    idx = 1
    for path in SOURCES:
        name = Path(path).name
        bf, fr = uid("B", idx), uid("F", idx)
        idx += 1
        build_files.append(f"\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};")
        file_refs.append(f"\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
        source_phase.append(f"\t\t\t{bf} /* {name} in Sources */,")

    idx_r = 100
    for path in RESOURCES:
        name = Path(path).name
        bf, fr = uid("B", idx_r), uid("F", idx_r)
        idx_r += 1
        last_type = "folder.assetcatalog" if name.endswith(".xcassets") else "folder"
        path_attr = path.replace("TossUp/", "", 1) if path.startswith("TossUp/") else name
        if "Resources/" in path:
            path_attr = "Resources/" + name
        build_files.append(f"\t\t{bf} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};")
        file_refs.append(f"\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {last_type}; path = {path_attr if 'Resources/' in path else name}; sourceTree = \"<group>\"; }};")
        resource_phase.append(f"\t\t\t{bf} /* {name} in Resources */,")

    idx_t = 200
    for path in TESTS:
        name = Path(path).name
        bf, fr = uid("B", idx_t), uid("F", idx_t)
        idx_t += 1
        test_build_files.append(f"\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};")
        file_refs.append(f"\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
        test_sources.append(f"\t\t\t{bf} /* {name} in Sources */,")

    lines.extend(build_files)
    lines.extend(test_build_files)
    lines.extend([
        "/* End PBXBuildFile section */",
        "",
        "/* Begin PBXFileReference section */",
        f"\t\t{uid('F', 900)} /* TossUp.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TossUp.app; sourceTree = BUILT_PRODUCTS_DIR; }};",
        f"\t\t{uid('F', 901)} /* TossUpTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TossUpTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};",
    ])
    lines.extend(file_refs)
    lines.extend([
        "/* End PBXFileReference section */",
        "",
        "/* Begin PBXFrameworksBuildPhase section */",
        f"\t\t{uid('P', 1)} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};",
        f"\t\t{uid('P', 2)} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};",
        "/* End PBXFrameworksBuildPhase section */",
        "",
        "/* Begin PBXGroup section */",
        f"\t\t{uid('G', 1)} = {{isa = PBXGroup; children = ({uid('G', 2)} /* TossUp */, {uid('G', 3)} /* TossUpTests */, {uid('G', 4)} /* Products */); sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 2)} /* TossUp */ = {{isa = PBXGroup; children = ({uid('F', 1)}, {uid('G', 10)} /* Models */, {uid('G', 11)} /* Services */, {uid('G', 12)} /* ViewModels */, {uid('G', 13)} /* Views */, {uid('G', 15)} /* Resources */, {uid('F', 100)} /* Assets.xcassets */); path = TossUp; sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 15)} /* Resources */ = {{isa = PBXGroup; children = ({uid('F', 101)} /* NSB_PDFs */); path = Resources; sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 3)} /* TossUpTests */ = {{isa = PBXGroup; children = ({uid('F', 200)} /* ParserTests.swift */); path = TossUpTests; sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 4)} /* Products */ = {{isa = PBXGroup; children = ({uid('F', 900)} /* TossUp.app */, {uid('F', 901)} /* TossUpTests.xctest */); name = Products; sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 10)} /* Models */ = {{isa = PBXGroup; children = ({uid('F', 2)}, {uid('F', 3)}); path = Models; sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 11)} /* Services */ = {{isa = PBXGroup; children = ({uid('F', 4)}, {uid('F', 5)}, {uid('F', 6)}, {uid('F', 7)}); path = Services; sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 12)} /* ViewModels */ = {{isa = PBXGroup; children = ({uid('F', 8)}, {uid('F', 9)}); path = ViewModels; sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 13)} /* Views */ = {{isa = PBXGroup; children = ({uid('G', 14)} /* Components */, {uid('F', 10)}, {uid('F', 11)}, {uid('F', 12)}, {uid('F', 13)}, {uid('F', 14)}, {uid('F', 15)}); path = Views; sourceTree = \"<group>\"; }};",
        f"\t\t{uid('G', 14)} /* Components */ = {{isa = PBXGroup; children = ({uid('F', 16)}); path = Components; sourceTree = \"<group>\"; }};",
        "/* End PBXGroup section */",
        "",
        "/* Begin PBXNativeTarget section */",
        f"\t\t{uid('T', 1)} /* TossUp */ = {{isa = PBXNativeTarget; buildConfigurationList = {uid('C', 3)}; buildPhases = ({uid('E', 1)} /* Sources */, {uid('P', 1)} /* Frameworks */, {uid('E', 2)} /* Resources */); buildRules = (); dependencies = (); name = TossUp; productName = TossUp; productReference = {uid('F', 900)}; productType = \"com.apple.product-type.application\"; }};",
        f"\t\t{uid('T', 2)} /* TossUpTests */ = {{isa = PBXNativeTarget; buildConfigurationList = {uid('C', 4)}; buildPhases = ({uid('E', 3)} /* Sources */, {uid('P', 2)} /* Frameworks */, {uid('E', 4)} /* Resources */); buildRules = (); dependencies = ({uid('D', 1)}); name = TossUpTests; productName = TossUpTests; productReference = {uid('F', 901)}; productType = \"com.apple.product-type.bundle.unit-test\"; }};",
        "/* End PBXNativeTarget section */",
        "",
        "/* Begin PBXContainerItemProxy section */",
        f"\t\t{CONTAINER_PROXY_ID} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {PROJECT_ID}; proxyType = 1; remoteGlobalIDString = {uid('T', 1)}; remoteInfo = TossUp; }};",
        "/* End PBXContainerItemProxy section */",
        "",
        "/* Begin PBXTargetDependency section */",
        f"\t\t{uid('D', 1)} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {uid('T', 1)}; targetProxy = {CONTAINER_PROXY_ID}; }};",
        "/* End PBXTargetDependency section */",
        "",
        "/* Begin PBXProject section */",
        f"\t\t{PROJECT_ID} /* Project object */ = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1500; LastUpgradeCheck = 1500; TargetAttributes = {{{uid('T', 2)} = {{CreatedOnToolsVersion = 15.0; TestTargetID = {uid('T', 1)}; }}; }}; }}; buildConfigurationList = {uid('C', 1)}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {uid('G', 1)}; productRefGroup = {uid('G', 4)}; projectDirPath = \"\"; projectRoot = \"\"; targets = ({uid('T', 1)}, {uid('T', 2)}); }};",
        "/* End PBXProject section */",
        "",
        "/* Begin PBXResourcesBuildPhase section */",
        f"\t\t{uid('E', 2)} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (",
        *resource_phase,
        "\t\t); runOnlyForDeploymentPostprocessing = 0; }};",
        f"\t\t{uid('E', 4)} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};",
        "/* End PBXResourcesBuildPhase section */",
        "",
        "/* Begin PBXSourcesBuildPhase section */",
        f"\t\t{uid('E', 1)} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (",
        *source_phase,
        "\t\t); runOnlyForDeploymentPostprocessing = 0; }};",
        f"\t\t{uid('E', 3)} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (",
        *test_sources,
        "\t\t); runOnlyForDeploymentPostprocessing = 0; }};",
        "/* End PBXSourcesBuildPhase section */",
        "",
        "/* Begin XCBuildConfiguration section */",
        f"\t\t{uid('C', 5)} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = dwarf; ENABLE_TESTABILITY = YES; GCC_OPTIMIZATION_LEVEL = 0; IPHONEOS_DEPLOYMENT_TARGET = 16.0; MACOSX_DEPLOYMENT_TARGET = 13.0; ONLY_ACTIVE_ARCH = YES; SDKROOT = auto; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; SWIFT_OPTIMIZATION_LEVEL = \"-Onone\"; }}; name = Debug; }};",
        f"\t\t{uid('C', 6)} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\"; ENABLE_NS_ASSERTIONS = NO; GCC_OPTIMIZATION_LEVEL = s; IPHONEOS_DEPLOYMENT_TARGET = 16.0; MACOSX_DEPLOYMENT_TARGET = 13.0; SDKROOT = auto; SWIFT_COMPILATION_MODE = wholemodule; VALIDATE_PRODUCT = YES; }}; name = Release; }};",
        f"\t\t{uid('C', 7)} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; ENABLE_HARDENED_RUNTIME = YES; ENABLE_PREVIEWS = YES; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = TossUp; INFOPLIST_KEY_LSMinimumSystemVersion = 13.0; INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES; IPHONEOS_DEPLOYMENT_TARGET = 16.0; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\"); MACOSX_DEPLOYMENT_TARGET = 13.0; MARKETING_VERSION = 1.0; PRODUCT_BUNDLE_IDENTIFIER = com.tossup.nsb; PRODUCT_NAME = \"$(TARGET_NAME)\"; SDKROOT = auto; SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator macosx\"; SUPPORTS_MACCATALYST = NO; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = \"1,2\"; }}; name = Debug; }};",
        f"\t\t{uid('C', 8)} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; ENABLE_HARDENED_RUNTIME = YES; ENABLE_PREVIEWS = YES; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = TossUp; INFOPLIST_KEY_LSMinimumSystemVersion = 13.0; INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES; IPHONEOS_DEPLOYMENT_TARGET = 16.0; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\"); MACOSX_DEPLOYMENT_TARGET = 13.0; MARKETING_VERSION = 1.0; PRODUCT_BUNDLE_IDENTIFIER = com.tossup.nsb; PRODUCT_NAME = \"$(TARGET_NAME)\"; SDKROOT = auto; SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator macosx\"; SUPPORTS_MACCATALYST = NO; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = \"1,2\"; }}; name = Release; }};",
        f"\t\t{uid('C', 9)} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{BUNDLE_LOADER = \"$(TEST_HOST)\"; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = YES; IPHONEOS_DEPLOYMENT_TARGET = 16.0; MACOSX_DEPLOYMENT_TARGET = 13.0; MARKETING_VERSION = 1.0; PRODUCT_BUNDLE_IDENTIFIER = com.tossup.nsb.tests; PRODUCT_NAME = \"$(TARGET_NAME)\"; SDKROOT = auto; SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator macosx\"; SWIFT_VERSION = 5.0; TEST_HOST = \"$(BUILT_PRODUCTS_DIR)/TossUp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TossUp\"; }}; name = Debug; }};",
        f"\t\t{uid('C', 10)} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{BUNDLE_LOADER = \"$(TEST_HOST)\"; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = YES; IPHONEOS_DEPLOYMENT_TARGET = 16.0; MACOSX_DEPLOYMENT_TARGET = 13.0; MARKETING_VERSION = 1.0; PRODUCT_BUNDLE_IDENTIFIER = com.tossup.nsb.tests; PRODUCT_NAME = \"$(TARGET_NAME)\"; SDKROOT = auto; SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator macosx\"; SWIFT_VERSION = 5.0; TEST_HOST = \"$(BUILT_PRODUCTS_DIR)/TossUp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TossUp\"; }}; name = Release; }};",
        "/* End XCBuildConfiguration section */",
        "",
        "/* Begin XCConfigurationList section */",
        f"\t\t{uid('C', 1)} /* Build configuration list for PBXProject */ = {{isa = XCConfigurationList; buildConfigurations = ({uid('C', 5)}, {uid('C', 6)}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        f"\t\t{uid('C', 3)} /* Build configuration list for PBXNativeTarget TossUp */ = {{isa = XCConfigurationList; buildConfigurations = ({uid('C', 7)}, {uid('C', 8)}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        f"\t\t{uid('C', 4)} /* Build configuration list for PBXNativeTarget TossUpTests */ = {{isa = XCConfigurationList; buildConfigurations = ({uid('C', 9)}, {uid('C', 10)}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        "/* End XCConfigurationList section */",
        "\t};",
        f"\trootObject = {PROJECT_ID} /* Project object */;",
        "}",
    ])

    PROJECT.write_text("\n".join(lines) + "\n")
    print(f"Wrote {PROJECT}")


if __name__ == "__main__":
    main()
