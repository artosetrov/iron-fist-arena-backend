#!/usr/bin/env python3
"""
Re-key a generation whose "flat magenta" background came back as another flat colour
(the model sometimes paints a muted pink, e.g. #B3447C, that the chroma key in
ingest_generated_sprite.py does not recognise). Samples the border, keys by colour
distance, un-mixes the edges and writes the subject over pure #FF00FF so the normal
ingest can run on the result.

Usage: python3 scripts/key_sampled_background.py <raw.png> <out.png>
"""
import sys, numpy as np
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
a=np.asarray(Image.open(src).convert('RGB'),dtype=np.float64)/255
border=np.concatenate([a[:24].reshape(-1,3),a[-24:].reshape(-1,3),a[:,:24].reshape(-1,3),a[:,-24:].reshape(-1,3)])
bg=np.median(border,axis=0); spread=np.percentile(np.linalg.norm(border-bg,axis=1),99)
d=np.linalg.norm(a-bg,axis=2); t0=max(0.06,spread*1.5); t1=t0+0.14
al=np.clip((d-t0)/(t1-t0),0,1)[...,None]
fg=np.clip(np.where(al>0.001,(a-(1-al)*bg)/np.maximum(al,1e-3),a),0,1)
out=al*fg+(1-al)*np.array([1.0,0,1.0])
Image.fromarray((out*255+0.5).astype(np.uint8)).save(dst)
print(src.split('/')[-1],'bg',np.round(bg*255),'spread',round(spread,3))
