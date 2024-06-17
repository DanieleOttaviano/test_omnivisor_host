#!/usr/bin/env python
# coding: utf-8

# In[2]:


import paramiko
import traceback
from paramiko.ssh_exception import NoValidConnectionsError
import sys
import time
import threading
from enum import Enum, auto


# In[3]:


class BoardException(Exception):
    
    def __init__(self, message):
        super().__init__(message)

class BoardRemoteExeception(BoardException):
    def __init__(self, stderr, stdout):
        super().__init__(f'''Remote return code non zero:\n{stderr}''')
        self.stdout = stdout
        self.stderr = stderr


# In[4]:


class StupidBufferedReader:

    def __init__(self, channel):
        self.buf = ''
        self.lines = []
        self.channel = channel
        # print(channel.closed, self.closed())

    def __read__(self):
        if self.channel.recv_ready():
            raw = self.channel.recv(1024)
            raw = f'''{self.buf}{raw.decode('utf-8')}'''
            lines = raw.splitlines(keepends=True)
            if not lines[-1][-1] == '\n':
                self.buf = lines.pop(-1)
            self.lines += lines

    def close(self):
        while not self.channel.closed:
            if not self.channel.closed:
                self.channel.send(chr(3))
            if not self.channel.closed:
                self.channel.send(chr(4))
            self.__read__()

    def closed(self):
        return self.channel.closed

    def readline(self):
        if not self.lines:
            self.__read__()

        if self.lines:
            return self.lines.pop(0)

        return None
    
    def ready(self):
        return len(self.lines) > 0 or self.channel.recv_ready()

    def __iter__(self):
        return self

    def __next__(self):
        line = self.readline()
        if line:
            return line
        raise StopIteration


# In[5]:


class OmnivisorModel:
    
    def __init__(self):
        self._active = False
        self._spatial_isolation = False
        self._temporal_isolation = False
        self._temporal_range = (5, 950)
        self._temporal_bw = 480

        self._activation_callback = []
        self._spatial_isolation_callback = []
        self._temporal_isolation_callback = []
        self._temporal_bandwidth_callback = []
        
    def is_active(self):
        return self._active

    def has_spatial_isolation(self):
        return self._spatial_isolation

    def has_temporal_isolation(self):
        return self._temporal_isolation

    def get_temporal_isolation_bandwidth_range(self):
        return self._temporal_range

    def get_temporal_isolation_bandwidth(self):
        return self._temporal_bw

    def add_activation_callback(self, activation_callback):
        self._activation_callback.append(activation_callback)
        
    def add_spatial_isolation_callback(self, spatial_isolation_callback):
        self._spatial_isolation_callback.append(spatial_isolation_callback)
        
    def add_temporal_isolation_callback(self, temporal_isolation_callback):
        self._temporal_isolation_callback.append(temporal_isolation_callback)
        
    def add_temporal_bandwidth_callback(self, temporal_bandwidth_callback):
        self._temporal_bandwidth_callback.append(temporal_bandwidth_callback)
        
    def set_active(self, active):
        if self._active == active:
            print("same, skipping")
            return

        self._active = active

        if not active:
            self.set_spatial_isolation(False)
        
        for fn in self._activation_callback:
            fn(active)

    def set_spatial_isolation(self, spatial):
        if self._spatial_isolation == spatial:
            return

        self._spatial_isolation = spatial

        if spatial:
            self.set_active(True)
        else:
            self.set_temporal_isolation(False)

        for fn in self._spatial_isolation_callback:
            fn(spatial)

    def set_temporal_isolation(self, temporal):
        if self._temporal_isolation == temporal:
            return

        self._temporal_isolation = temporal

        if temporal:
            self.set_spatial_isolation(True)
        else:
            self.set_temporal_isolation_bandwidth((self._temporal_range[0] + self._temporal_range[1]) / 2)

        for fn in self._temporal_isolation_callback:
            fn(temporal)

    def set_temporal_isolation_bandwidth(self, bandwidth):
        bandwidth = int(bandwidth)

        if self._temporal_bw == bandwidth:
            return

        self._temporal_bw = bandwidth
        
        self.set_temporal_isolation(True)

        for fn in self._temporal_bandwidth_callback:
            fn(bandwidth)

class RemoteCoreModel:
        
    def __init__(self, crash_by_timeout_threshold = 10):
        self._active = False
        self._faulty = False
        self._crashed = False
        self._threshold = crash_by_timeout_threshold
        self._count = 0

        self._active_callback = []
        self._faulty_callback = []
        self._crashed_callback = []

    def is_active(self):
        return self._active

    def is_faulty(self):
        return self._faulty

    def is_crashed(self):
        return self._crashed

    def add_active_callback(self, active_callback):
        self._active_callback.append(active_callback)
        
    def add_faulty_callback(self, faulty_callback):
        self._faulty_callback.append(faulty_callback)
        
    def add_crashed_callback(self, crashed_callback):
        self._crashed_callback.append(crashed_callback)

    def set_active(self, active):
        if self._active == active:
            return 

        self._active = active

        self.set_faulty(False)
        self.set_crashed(False)
        self._count = 0
        
        for fn in self._active_callback:
            fn(active)
        
    def set_faulty(self, faulty):
        if self._faulty == faulty:
            return 

        self._faulty = faulty

        if faulty:
            self.set_crashed(False)

        for fn in self._faulty_callback:
            fn(faulty)
        
    def set_crashed(self, crashed):
        if self._crashed == crashed:
            return 

        self._crashed = crashed
        
        if crashed:
            self.set_faulty(False)

        for fn in self._crashed_callback:
            fn(crashed)
        

    def reset_timeout_count(self):
        self._count = 0
        self.set_faulty(False)
        
    def increase_timeout_count(self):
        if not self._active:
            return
        self._count += 1
        if self._count < self._threshold:
            self.set_faulty(True)
        else:
            self.set_crashed(True)

class DisturbModel:

    def __init__(self, active_callback = None):
        self._active = False
        self._active_callback = active_callback

    def is_active(self):
        return self._active

    def set_active_callback(self, callback):
        self._activation_callback = callback

    def set_active(self, active):
        if self._active == active:
            return

        self._active = active

        if self._activation_callback:
            self._activation_callback(active)

class BoardModel:

    def __init__(self, **kwargs):
        self._reachable = None
        self._omnivisor = OmnivisorModel()
        self._remote_cores = {}
        
        for core in ['RPU', 'RISCV']:
            self._remote_cores[core] = RemoteCoreModel(**kwargs)
        
        self._disturbs = {
            'APU' : DisturbModel(),
            'RPU1' : DisturbModel(),
            'FPGA' : DisturbModel(),
        }
        
    # def setReacheability(self, reachable):
    #     self.


# In[6]:


class BoardController:

    class ShmIterator:

        def __init__(self, board, core, timeout_interval=1):
            channel = board._unsafe_connect().invoke_shell()
            channel.send(f'bash  /root/tests/test_omnivisor_guest/demo/read_shm.sh -c {core}; exit\n')
            self._buf = StupidBufferedReader(channel)
            self._timeout_callback = []
            self._valid_callback = []
            self._timeout_interval = timeout_interval
            
        def add_timeout_callback(self, callback):
            self._timeout_callback.append(callback)
            
        def add_valid_callback(self, callback):
            self._valid_callback.append(callback)

        def __iter__(self):
            return self

        def _try_next(self):
            if self._buf.ready():
                line = self._buf.readline()
                try:
                    value = int(line.strip())
                    return value
                except:
                    pass

            return None

        def __next__(self):
            beg = time.time()

            while time.time() - beg < self._timeout_interval:
                val = self._try_next()
                if val:
                    for fn in self._valid_callback:
                        fn()
                    return val
                time.sleep(.1)

            if self._buf.closed() and not self._buf.ready():
                raise StopIteration
            
            for fn in self._timeout_callback:
                fn()
            
            return None
        
        def close(self):
            self._buf.close()
            
    demo_path='/root/tests/test_omnivisor_guest/demo'

        
    def _get_shell(self):
        # Check ssh client
        if self._client and self._client.get_transport() is None or not self._client.get_transport().is_alive():
            self._client.close()
            self._shell.close()
            self._client = None
            self._shell = None
            
        if self._client is None:
            self._client = None
        
        if not self._shell is None and self._shell.closed:
            self._shell = None
        
    def _ssh_exec_command(self, command, conn=None, return_stdout=False, **kwargs):
        _opened = False
        if conn is None:
            if(self._debug):
                print('Opening connection')
            conn = self._unsafe_connect()
            _opened = True

        _, ssh_stdout, ssh_stderr = conn.exec_command(command)

        if not ssh_stdout.channel.recv_exit_status() == 0:
            raise(BoardRemoteExeception(''.join(ssh_stderr.readlines()), ''.join(ssh_stdout.readlines())))

        if self._debug or return_stdout:
            _stderr = ''.join(ssh_stderr.readlines())
            _stdout = ''.join(ssh_stdout.readlines())
            
        if self._debug:
            sys.stderr.write(_stderr)
            sys.stdout.write(_stdout)
            
        if _opened:
            if(self._debug):
                print('Closing connection')
            conn.close()

        if return_stdout:
            return _stdout

    def setup_board(self):
        command = f'''bash {BoardController.demo_path}/manage_demo.sh -b'''
        self._ssh_exec_command(command)
        
    def _unsafe_connect(self, **kwargs):
        ssh = paramiko.SSHClient()
        ssh.load_system_host_keys()
        ssh.connect(self._ip, username=self._username, password=self._password)
        return ssh

    def _unsafe_omivisor_toggle(self, state=None, spatial=False, **kwargs):
        if not state:
            raise BaseException(f"Omnivisor toggle state not provided")
        
        command_flag = {True: 'e', False: 'd'}[state]
        spatial_flag = '-s' if spatial else ''
        command = f'''bash {BoardController.demo_path}/manage_jailhouse.sh -{command_flag} {spatial_flag}'''
        self._ssh_exec_command(command, **kwargs)
        
    def _unsafe_temporale_toggle(self, state, bandwidth, **kwargs):
        command_flag = {True: f'-t {bandwidth}', False: '-T'}[state]
        command = f'''bash {BoardController.demo_path}/manage_jailhouse.sh {command_flag}'''
        # print(command)
        self._ssh_exec_command(command, **kwargs)

    def _unsafe_clear_shm(self, **kwargs):
        command=f'''bash {BoardController.demo_path}/clear_shm.sh'''
        self._ssh_exec_command(command, **kwargs)

    def _unsafe_manage_remote_core(self, core, desired_state, clear_shm=False, **kwargs):

        if not core == 'RPU' and not core == 'RISCV':
            raise BaseException(f"Remote core to load can be 'RPU' or 'RISCV', but found: {core}")

        if clear_shm:
            print('Clearing')
            self._unsafe_clear_shm()

        command_flag = {True: '-l', False: '-d'}[desired_state]

        command=f'''bash {BoardController.demo_path}/manage_remote_core.sh -c {core} {command_flag}'''
        self._ssh_exec_command(command, **kwargs)

    def _unsafe_toggle_disturb(self, disturb, desired_state, **kwargs):
        if not disturb == 'APU' and not disturb == 'RPU1' and not disturb == 'FPGA':
            raise BaseException(f"Available disturbs are APU, RPU1 and FPGA, but found: {disturb}")

        arg = {True: 'Enable', False: 'Disable'}[desired_state]

        command=f'''bash {BoardController.demo_path}/disturb_manager.sh -d {disturb} -a {arg}'''
        self._ssh_exec_command(command, **kwargs)
        
    def _unsafe_init(self, **kwargs):
        with self._unsafe_connect() as ssh:
            ssh.exec_command('uname')
            self._unsafe_omivisor_toggle(conn=ssh, state=True)

    def _try_run(self, to_call_func, **kwargs):
        try:
            return to_call_func(**kwargs)
        except BoardException as e:
            raise e
        except NoValidConnectionsError as e:
            if self._debug:
                print(traceback.format_exc())
                print(e)
        except Exception as e:
            if self._debug:
                print(type(e))
                print(e)
                print(traceback.format_exc())

    def __init__(self, ip='10.210.1.228', username='root', password='root', debug=False):

        self._debug=debug
        self._ip=ip
        self._username=username
        self._password=password
        
        
        self._client = None
        self._shell = None
        
        self._lock = threading.Lock()

        # self._try_run(self._unsafe_init)

    def toggle_omnivisor(self, state):
        self._try_run(self._unsafe_omivisor_toggle, state=state)

    def toggle_spatial_isolation(self, spatial):
        self._try_run(self._unsafe_omivisor_toggle, state=True, spatial=spatial)
        
    def toggle_temporal_isolation(self, temporal, bandwidth=None):
        self._try_run(self._unsafe_temporale_toggle, state=temporal, bandwidth=bandwidth)
        
    def set_temporal_bandwidth(self, bandwidth):
        self._try_run(self._unsafe_temporale_toggle, state=True, bandwidth=bandwidth)
        
    def get_shm_itr(self, core, **kwargs):
        itr = BoardController.ShmIterator(self, core=core, **kwargs)
        return itr

    def clear_shm(self):
        self._try_run(self._unsafe_clear_shm)

    def toggle_remote_core(self, core, desired_state):
        self._try_run(self._unsafe_manage_remote_core, core=core, desired_state=desired_state)

    def toggle_disturb(self, disturb, desired_state):
        self._try_run(self._unsafe_toggle_disturb, disturb=disturb, desired_state=desired_state)
    


# In[7]:


class BoardInterface:
    
    def __init__(self, ip='10.210.1.228', username='root', password='root', debug=False, **kwargs):
        self._model = BoardModel(**kwargs)
        self._controller = BoardController(ip=ip, username=username, password=password, debug=debug)
        self._lock = threading.Lock()
        
    def _call_controller_fn(self, fn_name, *args, **kwargs):
        with self._lock:
            try:
                return getattr(self._controller, fn_name)(*args, **kwargs)
            except AttributeError:
                raise BoardException(f"Function {fn_name} not found in controller")
            
    def setup_board(self):
        self._call_controller_fn('setup_board')
        
    def toggle_omnivisor(self, state):
        self._call_controller_fn('toggle_omnivisor', state)
        self._model._omnivisor.set_active(state)

    def toggle_spatial_isolation(self, spatial):
        active_cores = [core for core in self._model._remote_cores if self._model._remote_cores[core].is_active()]
        for core in active_cores:
            print(f'powering off active_core {core}')
            self._model._remote_cores[core].set_active(False)

        self._call_controller_fn('toggle_spatial_isolation', spatial)
        self._model._omnivisor.set_spatial_isolation(spatial)

        for core in active_cores:
            print(f'loading active_core {core}')
            self._model._remote_cores[core].set_active(True)
        
    def toggle_temporal_isolation(self, temporal):
        self._call_controller_fn('toggle_temporal_isolation', temporal, bandwidth=self._model._omnivisor.get_temporal_isolation_bandwidth())
        self._model._omnivisor.set_temporal_isolation(temporal)
        
    def set_temporal_bandwidth(self, bandwidth):
        self._call_controller_fn('set_temporal_bandwidth', bandwidth)
        self._model._omnivisor.set_temporal_isolation_bandwidth(bandwidth)

    def toggle_remote_core(self, core, state):
        self._call_controller_fn('toggle_remote_core', core, state)
        self._model._remote_cores[core].set_active(state)

    def toggle_disturb(self, disturb, state):
        self._call_controller_fn('toggle_disturb', disturb, state)

    def get_shm_itr(self, core, **kwargs):
        itr = self._call_controller_fn('get_shm_itr', core, **kwargs)
        itr.add_timeout_callback(self._model._remote_cores[core].increase_timeout_count)
        itr.add_valid_callback(self._model._remote_cores[core].reset_timeout_count)
        return itr

    def clear_shm(self):
        self._call_controller_fn('clear_shm')


