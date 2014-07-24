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
    concurrent

SOURCES += \
    src/harbour-barcode.cpp \
    src/scanner/ImagePostProcessing.cpp \
    src/scanner/BarcodeScanner.cpp \
    src/scanner/BarcodeDecoder.cpp

OTHER_FILES += \
    qml/cover/CoverPage.qml \
    rpm/harbour-barcode.spec \
    translations/*.ts \
    README.md \
    harbour-barcode.desktop \
    rpm/harbour-barcode.yaml \
    rpm/harbour-barcode.changes.in \
    qml/harbour-barcode.qml \
    qml/pages/ScanPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/AboutPage.qml \
    qml/components/LabelText.qml \
    qml/cover/cover-image.png \
    qml/pages/img/upc_240.png \
    qml/pages/img/qr-code_240.png \
    qml/pages/img/interleaved_240.png \
    qml/pages/img/ean-13_240.png \
    qml/pages/img/datamatrix_240.png \
    qml/pages/img/code-128_240.png \
    qml/pages/img/aztec_240.png

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
#TRANSLATIONS += translations/harbour-barcode-de.ts

# include library qzxing
include(src/scanner/qzxing/QZXing.pri)

HEADERS += \
    src/scanner/ImagePostProcessing.h \
    src/scanner/BarcodeScanner.h \
    src/scanner/BarcodeDecoder.h

