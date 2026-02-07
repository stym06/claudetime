APP_NAME := ClaudeTime
BUILD_DIR := .build
DIST_DIR := dist
APP_BUNDLE := $(DIST_DIR)/$(APP_NAME).app

.PHONY: build release run clean app dmg

build:
	swift build

release:
	swift build -c release

run:
	swift run

clean:
	swift package clean
	rm -rf $(DIST_DIR)

app: release
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/release/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@echo "Built $(APP_BUNDLE)"

dmg: app
	hdiutil create -volname $(APP_NAME) \
		-srcfolder $(DIST_DIR) \
		-ov -format UDZO \
		$(DIST_DIR)/$(APP_NAME).dmg
	@echo "Built $(DIST_DIR)/$(APP_NAME).dmg"
