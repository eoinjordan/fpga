"""Run the existing core regression and Tang Nano board integration tests."""
from pathlib import Path
import subprocess
import tempfile
import argparse
import sys
import importlib.util
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('gowin_check', ROOT / 'tools/check-gowin.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
iv = helper.executable('iverilog')
vvp = Path(helper.executable('vvp')).as_posix()
ivl = Path(iv).resolve().parents[1] / 'lib/ivl'
compiler = [iv] + (['-B', str(ivl)] if ivl.is_dir() else [])
runtime = [vvp] + (['-M-', '-M', str(ivl)] if ivl.is_dir() else [])
parser = argparse.ArgumentParser()
parser.add_argument('--board-only', action='store_true')
args = parser.parse_args()
subprocess.run([sys.executable, str(ROOT / '02-golden-models/python/gen_vectors.py')], check=True)
subprocess.run([sys.executable, str(ROOT / '06-riscv-soc/firmware/build_firmware.py')], check=True)
sources = [str(p) for p in ROOT.glob('0*/rtl/*.v')]
sources.append(str(ROOT / '06-riscv-soc/third_party/picorv32.v'))

with tempfile.TemporaryDirectory() as tmp:
    def simulate(tb, rtl, cwd):
        output = str(Path(tmp) / (tb.stem + '.vvp'))
        subprocess.run([*compiler, '-g2012', '-s', tb.stem, '-o', output, str(tb), *rtl], check=True)
        result = subprocess.run([*runtime, output.replace('\\', '/')], cwd=cwd, text=True, capture_output=True)
        print(result.stdout.strip())
        if result.returncode:
            print(result.stderr.strip())
            result.check_returncode()
        assert 'PASS' in result.stdout and 'FAIL' not in result.stdout, tb

    if not args.board_only:
        for tb in sorted(ROOT.glob('0*/tb/*.v')):
            simulate(tb, sources, tb.parent.parent)
    simulate(ROOT / 'boards/tangnano20k/tb/tb_board_uart.v',
             [str(ROOT / 'boards/tangnano20k/rtl/board_uart.v')], ROOT)
    for stage in ['05-input-audio', '06-riscv-soc', '07-semnpu']:
        directory = ROOT / stage / 'gowin'
        xml = ET.parse(directory / 'tangnano20k.gprj')
        rtl = [str(directory / f.attrib['path']) for f in xml.findall('FileList/File')
               if f.attrib['type'] == 'file.verilog']
        test = 'tb_board_audio.v' if stage == '05-input-audio' else 'tb_board_demo.v'
        simulate(ROOT / 'boards/tangnano20k/tb' / test, rtl, directory)
