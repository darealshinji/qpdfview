    /*

Copyright 2018 Marshall Banana
Copyright 2012-2013, 2018 Adam Reichold
Copyright 2014 Dorian Scholz
Copyright 2012 Michał Trybus
Copyright 2013 Chris Young

This file is part of qpdfview.

qpdfview is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

qpdfview is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with qpdfview.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <iostream>

#include <QDebug>
#include <QDir>
#include <QInputDialog>
#include <QLibraryInfo>
#include <QMessageBox>
#include <QScopedPointer>
#include <QTranslator>

#ifdef WITH_DBUS

#include <QDBusInterface>
#include <QDBusReply>

#endif // WITH_DBUS

#ifdef WITH_SYNCTEX

#include <synctex_parser.h>

#ifndef HAS_SYNCTEX_2

typedef synctex_scanner_t synctex_scanner_p;
typedef synctex_node_t synctex_node_p;

#define synctex_scanner_next_result(scanner) synctex_next_result(scanner)
#define synctex_display_query(scanner, file, line, column, page) synctex_display_query(scanner, file, line, column)

#endif // HAS_SYNCTEX_2

#endif // WITH_SYNCTEX

#include "application.h"
#include "documentview.h"
#include "database.h"
#include "mainwindow.h"
#include "compatibility.h"

#ifdef WITH_SIGNALS

#include "signalhandler.h"

#endif // WITH_SIGNALS

#ifdef Q_OS_WIN

#include <windows.h>

#endif // Q_OS_WIN

#ifdef __amigaos4__

#include <proto/dos.h>
#include <workbench/startup.h>

const char* __attribute__((used)) stack_cookie = "\0$STACK:500000\0";

#endif // __amigaos4__

namespace
{

using namespace qpdfview;

struct File
{
    QString filePath;
    int page;

    QString sourceName;
    int sourceLine;
    int sourceColumn;
    QRectF enclosingBox;

    File() : filePath(), page(-1), sourceName(), sourceLine(-1), sourceColumn(-1), enclosingBox() {}

};

enum ExitStatus
{
    ExitOk = 0,
    ExitUnknownArgument = 1,
    ExitIllegalArgument = 2,
    ExitInconsistentArguments = 3,
    ExitDBusError = 4
};

bool unique = false;
bool quiet = false;

QString instanceName;
QString searchText;

QList< File > files;

MainWindow* mainWindow = 0;

bool loadTranslator(QTranslator* const translator, const QString& fileName, const QString& path)
{
#if QT_VERSION >= QT_VERSION_CHECK(4,8,0)

    const bool ok = translator->load(QLocale::system(), fileName, "_", path);

#else

    const bool ok = translator->load(fileName + "_" + QLocale::system().name(), path);

#endif // QT_VERSION

    if(ok)
    {
        qApp->installTranslator(translator);
    }

    return ok;
}

void loadTranslators()
{
    QTranslator* toolkitTranslator = new QTranslator(qApp);
    loadTranslator(toolkitTranslator, "qt", QLibraryInfo::location(QLibraryInfo::TranslationsPath));

    QTranslator* applicationTranslator = new QTranslator(qApp);
    if(loadTranslator(applicationTranslator, "qpdfview", QDir(QApplication::applicationDirPath()).filePath(APP_DIR_DATA_PATH))) {}
    else if(loadTranslator(applicationTranslator, "qpdfview", DATA_INSTALL_PATH)) {}
    else if(loadTranslator(applicationTranslator, "qpdfview", ":/")) {}
}

void parseCommandLineArguments()
{
    bool instanceNameIsNext = false;
    bool searchTextIsNext = false;
    bool noMoreOptions = false;

    RegularExpression fileAndPageRegExp(QLatin1String("^(.+)#(\\d+)$"));
    RegularExpression fileAndSourceRegExp(QLatin1String("^(.+)#src:(.+):(\\d+):(\\d+)$"));
    RegularExpression instanceNameRegExp(QLatin1String("^[A-Za-z_]+[A-Za-z0-9_]*$"));

    QStringList arguments = QApplication::arguments();

    qDebug() << arguments;

    if(!arguments.isEmpty())
    {
        arguments.removeFirst();
    }

    foreach(const QString& argument, arguments)
    {
        if(instanceNameIsNext)
        {
            if(argument.isEmpty())
            {
                qCritical() << QObject::tr("An empty instance name is not allowed.");
                exit(ExitIllegalArgument);
            }

            instanceNameIsNext = false;
            instanceName = argument;
        }
        else if(searchTextIsNext)
        {
            if(argument.isEmpty())
            {
                qCritical() << QObject::tr("An empty search text is not allowed.");
                exit(ExitIllegalArgument);
            }

            searchTextIsNext = false;
            searchText = argument;
        }
        else if(!noMoreOptions && argument.startsWith("--"))
        {
            if(argument == QLatin1String("--unique"))
            {
                unique = true;
            }
            else if(argument == QLatin1String("--quiet"))
            {
                quiet = true;
            }
            else if(argument == QLatin1String("--instance"))
            {
                instanceNameIsNext = true;
            }
            else if(argument == QLatin1String("--search"))
            {
                searchTextIsNext = true;
            }
            else if(argument == QLatin1String("--choose-instance"))
            {
                bool ok = false;
                const QString chosenInstanceName = QInputDialog::getItem(0, MainWindow::tr("Choose instance"), MainWindow::tr("Instance:"), Database::instance()->knownInstanceNames(), 0, true, &ok);

                if(ok)
                {
                    instanceName = chosenInstanceName;
                }
            }
            else if(argument == QLatin1String("--help"))
            {
#ifndef Q_OS_WIN

                #define INDENT "  "
                #define BREAK  ""

#else

                #define INDENT "\n"
                #define BREAK  "\n    "

#endif  // Q_OS_WIN

                const char* const usage =
                    "Usage: qpdfview [options] [--] [file[#page]] [file[#src:name:line:column]] ...\n"
                    "\n"
                    "Available options:\n"
                    INDENT "--help                      " BREAK "Show this information\n"
                    INDENT "--quiet                     " BREAK "Suppress warning messages when opening files\n"
                    INDENT "--search text               " BREAK "Search for text in the current tab\n"
                    INDENT "--unique                    " BREAK "Open files as tabs in unique window\n"
                    INDENT "--unique --instance name    " BREAK "Open files as tabs in named instance\n"
                    INDENT "--unique --choose-instance  " BREAK "Open files as tabs after choosing an instance name\n"
                    "\n"
                    "Please report bugs at \"https://launchpad.net/qpdfview\".\n";

                qInfo() << usage;
                exit(ExitOk);
            }
            else if(argument == QLatin1String("--"))
            {
                noMoreOptions = true;
            }
            else
            {
                qCritical() << QObject::tr("Unknown command-line option '%1'.").arg(argument);
                exit(ExitUnknownArgument);
            }
        }
        else
        {
            File file;

            if(Match match = Match(fileAndPageRegExp, argument))
            {
                file.filePath = match.captured(1);
                file.page = match.captured(2).toInt();
            }
            else if(Match match = Match(fileAndSourceRegExp, argument))
            {
                file.filePath = match.captured(1);
                file.sourceName = match.captured(2);
                file.sourceLine = match.captured(3).toInt();
                file.sourceColumn = match.captured(4).toInt();
            }
            else
            {
                file.filePath = argument;
            }

            files.append(file);
        }
    }

    if(instanceNameIsNext)
    {
        qCritical() << QObject::tr("Using '--instance' requires an instance name.");
        exit(ExitInconsistentArguments);
    }

    if(!unique && !instanceName.isEmpty())
    {
        qCritical() << QObject::tr("Using '--instance' is not allowed without using '--unique'.");
        exit(ExitInconsistentArguments);
    }

    if(!instanceName.isEmpty() && !Match(instanceNameRegExp, instanceName))
    {
        qCritical() << QObject::tr("An instance name must only contain the characters \"[A-Z][a-z][0-9]_\" and must not begin with a digit.");
        exit(ExitIllegalArgument);
    }

    if(searchTextIsNext)
    {
        qCritical() << QObject::tr("Using '--search' requires a search text.");
        exit(ExitInconsistentArguments);
    }
}

void parseWorkbenchExtendedSelection(int argc, char** argv)
{
#ifdef __amigaos4__

    if(argc == 0)
    {
        const int pathLength = 1024;
        const QScopedArrayPointer< char > filePath(new char[pathLength]);

        const struct WBStartup* wbStartup = reinterpret_cast< struct WBStartup* >(argv);

        for(int index = 1; index < wbStartup->sm_NumArgs; ++index)
        {
            const struct WBArg* wbArg = wbStartup->sm_ArgList + index;

            if((wbArg->wa_Lock) && (*wbArg->wa_Name))
            {
                IDOS->DevNameFromLock(wbArg->wa_Lock, filePath.data(), pathLength, DN_FULLPATH);
                IDOS->AddPart(filePath.data(), wbArg->wa_Name, pathLength);

                File file;
                file.filePath = filePath.data();

                files.append(file);
            }
        }
    }

#else

    Q_UNUSED(argc);
    Q_UNUSED(argv);

#endif // __amigaos4__
}

void resolveSourceReferences()
{
#ifdef WITH_SYNCTEX

    for(int index = 0; index < files.count(); ++index)
    {
        File& file = files[index];

        if(!file.sourceName.isNull())
        {
            if(synctex_scanner_p scanner = synctex_scanner_new_with_output_file(file.filePath.toLocal8Bit(), 0, 1))
            {
                if(synctex_display_query(scanner, file.sourceName.toLocal8Bit(), file.sourceLine, file.sourceColumn, -1) > 0)
                {
                    for(synctex_node_p node = synctex_scanner_next_result(scanner); node != 0; node = synctex_scanner_next_result(scanner))
                    {
                        int page = synctex_node_page(node);
                        QRectF enclosingBox(synctex_node_box_visible_h(node), synctex_node_box_visible_v(node), synctex_node_box_visible_width(node), synctex_node_box_visible_height(node));

                        if(file.page != page)
                        {
                            file.page = page;
                            file.enclosingBox = enclosingBox;
                        }
                        else
                        {
                            file.enclosingBox = file.enclosingBox.united(enclosingBox);
                        }
                    }
                }

                synctex_scanner_free(scanner);
            }
            else
            {
                qWarning() << DocumentView::tr("SyncTeX data for '%1' could not be found.").arg(file.filePath);
            }
        }
    }

#endif // WITH_SYNCTEX
}

void activateUniqueInstance()
{
    qApp->setObjectName(instanceName);

#ifdef WITH_DBUS

    if(unique)
    {
        QScopedPointer< QDBusInterface > uniqueInstance(MainWindowAdaptor::createInterface());

        if(uniqueInstance->isValid())
        {
            uniqueInstance->call("raiseAndActivate");

            foreach(const File& file, files)
            {
                QDBusReply< bool > reply = uniqueInstance->call("jumpToPageOrOpenInNewTab", QFileInfo(file.filePath).absoluteFilePath(), file.page, true, file.enclosingBox, quiet);

                if(!reply.isValid())
                {
                    qCritical() << QDBusConnection::sessionBus().lastError().message();

                    exit(ExitDBusError);
                }
            }

            if(!files.isEmpty())
            {
                uniqueInstance->call("saveDatabase");
            }

            if(!searchText.isEmpty())
            {
                uniqueInstance->call("startSearch", searchText);
            }

            exit(ExitOk);
        }
        else
        {
            mainWindow = new MainWindow();

            if(MainWindowAdaptor::createAdaptor(mainWindow) == 0)
            {
                qCritical() << QDBusConnection::sessionBus().lastError().message();

                delete mainWindow;
                exit(ExitDBusError);
            }
        }
    }
    else
    {
        mainWindow = new MainWindow();
    }

#else

    mainWindow = new MainWindow();

#endif // WITH_DBUS
}

void prepareSignalHandler()
{
#ifdef WITH_SIGNALS

    if(SignalHandler::prepareSignals())
    {
        SignalHandler* signalHandler = new SignalHandler(mainWindow);

        QObject::connect(signalHandler, SIGNAL(sigIntReceived()), mainWindow, SLOT(close()));
        QObject::connect(signalHandler, SIGNAL(sigTermReceived()), mainWindow, SLOT(close()));
    }
    else
    {
        qWarning() << QObject::tr("Could not prepare signal handler.");
    }

#endif // WITH_SIGNALS
}

#ifdef Q_OS_WIN

void showMessageBox(QtMsgType type, const QMessageLogContext& context, const QString& message)
{
    Q_UNUSED(context);

    const char* prefix = "";
    UINT icon = MB_ICONINFORMATION;

    switch (type)
    {
        case QtDebugMsg:
            prefix = "Debug: ";
            break;
        case QtWarningMsg:
            prefix = "Warning: ";
            icon = MB_ICONWARNING;
            break;
        case QtCriticalMsg:
            prefix = "Critical error: ";
            icon = MB_ICONERROR;
            break;
        case QtFatalMsg:
            prefix = "Fatal error: ";
            icon = MB_ICONERROR;
            break;
    }

    const QString fullMessage = prefix + message;
    MessageBoxA(NULL, fullMessage.toLocal8Bit().constData(), "qpdfview", MB_OK | icon);
}

#endif // Q_OS_WIN

void installMessageHandler()
{
#ifdef Q_OS_WIN

    qInstallMessageHandler(showMessageBox);

#endif // Q_OS_WIN
}

} // anonymous

int main(int argc, char** argv)
{
    qRegisterMetaType< QList< QRectF > >("QList<QRectF>");
    qRegisterMetaType< Rotation >("Rotation");
    qRegisterMetaType< RenderParam >("RenderParam");

    installMessageHandler();

    parseWorkbenchExtendedSelection(argc, argv);

    Application application(argc, argv);

    loadTranslators();

    parseCommandLineArguments();

    resolveSourceReferences();

    activateUniqueInstance();

    application.setMainWindow(mainWindow);

    prepareSignalHandler();

    mainWindow->show();
    mainWindow->setAttribute(Qt::WA_DeleteOnClose);

    foreach(const File& file, files)
    {
        mainWindow->jumpToPageOrOpenInNewTab(file.filePath, file.page, true, file.enclosingBox, quiet);
    }

    if(!files.isEmpty())
    {
        mainWindow->saveDatabase();
    }

    if(!searchText.isEmpty())
    {
        mainWindow->startSearch(searchText);
    }

    return application.exec();
}
