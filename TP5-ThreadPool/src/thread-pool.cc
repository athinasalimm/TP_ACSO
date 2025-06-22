/**
 * File: thread-pool.cc
 * --------------------
 * Presents the implementation of the ThreadPool class.
 */
#include <iostream>
#include "thread-pool.h"
using namespace std;

ThreadPool::ThreadPool(size_t numThreads) : wts(numThreads), done(false) {
    dt = thread([this] { dispatcher(); });
    for (size_t i = 0; i < numThreads; ++i) {
        wts[i].ts = thread([this, i] { worker(i); });
        {
            lock_guard<mutex> lock(workerLock);
            workers_libres.push(i);     
        }
        sem_workers.signal();         
    }
}

void ThreadPool::schedule(const function<void(void)>& thunk) {
    if (!thunk) {
        throw invalid_argument("No se puede encolar una función nula (nullptr).");
    }
    if (done) return;
    {
        unique_lock<mutex> lock(queueLock);
        tareas.push(thunk);
    }
    {
        unique_lock<mutex> lock(mutex_wait);
        ++tareas_en_progreso;
    }
    sem_tareas.signal();  
}


void ThreadPool::worker(int i) {
    while (true) {
        wts[i].sem_trabajar.wait();  
        if (done && !wts[i].thunk) break; 
        function<void(void)> tarea = wts[i].thunk;
        try {
            if (tarea) tarea();
        } catch (...) {
        }
        {
            unique_lock<mutex> lock(mutex_wait);
            --tareas_en_progreso;
            if (tareas_en_progreso == 0) {
                cv_wait.notify_all(); 
            }
        }
        {
            lock_guard<mutex> lock(workerLock);
            workers_libres.push(i);  
        }
        sem_workers.signal();  
    }
}

void ThreadPool::dispatcher() {
    while (true) {
        sem_tareas.wait();  // Esperar a que haya al menos una tarea

        function<void(void)> thunk;
        {
            unique_lock<mutex> lock(queueLock);
            if (done && tareas.empty()) return;
            if (!tareas.empty()) {
                thunk = tareas.front();
                tareas.pop();
            } else {
                continue;  // Puede pasar por race condition: vuelvo a esperar
            }
        }

        sem_workers.wait();  // Esperar a que haya un worker libre

        int worker_id;
        {
            lock_guard<mutex> lock(workerLock);
            worker_id = workers_libres.front();
            workers_libres.pop();
        }

        wts[worker_id].thunk = thunk;
        wts[worker_id].sem_trabajar.signal();  // Despertar al worker
    }
}

void ThreadPool::wait() {
    unique_lock<mutex> lock(mutex_wait);
    cv_wait.wait(lock, [this] {
        return tareas_en_progreso == 0;
    });
}

ThreadPool::~ThreadPool() {
    wait();  
    {
        lock_guard<mutex> lock(mutex_wait);
        lock_guard<mutex> lock2(queueLock);
        done = true;

        // marcar los thunks como nulos
        {
            lock_guard<mutex> lock(workerLock);
            for (size_t i = 0; i < wts.size(); ++i) {
                wts[i].thunk = nullptr;
            }
        }
    }

    // Despertar dispatcher (por si está en sem_tareas.wait())
    for (size_t i = 0; i < wts.size(); ++i)
        sem_tareas.signal();

    if (dt.joinable()) dt.join();

    // Despertar todos los workers
    for (size_t i = 0; i < wts.size(); ++i)
        wts[i].sem_trabajar.signal();

    for (size_t i = 0; i < wts.size(); ++i) {
        if (wts[i].ts.joinable())
            wts[i].ts.join();
    }
}

