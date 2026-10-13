"""Package source only; never ship compiler caches or machine-local profile data."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root=Path(__file__).resolve().parents[1]
target=root.parent/'DeadFrequency-Source.yyz'
excluded={'build','Windows','Windows-v4','.cache','.temp','__pycache__','screenshots'}
with ZipFile(target,'w',ZIP_DEFLATED) as z:
    for p in root.rglob('*'):
        rel=p.relative_to(root)
        if p.is_file() and not any(part in excluded for part in rel.parts) and p.suffix not in ('.log','.local'):
            z.write(p,rel.as_posix())
print(target)
