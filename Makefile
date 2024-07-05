
install:
	swift build -c release
	cp -f .build/release/swiftpm-settings-acknowledgements /usr/local/bin