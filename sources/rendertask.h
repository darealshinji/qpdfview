/*

Copyright 2013-2015 Adam Reichold

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

#ifndef RENDERTASK_H
#define RENDERTASK_H

#include <QImage>
#include <QMutex>
#include <QObject>
#include <QRunnable>
#include <QSet>
#include <QWaitCondition>

#include "renderparam.h"

namespace qpdfview
{

namespace Model
{
class Page;
}

class Settings;

class RenderTaskParent
{
    friend struct RenderTaskFinishedEvent;
    friend struct RenderTaskCanceledEvent;
    friend struct DeleteParentLaterEvent;

public:
    virtual ~RenderTaskParent();

private:
    virtual void on_finished(const RenderParam& renderParam,
                             const QRect& rect, bool prefetch,
                             const QImage& image, const QRectF& cropRect) = 0;
    virtual void on_canceled() = 0;
};

class RenderTaskDispatcher : public QObject
{
    Q_OBJECT

    friend class RenderTask;

private:
    Q_DISABLE_COPY(RenderTaskDispatcher)

    RenderTaskDispatcher(QObject* parent = 0);


    void finished(RenderTaskParent* parent,
                  const RenderParam& renderParam,
                  const QRect& rect, bool prefetch,
                  const QImage& image, const QRectF& cropRect);
    void canceled(RenderTaskParent* parent);

    void deleteParentLater(RenderTaskParent* parent);

public:
    bool event(QEvent* event);

private:
    QSet< RenderTaskParent* > m_activeParents;

    void addActiveParent(RenderTaskParent* parent);
    void removeActiveParent(RenderTaskParent* parent);

};

class RenderTask : public QRunnable
{
public:
    explicit RenderTask(Model::Page* page, RenderTaskParent* parent = 0);
    ~RenderTask();

    void wait();

    bool isRunning() const;

    bool wasCanceled() const { return loadCancellation() != NotCanceled; }
    bool wasCanceledNormally() const { return loadCancellation() == CanceledNormally; }
    bool wasCanceledForcibly() const { return loadCancellation() == CanceledForcibly; }

    void run();

    void start(const RenderParam& renderParam,
               const QRect& rect, bool prefetch);

    void cancel(bool force = false) { setCancellation(force); }

    void deleteParentLater();

private:
    Q_DISABLE_COPY(RenderTask)

    static Settings* s_settings;

    static RenderTaskDispatcher* s_dispatcher;
    RenderTaskParent* m_parent;

    mutable QMutex m_mutex;
    QWaitCondition m_waitCondition;

    bool m_isRunning;
    QAtomicInt m_wasCanceled;

    enum
    {
        NotCanceled = 0,
        CanceledNormally = 1,
        CanceledForcibly = 2
    };

    void setCancellation(bool force);
    void resetCancellation();
    bool testCancellation();
    int loadCancellation() const;

    void finish(bool canceled);


    Model::Page* m_page;

    RenderParam m_renderParam;

    QRect m_rect;
    bool m_prefetch;

};


#if QT_VERSION > QT_VERSION_CHECK(5,0,0)

inline void RenderTask::setCancellation(bool force)
{
#if QT_VERSION >= QT_VERSION_CHECK(5,14,0)

    m_wasCanceled.storeRelaxed(force ? CanceledForcibly : CanceledNormally);

#else

    m_wasCanceled.store(force ? CanceledForcibly : CanceledNormally);

#endif // QT_VERSION
}

inline void RenderTask::resetCancellation()
{
#if QT_VERSION >= QT_VERSION_CHECK(5,14,0)

    m_wasCanceled.storeRelaxed(NotCanceled);

#else

    m_wasCanceled.store(NotCanceled);

#endif // QT_VERSION
}

inline bool RenderTask::testCancellation()
{
    return m_prefetch ?
                loadCancellation() == CanceledForcibly :
                loadCancellation() != NotCanceled;
}

inline int RenderTask::loadCancellation() const
{
#if QT_VERSION >= QT_VERSION_CHECK(5,14,0)

    return m_wasCanceled.loadRelaxed();

#else

    return m_wasCanceled.load();

#endif // QT_VERSION
}

#else

inline void RenderTask::setCancellation(bool force)
{
    m_wasCanceled.fetchAndStoreRelaxed(force ? CanceledForcibly : CanceledNormally);
}

inline void RenderTask::resetCancellation()
{
    m_wasCanceled.fetchAndStoreRelaxed(NotCanceled);
}

inline bool RenderTask::testCancellation()
{
    return m_prefetch ?
                m_wasCanceled.testAndSetRelaxed(CanceledForcibly, CanceledForcibly) :
                !m_wasCanceled.testAndSetRelaxed(NotCanceled, NotCanceled);
}

inline int RenderTask::loadCancellation() const
{
    return m_wasCanceled;
}

#endif // QT_VERSION

} // qpdfview

#endif // RENDERTASK_H
