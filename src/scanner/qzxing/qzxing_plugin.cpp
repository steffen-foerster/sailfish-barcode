#include <QtQml>
#include "qzxing_plugin.h"
#include "qzxing.h"

void QZXingPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    QQmlExtensionPlugin::initializeEngine(engine, uri);
}

void QZXingPlugin::registerTypes(const char *uri)
{
    // @uri QZXing
    qmlRegisterType<QZXing>(uri, 1, 0, "QXZing");
}
