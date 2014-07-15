#ifndef QZXING_PLUGIN_H
#define QZXING_PLUGIN_H

#define QZXING_PLUGIN_QML_NAME "QZXing"

#include <QQmlEngine>
#include <QQmlExtensionPlugin>

class QZXingPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);
    void initializeEngine(QQmlEngine *engine, const char *uri);
};

#endif // QZXING_PLUGIN_H
