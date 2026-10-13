"""Prepare credited CC0 recordings; raw files are kept outside shipped packages."""
from pathlib import Path
import soundfile as sf
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT.parent/'.tools/audio'
OUT=ROOT/'datafiles'
def convert(name,path,seconds,peak=.78,shot=False):
    samples,sr=sf.read(str(path),always_2d=True);samples=samples.mean(axis=1)
    # Find the first meaningful transient, preserve 5 ms of pre-roll.
    active=np.flatnonzero(np.abs(samples)>max(.008,np.max(np.abs(samples))*.08))
    start=max(0,int(active[0])-int(sr*.005)) if len(active) else 0
    samples=samples[start:start+int(sr*seconds)]
    samples=np.interp(np.arange(int(len(samples)*22050/sr))*sr/22050,np.arange(len(samples)),samples)
    samples=np.convolve(samples,[.16,.68,.16],mode='same')
    samples-=np.mean(samples)
    if shot:
        # Retain the recorded transient, gently compress peaks and add a short room tail.
        samples=np.tanh(samples*2)
        dry=samples.copy()
        for delay,gain in [(int(.029*22050),.08),(int(.057*22050),.045)]:samples[delay:]+=dry[:-delay]*gain
    fade=min(len(samples),800);samples[-fade:]*=np.linspace(1,0,fade)
    samples[:60]*=np.linspace(0,1,min(60,len(samples)))
    samples*=peak/max(.001,np.max(np.abs(samples)))
    sf.write(str(OUT/(name+'.wav')),samples,22050,subtype='PCM_16')
    print(name,round(len(samples)/22050,3), 'sec')
guns=SRC/'firearms/Prepared SFX Library'
convert('shot',guns/'Walther PPQ/X_31P.wav',.65,shot=True)
convert('smg',guns/'Carl Gustav M45/G_20P.wav',.30,.68,True)
convert('shotgun',guns/'Mossberg/N_26P.wav',.9,.86,True)
convert('reload',SRC/'reload.wav',.65,.65)
impact=SRC/'impact/Audio'
convert('door',impact/'impactWood_medium_001.ogg',.35,.60)
convert('slam',impact/'impactWood_heavy_001.ogg',.5,.72)
convert('glass',impact/'impactGlass_heavy_000.ogg',1.2,.72)
convert('hit',impact/'impactPunch_heavy_000.ogg',.4,.74)
for i in range(3):convert('footstep'+str(i+1),impact/f'footstep_concrete_00{i}.ogg',.3,.5)
