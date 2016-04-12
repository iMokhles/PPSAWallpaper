GO_EASY_ON_ME = 1

DEBUG = 0

THEOS_DEVICE_IP = localhost

ARCHS = armv7 armv7s arm64

TARGET = iphone:clang:8.1:9.0

ADDITIONAL_LDFLAGS = -Wl,-segalign,4000
ADDITIONAL_CFLAGS = -fobjc-arc

THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = PhotosPopSetAsWallpaper
PhotosPopSetAsWallpaper_FILES = Tweak.xm
PhotosPopSetAsWallpaper_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore CoreImage Accelerate AVFoundation AudioToolbox MobileCoreServices Social Accounts MediaPlayer PhotosUI Photos
PhotosPopSetAsWallpaper_PRIVATE_FRAMEWORKS = PhotoLibrary
PhotosPopSetAsWallpaper_LIBRARIES =  substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Photos"
