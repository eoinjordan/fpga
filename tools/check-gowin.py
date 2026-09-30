"""Check checked-in Gowin manifests and elaborate the board top modules."""
from pathlib import Path
import json
import os
import re
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def executable(name):
    found = shutil.which(name)
    bundled = Path.home() / 'oss-cad-suite/bin' / (name + '.exe')
    if found:
        return found
    if bundled.exists():
        os.environ['PATH'] = str(bundled.parent) + os.pathsep + str(bundled.parent.parent / 'lib') + os.pathsep + os.environ.get('PATH', '')
        return str(bundled)
    raise SystemExit(f'{name} is required: activate the OSS CAD Suite first.')


def main():
    iverilog = executable('iverilog')
    ivl = Path(iverilog).resolve().parents[1] / 'lib/ivl'
    compiler = [iverilog] + (['-B', str(ivl)] if ivl.is_dir() else [])
    prefixes = [Path(iverilog).resolve().parents[1], Path('/usr')]
    yosys = shutil.which('yosys')
    if yosys:
        prefixes.insert(0, Path(yosys).resolve().parents[1])
    candidates = [p / 'share/yosys/gowin/cells_sim.v' for p in prefixes]
    cells = Path(os.environ['GOWIN_SIM_CELLS']) if 'GOWIN_SIM_CELLS' in os.environ else next(
        (p for p in candidates if p.exists()), candidates[0])
    if not cells.exists():
        raise SystemExit('Set GOWIN_SIM_CELLS to Yosys gowin/cells_sim.v')
    projects = sorted(ROOT.glob('0*/gowin/tangnano20k.gprj'))
    assert len(projects) == 8, f'Expected eight hardware projects, found {len(projects)}'
    with tempfile.TemporaryDirectory() as tmp:
        # Yosys supplies rPLL, OSER10 and TLVDS_OBUF declarations but no CLKDIV.
        # This blackbox checks connectivity only, not video clock behavior.
        stub = Path(tmp) / 'clkdiv.v'
        stub.write_text('''module CLKDIV(input HCLKIN, RESETN, CALIB, output CLKOUT);
parameter DIV_MODE="5", GSREN="false";
endmodule\n''')
        for project in projects:
            directory = project.parent
            xml = ET.parse(project).getroot()
            device = xml.find('Device')
            assert device.attrib == {'name': 'GW2AR-18C', 'pn': 'GW2AR-LV18QN88C8/I7'}
            assert device.text == 'gw2ar18c-000'
            sources = []
            for item in xml.findall('FileList/File'):
                path = directory / item.attrib['path']
                assert path.is_file(), f'Missing {path}'
                assert 'vendor/' not in item.attrib['path']
                assert '/tb/' not in item.attrib['path']
                if item.attrib['type'] == 'file.verilog':
                    sources.append(str(path))
            config = json.loads((directory / 'impl/project_process_config.json').read_text())
            assert config['TopModule'] == 'tangnano20k_top'
            rtl = (directory / 'tangnano20k_top.v').read_text()
            header = rtl.split(');', 1)[0]
            ports = set()
            for declaration in re.findall(r'(?:input|output)\s+wire\s+(.*?)(?=,\s*(?:input|output)|$)', header, re.S):
                width = re.match(r'\[(\d+):(\d+)\]\s*(.*)', declaration)
                if width:
                    hi, lo, names = int(width[1]), int(width[2]), width[3]
                else:
                    hi = lo = None
                    names = declaration
                # Next direction on the same line starts a separate declaration.
                names = re.split(r',\s*(?:input|output)', names)[0]
                for name in names.rstrip(',').split(','):
                    name = name.strip()
                    if hi is None: ports.add(name)
                    else: ports.update(f'{name}[{bit}]' for bit in range(lo, hi+1))
            cst = (directory / 'tangnano20k.cst').read_text()
            constrained = set(re.findall(r'IO_LOC "([^"]+)"', cst))
            for positive in list(constrained):
                if '_p' in positive: constrained.add(positive.replace('_p', '_n'))
            assert ports == constrained, f'{project}: port/CST mismatch {ports ^ constrained}'
            pins = re.findall(r'IO_LOC "[^"]+" ([\d,]+);', cst)
            all_pins = [p for pair in pins for p in pair.split(',')]
            assert len(all_pins) == len(set(all_pins)), 'Duplicate physical pins'
            assert 'period 37.037' in (directory / 'tangnano20k.sdc').read_text()
            if 'simple_soc' in rtl:
                fw = directory / 'firmware.hex'
                assert fw.is_file() and len(fw.read_text().splitlines()) == 68
            subprocess.run([*compiler, '-g2012', '-s', 'tangnano20k_top',
                '-o', str(Path(tmp) / 'top.vvp'), str(cells), str(stub), *sources],
                cwd=directory, check=True)
            print('PASS manifest, constraints, elaboration:', project.relative_to(ROOT))
    print('Video primitives are blackboxes here; Gowin P&R and hardware remain unverified.')


if __name__ == '__main__':
    main()
