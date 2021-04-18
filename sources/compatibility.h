/*

Copyright 2021 Adam Reichold

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

#ifndef COMPATIBILITY_H
#define COMPATIBILITY_H

#include <QWheelEvent>
#include <QPrinter>
#include <QProcess>

#if QT_VERSION >= QT_VERSION_CHECK(5,0,0)

#include <QRegularExpression>

#else

#include <QRegExp>

#endif // QT_VERSION

namespace qpdfview
{

inline bool rotatedForward(const QWheelEvent* event)
{
#if QT_VERSION >= QT_VERSION_CHECK(5,15,0)

    return event->angleDelta().y() > 0;

#else

    return event->delta() > 0;

#endif // QT_VERSION
}

#if QT_VERSION >= QT_VERSION_CHECK(5,0,0)

typedef QRegularExpression RegularExpression;

class Match
{
    QRegularExpressionMatch match;

public:
    Match(RegularExpression& expr, const QString& text) :
        match(expr.match(text))
    {
    }

    operator bool() const
    {
        return match.hasMatch();
    }

    QString captured(int nth) const
    {
        return match.captured(nth);
    }

};

#else

typedef QRegExp RegularExpression;

class Match
{
    QRegExp* expr;

public:
    Match(QRegExp& expr, const QString& text) :
        expr(expr.indexIn(text) != -1 ? &expr : 0)
    {
    }

    operator bool() const
    {
        return expr != 0;
    }

    QString captured(int nth) const
    {
        return expr->cap(nth);
    }

};

#endif // QT_VERSION

#if QT_VERSION >= QT_VERSION_CHECK(5,14,0)

typedef Qt::SplitBehaviorFlags SplitBehavior;
namespace SplitBehaviorValues = Qt;

#else

typedef QString::SplitBehavior SplitBehavior;
typedef QString SplitBehaviorValues;

#endif // QT_VERSION

#if QT_VERSION >= QT_VERSION_CHECK(5,3,0)

typedef QPageLayout::Orientation PageOrientation;
typedef QPageLayout PageOrientationValues;

#else

typedef QPrinter::Orientation PageOrientation;
typedef QPrinter PageOrientationValues;

#endif // QT_VERSION

template< typename Iterator, typename Value >
Iterator binarySearch(Iterator first, Iterator last, const Value& value)
{
    first = std::lower_bound(first, last, value);

    return first == last || value < *first ? last : first;
}

inline bool startDetached(QString command)
{
#if QT_VERSION >= QT_VERSION_CHECK(5,15,0)

        QStringList arguments = QProcess::splitCommand(command);
        QString program = arguments.takeFirst();

        return QProcess::startDetached(program, arguments);

#else

        return QProcess::startDetached(command);

#endif // QT_VERSION
}

} // qpdfview

#endif // MISCELLANEOUS_H
