# Aura — build & release automation
#
# Version lives in pubspec.yaml as `version: NAME+BUILD` (e.g. 1.0.0+8).
#   NAME  = marketing version (CFBundleShortVersionString / versionName)
#   BUILD = build number       (CFBundleVersion / versionCode)
#
# Common flows:
#   make dist          # bump build, then build Android (aab+apk) + iOS (ipa)
#   make android       # bump build, then build app bundle + apk
#   make ios           # bump build, then build ipa
#   make bump-build    # just increment the build number
#   make version       # print the current version

# Override to use fvm, etc:  make apk FLUTTER="fvm flutter"
FLUTTER ?= flutter
PUBSPEC  := pubspec.yaml

# Parsed once per invocation (recipes that bump re-read the file at runtime).
VERSION      := $(shell grep '^version:' $(PUBSPEC) | sed 's/version: *//')
VERSION_NAME := $(firstword $(subst +, ,$(VERSION)))
BUILD_NUMBER := $(word 2,$(subst +, ,$(VERSION)))

.DEFAULT_GOAL := help

# --- meta -------------------------------------------------------------------

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

.PHONY: version
version: ## Print current version (name + build)
	@echo "$(VERSION)  (name=$(VERSION_NAME), build=$(BUILD_NUMBER))"

.PHONY: get
get: ## flutter pub get
	@$(FLUTTER) pub get

.PHONY: clean
clean: ## flutter clean
	@$(FLUTTER) clean

# --- version bumping --------------------------------------------------------
# sed -i.bak is portable across BSD (macOS) and GNU sed.

.PHONY: bump-build
bump-build: ## Increment the build number (NAME+BUILD -> NAME+BUILD+1)
	@new=$$(( $(BUILD_NUMBER) + 1 )); \
	sed -i.bak "s/^version: .*/version: $(VERSION_NAME)+$$new/" $(PUBSPEC) && rm -f $(PUBSPEC).bak; \
	echo "build: $(BUILD_NUMBER) -> $$new  ($(VERSION_NAME)+$$new)"

.PHONY: bump-patch
bump-patch: ## Bump patch version (x.y.Z), reset nothing, keep build
	@$(call _bump_name,3)

.PHONY: bump-minor
bump-minor: ## Bump minor version (x.Y.0)
	@$(call _bump_name,2)

.PHONY: bump-major
bump-major: ## Bump major version (X.0.0)
	@$(call _bump_name,1)

# $(1) = which semver field to bump (1=major,2=minor,3=patch)
define _bump_name
	name="$(VERSION_NAME)"; build="$(BUILD_NUMBER)"; \
	maj=$$(echo $$name | cut -d. -f1); \
	min=$$(echo $$name | cut -d. -f2); \
	pat=$$(echo $$name | cut -d. -f3); \
	case $(1) in \
	  1) maj=$$((maj+1)); min=0; pat=0;; \
	  2) min=$$((min+1)); pat=0;; \
	  3) pat=$$((pat+1));; \
	esac; \
	newname="$$maj.$$min.$$pat"; \
	sed -i.bak "s/^version: .*/version: $$newname+$$build/" $(PUBSPEC) && rm -f $(PUBSPEC).bak; \
	echo "name: $(VERSION_NAME) -> $$newname  ($$newname+$$build)"
endef

# --- Android ----------------------------------------------------------------

.PHONY: aab
aab: ## Build Android App Bundle (release) — for Play Store
	@$(FLUTTER) build appbundle --release
	@echo "→ build/app/outputs/bundle/release/app-release.aab"

.PHONY: apk
apk: ## Build Android APK (release) — for sideload / direct install
	@$(FLUTTER) build apk --release
	@echo "→ build/app/outputs/flutter-apk/app-release.apk"

.PHONY: android
android: bump-build aab apk ## Bump build, then build Android aab + apk

# --- iOS --------------------------------------------------------------------

.PHONY: ipa
ipa: ## Build signed iOS .ipa (release) — for App Store / TestFlight
	@$(FLUTTER) build ipa --release
	@echo "→ build/ios/ipa/  (open in Transporter or: xcrun altool / fastlane to upload)"

.PHONY: ios
ios: bump-build ipa ## Bump build, then build iOS ipa

# --- both -------------------------------------------------------------------

.PHONY: dist
dist: bump-build aab apk ipa ## Bump build once, then build Android + iOS distributables
	@echo "Distribution build complete for build $(shell grep '^version:' $(PUBSPEC) | sed 's/version: *//')"
