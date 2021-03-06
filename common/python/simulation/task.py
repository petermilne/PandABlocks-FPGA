import Queue
import threading
import traceback
import os

class Task(object):
    def __init__(self):
        self.make_queue()
        self.setup_event_loop()

    def make_queue(self):
        self.q = Queue.Queue()

    def post(self, event):
        done = threading.Event()
        self.q.put((event, done))
        return done

    def post_wait(self, event):
        done = threading.Event()
        self.q.put((event, done))
        done.wait()

    def get_next_event(self, timeout=None):
        try:
            result = self.q.get(timeout=timeout)
        except Queue.Empty:
            return None
        else:
            return result

    def start_event_loop(self):
        self.t = threading.Thread(target=self.event_loop)
        self.t.daemon = True
        self.t.start()

    def setup_event_loop(self):
        pass

    def event_loop(self):
        try:
            while True:
                self.handle_events()
        except Exception as e:
            print 'Caught exception in worker thread'
            traceback.print_exc()
            os._exit(1)
