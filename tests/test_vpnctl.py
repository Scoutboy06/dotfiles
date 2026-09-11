"""Run with python -m unittest discover -s tests -p 'test_vpnctl.py'. No real VPN operations."""
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / 'dot_local/bin/executable_vpnctl'
loader = importlib.machinery.SourceFileLoader('vpnctl', str(SOURCE))
spec = importlib.util.spec_from_loader(loader.name, loader)
vpn = importlib.util.module_from_spec(spec)
loader.exec_module(vpn)


class RoutingTests(unittest.TestCase):
    def evaluate(self, profile, host):
        script = vpn.pac(profile, 1080) + '\nconsole.log(FindProxyForURL("https://" + process.argv[1], process.argv[1]));'
        return subprocess.check_output(['node', '-e', script, host], text=True).strip()

    def test_domain_boundaries_and_full_mode(self):
        p = {'splitTunneling': True, 'domains': ['internal.example'], 'routes': []}
        self.assertEqual(self.evaluate(p, 'a.internal.example'), 'SOCKS5 127.0.0.1:1080')
        self.assertEqual(self.evaluate(p, 'internal.example.evil.example'), 'DIRECT')
        self.assertEqual(self.evaluate(p, 'other.example'), 'DIRECT')
        self.assertEqual(self.evaluate({'splitTunneling': False}, 'other.example'), 'SOCKS5 127.0.0.1:1080')
        self.assertEqual(self.evaluate({'splitTunneling': False}, '127.0.0.1'), 'DIRECT')

    def test_empty_split_policy_fails(self):
        with self.assertRaises(ValueError):
            vpn.pac({'splitTunneling': True}, 1080)

    def test_remote_metadata_does_not_inject_javascript(self):
        p = {'splitTunneling': True, 'domains': ['x";throw new Error("oops")//'], 'routes': []}
        self.assertEqual(self.evaluate(p, 'other.example'), 'DIRECT')

    def test_status_and_profiles_are_offline_without_configuration(self):
        with tempfile.TemporaryDirectory() as d:
            env = dict(os.environ, XDG_STATE_HOME=d, XDG_RUNTIME_DIR=d + '/run', VPNCTL_CONFIG=d + '/missing')
            for command in ('status', 'profiles'):
                r = subprocess.run([sys.executable, str(SOURCE), command], env=env, text=True, capture_output=True)
                self.assertEqual(r.returncode, 0, r.stderr)
                self.assertEqual(json.loads(r.stdout), [] if command == 'profiles' else {'enabled': False, 'phase': 'off'})

    def test_restore_preserves_user_proxy_changes(self):
        with tempfile.TemporaryDirectory() as d, patch.object(vpn, 'STATE', Path(d)):
            vpn.write_json(Path(d) / 'proxy-backup.json', {'mode': "'manual'", 'url': "''", 'ownedUrl': "'our-url'"})
            with patch.object(vpn, 'gget', return_value="'user-url'"), patch.object(vpn, 'gset') as setter:
                vpn.restore_proxy()
                setter.assert_not_called()


MOCK_SSH = r'''#!/usr/bin/env python3
import json, os, pathlib, signal, socket, sys, time
p=pathlib.Path(os.environ['VPN_TEST'])
with (p/'calls').open('a') as f: f.write(json.dumps(sys.argv[1:])+'\n')
if '-D' in sys.argv:
 host,port=sys.argv[sys.argv.index('-D')+1].split(':')
 sock=socket.socket();sock.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1);sock.bind((host,int(port)));sock.listen()
 (p/'proxy-pid').write_text(str(os.getpid()))
 while True:
  c,_=sock.accept();c.close()
if (p/'offline').exists(): sys.exit(255)
s=json.loads((p/'remote.json').read_text())
if sys.argv[-1].startswith('cat '):
 s['updated']=str(time.time())
 print(json.dumps(s));sys.exit(0)
r=json.load(sys.stdin)
s.update(requestId=r['id'], enabled=r['enabled'], desiredId=r['profileId'], connectedIds=[r['profileId']] if r['enabled'] else [])
(p/'remote.json').write_text(json.dumps(s))
'''
MOCK_GSETTINGS = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
p=pathlib.Path(os.environ['VPN_TEST'])/'gsettings.json'
s=json.loads(p.read_text())
if sys.argv[1]=='get':print(s[sys.argv[3]])
else:s[sys.argv[3]]=sys.argv[4];p.write_text(json.dumps(s))
'''


class WorkerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.p = Path(self.temp.name)
        for name, content in [('ssh', MOCK_SSH), ('gsettings', MOCK_GSETTINGS)]:
            f=self.p/name; f.write_text(content); f.chmod(0o755)
        ports=[]
        for _ in range(2):
            with socket.socket() as s:
                s.bind(('127.0.0.1', 0)); ports.append(s.getsockname()[1])
        self.ports=ports
        (self.p/'config.json').write_text(json.dumps({'host':'mock-host','directory':"/remote/user's directory",'socksPort':ports[0],'pacPort':ports[1]}))
        self.original={'mode':"'none'",'autoconfig-url':"'previous-url'"}
        (self.p/'gsettings.json').write_text(json.dumps(self.original))
        (self.p/'remote.json').write_text(json.dumps({'version':2,'enabled':False,'connectedIds':[], 'profiles':[
            {'id':'user:a','name':'VPN A','splitTunneling':True,'domains':['internal.example'],'routes':[]},
            {'id':'user:b','name':'VPN B','splitTunneling':False,'domains':[],'routes':[]}]}))
        self.env=dict(os.environ,VPN_TEST=str(self.p),VPNCTL_CONFIG=str(self.p/'config.json'),XDG_STATE_HOME=str(self.p/'state'),XDG_RUNTIME_DIR=str(self.p/'run'),PATH=str(self.p)+':'+os.environ['PATH'])
        self.log=(self.p/'log').open('w')
        self.worker=None

    def tearDown(self):
        if self.worker and self.worker.poll() is None:
            self.worker.terminate(); self.worker.wait(timeout=20)
        self.log.close()
        self.temp.cleanup()

    def start(self):
        self.worker=subprocess.Popen([sys.executable,str(SOURCE),'worker'],env=self.env,stdout=self.log,stderr=self.log)

    def state(self):
        return vpn.read_json(self.p/'run/vpnctl/status.json',{})

    def until(self, predicate):
        deadline=time.monotonic()+15
        while time.monotonic()<deadline:
            s=self.state()
            if predicate(s):return s
            time.sleep(.1)
        self.fail(str(self.state())+'\n'+(self.p/'log').read_text())

    def assert_stopped(self):
        self.assertFalse(self.state()['enabled'])
        self.assertEqual(json.loads((self.p/'gsettings.json').read_text()),self.original)
        before=(self.p/'calls').read_text()
        time.sleep(.3)
        self.assertEqual((self.p/'calls').read_text(),before)
        for port in self.ports:
            with socket.socket() as s:self.assertNotEqual(s.connect_ex(('127.0.0.1',port)),0)

    def test_enable_switch_disable_restores_proxy_and_stops_everything(self):
        self.start(); self.until(lambda s:s.get('phase')=='connected')
        self.assertEqual(json.loads((self.p/'gsettings.json').read_text())['mode'],"'auto'")
        subprocess.run([sys.executable,str(SOURCE),'select','user:b'],env=self.env,check=True)
        self.until(lambda s:s.get('phase')=='connected' and s.get('selectedId')=='user:b')
        self.worker.terminate();self.worker.wait(timeout=20)
        self.assert_stopped()
        self.assertFalse(json.loads((self.p/'remote.json').read_text())['enabled'])

    def test_occupied_socks_port_reports_an_error(self):
        with socket.socket() as listener:
            listener.bind(('127.0.0.1',self.ports[0]));listener.listen()
            self.start()
            state=self.until(lambda s:s.get('phase')=='error')
            self.assertIn('SOCKS port is already in use',state['error'])

    def test_unreachable_host_does_not_prevent_local_disable(self):
        self.start();self.until(lambda s:s.get('phase')=='connected')
        (self.p/'offline').touch()
        self.worker.terminate();self.worker.wait(timeout=20)
        self.assert_stopped()
        self.assertIn('disconnect could not be confirmed',self.state()['error'])

    def test_old_host_exits_without_proxy_or_mutation(self):
        (self.p/'remote.json').write_text(json.dumps({'version':1}))
        self.start();self.worker.wait(timeout=10)
        self.assert_stopped()
        self.assertIn('Update the Windows agent',self.state()['error'])
        self.assertEqual(len((self.p/'calls').read_text().splitlines()),1)


if __name__=='__main__':unittest.main()
