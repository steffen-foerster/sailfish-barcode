# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-barcode

CONFIG += sailfishapp

QT += multimedia \
    concurrent \
    dbus

SOURCES += \
    src/harbour-barcode.cpp \
    src/scanner/ImagePostProcessing.cpp \
    src/scanner/BarcodeDecoder.cpp \
    src/scanner/AutoBarcodeScanner.cpp \
    src/scanner/CaptureImageProvider.cpp

OTHER_FILES += \
    qml/cover/CoverPage.qml \
    rpm/harbour-barcode.spec \
    translations/*.ts \
    README.md \
    harbour-barcode.desktop \
    rpm/harbour-barcode.yaml \
    rpm/harbour-barcode.changes.in \
    qml/harbour-barcode.qml \
    qml/pages/AboutPage.qml \
    qml/components/LabelText.qml \
    qml/cover/cover-image.png \
    qml/pages/img/upc_240.png \
    qml/pages/img/qr-code_240.png \
    qml/pages/img/interleaved_240.png \
    qml/pages/img/ean-13_240.png \
    qml/pages/img/datamatrix_240.png \
    qml/pages/img/code-128_240.png \
    qml/pages/img/aztec_240.png \
    qml/pages/AutoScanPage.qml \
    qml/pages/SettingsPage.qml \
    qml/js/Settings.js \
    qml/js/LocalStore.js \
    qml/pages/TextPage.qml \
    qml/js/History.js \
    qml/components/Settings1View.qml \
    qml/components/Settings2View.qml \
    qml/pages/HistoryPage.qml \
    qml/js/Utils.js


# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
TRANSLATIONS += \
    translations/harbour-barcode-it.ts \
    translations/harbour-barcode-sv.ts \
    translations/harbour-barcode-fr.ts \
    translations/harbour-barcode-de.ts \
    translations/harbour-barcode-hu.ts \
    translations/harbour-barcode-da.ts \
    translations/harbour-barcode-es.ts \
    translations/harbour-barcode-ru.ts \
    translations/harbour-barcode-zh_CN.ts \
    translations/harbour-barcode-zh_TW.ts \
    translations/harbour-barcode-cs_CZ.ts

# include library qzxing
include(src/scanner/qzxing/QZXing.pri)

HEADERS += \
    src/scanner/ImagePostProcessing.h \
    src/scanner/BarcodeDecoder.h \
    src/scanner/AutoBarcodeScanner.h \
    src/scanner/CaptureImageProvider.h

