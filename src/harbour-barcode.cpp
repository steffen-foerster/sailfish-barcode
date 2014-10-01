#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QGuiApplication>
#include <QQuickView>
#include <QtQml>
#include <QDebug>

#include "scanner/BarcodeDecoder.h"
#include "scanner/AutoBarcodeScanner.h"
#include "scanner/CaptureImageProvider.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    qmlRegisterType<AutoBarcodeScanner>("harbour.barcode.AutoBarcodeScanner", 1, 0, "AutoBarcodeScanner");

    view->engine()->addImageProvider("scanner", new CaptureImageProvider());
    view->setSource(SailfishApp::pathTo("qml/harbour-barcode.qml"));
    view->showFullScreen();

    return app->exec();
}
