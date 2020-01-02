/*

Copyright 2020 vit9696

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

#ifndef APPLICATION_H
#define APPLICATION_H

#include <QApplication>
#include <QPointer>

namespace qpdfview
{

class MainWindow;

class Application : public QApplication
{
    Q_OBJECT

public:
    Application(int& argc, char** argv);

    void setMainWindow(MainWindow* window);

    virtual bool event(QEvent* event);

private:
    QPointer< MainWindow > m_mainWindow;

};

} // qpdfview

#endif // APPLICATION_H
