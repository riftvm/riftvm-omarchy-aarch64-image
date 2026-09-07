#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import tempfile

project = Path(__file__).resolve().parent.parent
inventory = json.loads((project / 'config/ezvm32-migration.json').read_text())
with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    for relative in inventory['paths'] + inventory['textFiles']:
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        if relative == 'mnt/ezvm-shared':
            path.mkdir(exist_ok=True)
        elif '.wants/' in relative:
            if not path.is_symlink():
                scope = 'user/' if '/user/' in relative else 'system/'
                path.symlink_to('/etc/systemd/' + scope + path.name)
        else:
            path.write_text('EZVM ezvm-agent ezvm-session-agent /mnt/ezvm-shared\n')
    subprocess.run(['python3', str(project / 'bin/migrate-ezvm32-root'), str(root)], check=True)
    assert (root / 'usr/local/sbin/rift-agent').exists()
    assert (root / 'usr/share/omarchy-aarch64/base-image-build.txt').read_text().startswith('EZVM')
    assert os.readlink(root / 'etc/systemd/system/multi-user.target.wants/rift-agent.service') == '/etc/systemd/system/rift-agent.service'
    assert not (root / 'usr/local/sbin/ezvm-agent').exists()
    assert (root / 'etc/systemd/system/mnt-riftvm\\x2dfolders.automount').exists()
    # A second pass must refuse this already migrated source.
    assert subprocess.run(['python3', str(project / 'bin/migrate-ezvm32-root'), str(root)], capture_output=True).returncode != 0
print('PASS: migration inventory, symlink targets, overlay, provenance and repeat rejection')
