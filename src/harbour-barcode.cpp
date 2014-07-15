#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QGuiApplication>
#include <QQuickView>
#include <QtQml>
#include <QDebug>

#include "scanner/BarcodeDecoder.h"
#include "scanner/BarcodeScanner.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    qmlRegisterType<BarcodeScanner>("harbour.barcode.BarcodeScanner", 1, 0, "BarcodeScanner");

    view->setSource(SailfishApp::pathTo("qml/harbour-barcode.qml"));
    view->showFullScreen();

    return app->exec();
}
