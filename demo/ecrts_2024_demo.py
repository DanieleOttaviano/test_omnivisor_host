import sys
import time
import signal

import numpy as np

from PySide6.QtWidgets import QApplication, QPushButton
from PySide6.QtCore import Slot, QRunnable, QThreadPool, QObject, Signal
from PySide6.QtGui import Qt

from matplotlib.backends.backend_qtagg import FigureCanvas
from matplotlib.backends.qt_compat import QtWidgets
from matplotlib.figure import Figure
from matplotlib import pyplot as plt

from ssh_test import *

class BoardWorker(QRunnable):
    
    class Signals(QObject):
        finished = Signal()
        error = Signal(tuple)
    
    def __init__(self, fn):
        super(BoardWorker, self).__init__()
        
        self.signals = BoardWorker.Signals()
        self.fn = fn
        
    @Slot()
    def run(self):
        try:
            self.fn()
        except:
            traceback.print_exc()
            exctype, value = sys.exc_info()[:2]
            self.signals.error.emit((exctype, value, traceback.format_exc()))
        finally:
            self.signals.finished.emit()
                
    def close(self):
        self._iterator._buf.close()

class ShmMemoryReaderWorker(QRunnable):
    
    class Signals(QObject):
        finished = Signal()
        error = Signal(tuple)
        progress = Signal(int)
        timeout = Signal()
    
    def __init__(self, shm_iterator):
        super(ShmMemoryReaderWorker, self).__init__()
        
        self._iterator = shm_iterator
        self.signals = ShmMemoryReaderWorker.Signals()
        
    @Slot()
    def run(self):
        try:
            for x in iter(self._iterator):
                if x is None:
                    if not self._iterator._buf.closed():
                        self.signals.timeout.emit()
                    else:
                        print('Closed timeout')
                else:
                    self.signals.progress.emit(x)
        except:
            traceback.print_exc()
            exctype, value = sys.exc_info()[:2]
            self.signals.error.emit((exctype, value, traceback.format_exc()))
        finally:
            self.signals.finished.emit()
                
    def close(self):
        self._iterator._buf.close()
    
class Core(QtWidgets.QCheckBox):
    
    def __init__(self, key, model, callback):
        super().__init__(key)

        self.checkStateChanged.connect(
            lambda state: callback(state == Qt.CheckState.Checked))

        self.setChecked(model.is_active())
        self._model = model
        
        model.add_active_callback(self.setChecked)
        model.add_active_callback(self._update_text_color)
        model.add_faulty_callback(self._update_text_color)
        model.add_crashed_callback(self._update_text_color)
    
    def _update_text_color(self, *args):
        if self._model.is_crashed():
            color = 'red'
        elif self._model.is_faulty():
            color = 'yellow'
        else:
            color = None
            
        if color:
            style = f"QCheckBox {{ color: {color} }}"
        else:
            style = ""
            
        self.setStyleSheet(style)

class Disturb(QtWidgets.QCheckBox):

    def __init__(self, key, model, callback):
        super().__init__(key)

        self.checkStateChanged.connect(
            lambda state: callback(state == Qt.CheckState.Checked))

        self.setChecked(model.is_active())

        model.set_active_callback(self.setChecked)
    
class SpatialIsolation(QtWidgets.QGroupBox):
    
    def __init__(self, model, callback=None):
        super().__init__()

        btn = QtWidgets.QCheckBox('Spatial isolation')
        btn.checkStateChanged.connect(lambda state: callback(state == Qt.CheckState.Checked))
        btn.setChecked(model.has_spatial_isolation())
        model.add_spatial_isolation_callback(btn.setChecked)
        
        vbox = QtWidgets.QVBoxLayout()
        vbox.addWidget(btn)
        
        self.setLayout(vbox)
        
class TemporalIsolation(QtWidgets.QGroupBox):
    
    def __init__(self, model, temporal_callback, bandwidth_callback):
        super().__init__()
        
        vbox = QtWidgets.QVBoxLayout()
        hbox = QtWidgets.QHBoxLayout()
        
        self.btn = QtWidgets.QCheckBox('Temporal isolation')
        self.btn.checkStateChanged.connect(lambda state: temporal_callback(state == Qt.CheckState.Checked))
        self.btn.setEnabled(model._omnivisor.has_spatial_isolation())
        model._omnivisor.add_spatial_isolation_callback(self.btn.setEnabled)
        
        bw_min, bw_max = model._omnivisor.get_temporal_isolation_bandwidth_range()
        self.value = model._omnivisor.get_temporal_isolation_bandwidth()
        
        self.slider = QtWidgets.QSlider()
        self.slider.setOrientation(Qt.Orientation.Vertical)
        self.slider.setRange(bw_min, bw_max)
        self.slider.setTickInterval(50)
        self.slider.setTickPosition(QtWidgets.QSlider.TicksRight)
        self.slider.setValue(self.value)
        self.slider.valueChanged.connect(self.__changed_value)
        self.slider.setEnabled(model._omnivisor.has_temporal_isolation())
        model._omnivisor.add_temporal_isolation_callback(self.slider.setEnabled)

        # self.current_bw = QtWidgets.QLineEdit(chr(0x221E))
        self.current_bw = QtWidgets.QLineEdit()
        self.current_bw.setReadOnly(True)
        self.current_bw.setText(f"{self.value} MB/s")
        model._omnivisor.add_temporal_bandwidth_callback(lambda val: self.current_bw.setText(f"{val} MB/s"))
        
        hbox.addWidget(self.slider)
        
        self.box = QtWidgets.QSpinBox()
        self.box.setRange(bw_min, bw_max)
        self.box.setValue(self.value)
        self.box.valueChanged.connect(self.__changed_value)
        self.box.setEnabled(model._omnivisor.has_temporal_isolation())
        model._omnivisor.add_temporal_isolation_callback(self.box.setEnabled)
        
        self.apply_btn = QtWidgets.QPushButton('Apply')
        self.apply_btn.setEnabled(model._omnivisor.has_temporal_isolation())
        model._omnivisor.add_temporal_isolation_callback(self.apply_btn.setEnabled)
        self.apply_btn.clicked.connect(lambda _: bandwidth_callback(self.value))
        
        vbox.addWidget(self.btn)

        vbox.addWidget(QtWidgets.QLabel("Current bandwidth"))

        vbox.addWidget(self.current_bw)
        vbox.addWidget(QtWidgets.QLabel("Target bandwidth"))
        vbox.addLayout(hbox)
        vbox.addWidget(self.box)
        vbox.addWidget(self.apply_btn)
        
        vbox.setAlignment(Qt.AlignHCenter)
        
        self.setLayout(vbox)
        
    def __changed_value(self, value):
        if self.value == value:
            return
        
        self.value = value
        self.box.setValue(value)
        self.slider.setValue(value)
    
    def __changed_slider_value(self, value):
        self.value = value
        self.box.setValue(value)
        
    def __changed_box_value(self, value):
        self.value = value
        self.slider.setValue(value)
        
    def reset(self):
        self.state = False
        self.btn.setChecked(self.state)

class UpdatableFigure(FigureCanvas):
    
    def __init__(self, model, worker_getter, window_size=100, data_size=1000):
        super().__init__(Figure(figsize=(5, 3)))
        
        self._worker_getter = worker_getter
        
        self._window_size = window_size
        self._data_size = data_size
        self._axis = self.figure.subplots()
        self._last_x = -1

        self._data = []

        self._line, = self._axis.plot([], [])
        self._axis.set_xlim([-1, self._window_size + 1])
        self._axis.yaxis.set_major_locator(plt.MaxNLocator(10))
        # self._axis.set_ylim([-.05, 1.1])
        
        self._min_y = 0
        self._max_y = 1
        
        y_delta = (self._max_y - self._min_y) / 20
        self._axis.set_ylim([self._min_y - y_delta, self._max_y + y_delta])
        
        
        self._worker = None
        model.add_active_callback(self.__active_callback)
        # model.add_crashed_callback(self.__close_worker)
        
        
    def __active_callback(self, val):
        if self._worker is None:
            self._worker = self._worker_getter(progress_callback=self.add_data, finished_callback=self.__close_worker, error_callback=self.__close_worker)
            print(self._worker)
        # else:
        #     self.__close_worker()
                
    def __close_worker(self, doit=True):
        if self._worker and doit:
            self._worker.close()
            self._worker = None

    def __refresh_plot(self):
        x, y = zip(*self._data)

        y_delta = (self._max_y - self._min_y + 1) / 20
        if y_delta == 0:
            y_delta = 1
        self._axis.set_ylim([self._min_y - y_delta, self._max_y + y_delta])

        if self._last_x >= self._window_size:
            self._axis.set_xlim([self._last_x - self._window_size - 1, self._last_x + 1])

        self._line.set_data(x, y)
        self._line.figure.canvas.draw()

    def __update_data(self, y):
        if len(self._data) == self._data_size:
            self._data = self._data[1:]

        self._last_x = self._last_x + 1

        self._data.append([self._last_x, y])

        if len(self._data) == 1:
            self._max_y = y
            self._min_y = y
        else:
            _, _y = zip(*self._data)
            self._max_y = max(*_y, self._max_y)
            self._min_y = min(*_y, self._min_y)
    
    def add_data(self, y):
        self.__update_data(y)
        self.__refresh_plot()

class ApplicationWindow(QtWidgets.QMainWindow):
        
    def get_core_iterator(self, core, progress_callback, finished_callback, error_callback=None):
        # print(core, progress_callback, finished_callback)
        traceback.print_stack()
        iterator = self._board.get_shm_itr(core, timeout_interval=1.5)
        worker = ShmMemoryReaderWorker(iterator)
        worker.signals.finished.connect(finished_callback)
        worker.signals.progress.connect(progress_callback)
        if error_callback:
            worker.signals.error.connect(error_callback)
        self.threadpool.start(worker)
        return worker
        
    def __create_group_box(self, title, widgets):
        vbox = QtWidgets.QVBoxLayout()        
        for widget in widgets:
            vbox.addWidget(widget)

        group = QtWidgets.QGroupBox()
        group.setTitle(title)
        group.setAlignment(Qt.AlignCenter)
        group.setLayout(vbox)

        return group

    def __create_disturbs_widgets(self, models, callback):
        return [
            Disturb(key, models[key], lambda active, key=key: callback(key, active))
            for key in models]


    def __create_disturbs_group(self, models, callback):
        disturbs = QtWidgets.QGroupBox()

        vbox = QtWidgets.QVBoxLayout()
                
        for key in models:
            vbox.addWidget(Disturb(
                key,
                models[key],
                lambda active, key=key: callback(key, active)))

        disturbs.setTitle('Disturbs')
        disturbs.setAlignment(Qt.AlignCenter)
        disturbs.setLayout(vbox)

        return disturbs

    def __create_cores_widgets(self, models, callback):
        return [Core(
                key,
                models[key],
                lambda active, key=key: callback(key, active)
                ) for key in models]

    def __create_cores_group(self, models, callback):
        cores = QtWidgets.QGroupBox()
        vbox = QtWidgets.QVBoxLayout()
        
        for key in models:
            vbox.addWidget(Core(
                key,
                models[key],
                lambda active, key=key: callback(key, active)
                ))
            

        cores.setTitle('Remote Cores')
        cores.setAlignment(Qt.AlignCenter)
        cores.setLayout(vbox)

        return cores

    def __init__(self):
        super().__init__()
        
        self.threadpool = QThreadPool()

        self._main = QtWidgets.QWidget()
        self.setCentralWidget(self._main)

        self._board = BoardInterface(debug=True, crash_by_timeout_threshold=4)
        self._model = self._board._model
        
        cores = self.__create_group_box("Cores", self.__create_cores_widgets(self._model._remote_cores, self._board.toggle_remote_core))
        disturbs = self.__create_group_box("Disturbs", self.__create_disturbs_widgets(self._model._disturbs, self._board.toggle_disturb))
        self.spatialIsolation = SpatialIsolation(self._model._omnivisor , callback=self._board.toggle_spatial_isolation)
        self.temporalIsolation = TemporalIsolation(self._model, temporal_callback=self._board.toggle_temporal_isolation, bandwidth_callback=self._board.set_temporal_bandwidth)

        mainLayout = QtWidgets.QVBoxLayout(self._main)
        content = QtWidgets.QWidget()
        contentLayout = QtWidgets.QHBoxLayout(content)
        mainLayout.addWidget(content, stretch=1)

        # riscv = UpdatableFigure(self._model._remote_cores['RISCV'], lambda core='RISCV', *args, **kwargs: self.get_core_iterator(core, *args, **kwargs), window_size=100)
        # rpu = UpdatableFigure(self._model._remote_cores['RPU'], lambda core='RPU', *args, **kwargs: self.get_core_iterator(core, *args, **kwargs), window_size=100)
        # self._rpu_fig = rpu
        # self._riscv_fig = riscv
        
        plots = QtWidgets.QVBoxLayout()
        for core in self._model._remote_cores:
            plot = UpdatableFigure(
                self._model._remote_cores[core], 
                lambda core=core, *args, **kwargs: self.get_core_iterator(core, *args, **kwargs), 
                window_size=100)
            plots.addWidget(plot)
        # plots.addWidget(rpu)
        # plots.addWidget(riscv)
        
        contentLayout.addLayout(plots, stretch=1)

        button = QPushButton("Clear shm")
        button.clicked.connect(lambda _: self._board.clear_shm())
        
        sideLayout = QtWidgets.QVBoxLayout()
        sideLayout.addWidget(cores)
        sideLayout.addWidget(disturbs)
        sideLayout.addWidget(self.spatialIsolation)
        sideLayout.addWidget(self.temporalIsolation)
        sideLayout.addWidget(button)

        statusBar = QtWidgets.QStatusBar()
        contentLayout.addLayout(sideLayout, stretch=0)
        
        mainLayout.addWidget(statusBar)
        
        content.setEnabled(False)
        
        worker = BoardWorker(lambda b=statusBar: self._test(self._board.setup_board, b))
        worker.signals.finished.connect(lambda l=content, b=statusBar: self._test1(l.setEnabled, b))
        self.threadpool.start(worker)
        
    def _test(self, fn, bar):
        bar.showMessage("Setting up board")
        # print("PM")
        # time.sleep(1)
        fn()
        
    def _test1(self, fn, bar):
        fn(True)
        bar.showMessage("Board ready")

if __name__ == "__main__":

    # Create the Qt Application
    app = QApplication(sys.argv)
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    # Check whether there is already a running QApplication (e.g., if running
    # from an IDE).
    qapp = QtWidgets.QApplication.instance()
    if not qapp:
        print('Creating')
        qapp = QtWidgets.QApplication(sys.argv)

    app = ApplicationWindow()
    
    # button.show()
    app.show()
    app.activateWindow()
    app.raise_()
    qapp.exec()
    qapp.quit()