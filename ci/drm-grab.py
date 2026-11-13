#!/usr/bin/env python3
"""Capture l'image réellement affichée par KWin (backend DRM) : lit le framebuffer de scanout d'un CRTC actif.
Usage : drm-grab.py /dev/dri/cardN sortie.png   (root requis ; buffers « dumb » de Mesa llvmpipe / kms_swrast)."""
import ctypes, ctypes.util, fcntl, mmap, os, subprocess, sys

dev, out = sys.argv[1], sys.argv[2]
lib = ctypes.CDLL(ctypes.util.find_library("drm") or "libdrm.so.2")
U32 = ctypes.c_uint32

class ModeRes(ctypes.Structure):
    _fields_ = [("count_fbs", ctypes.c_int), ("fbs", ctypes.POINTER(U32)), ("count_crtcs", ctypes.c_int), ("crtcs", ctypes.POINTER(U32)),
                ("count_connectors", ctypes.c_int), ("connectors", ctypes.POINTER(U32)), ("count_encoders", ctypes.c_int),
                ("encoders", ctypes.POINTER(U32)), ("min_width", U32), ("max_width", U32), ("min_height", U32), ("max_height", U32)]

class ModeInfo(ctypes.Structure):
    _fields_ = [("clock", U32), ("hdisplay", ctypes.c_uint16), ("hsync_start", ctypes.c_uint16), ("hsync_end", ctypes.c_uint16),
                ("htotal", ctypes.c_uint16), ("hskew", ctypes.c_uint16), ("vdisplay", ctypes.c_uint16), ("vsync_start", ctypes.c_uint16),
                ("vsync_end", ctypes.c_uint16), ("vtotal", ctypes.c_uint16), ("vscan", ctypes.c_uint16), ("vrefresh", U32),
                ("flags", U32), ("type", U32), ("name", ctypes.c_char * 32)]

class Crtc(ctypes.Structure):
    _fields_ = [("crtc_id", U32), ("buffer_id", U32), ("x", U32), ("y", U32), ("width", U32), ("height", U32),
                ("mode_valid", ctypes.c_int), ("mode", ModeInfo), ("gamma_size", ctypes.c_int)]

class Fb(ctypes.Structure):
    _fields_ = [("fb_id", U32), ("width", U32), ("height", U32), ("pitch", U32), ("bpp", U32), ("depth", U32), ("handle", U32)]

class MapDumb(ctypes.Structure):
    _fields_ = [("handle", U32), ("pad", U32), ("offset", ctypes.c_uint64)]

lib.drmModeGetResources.restype = ctypes.POINTER(ModeRes)
lib.drmModeGetCrtc.restype = ctypes.POINTER(Crtc)
lib.drmModeGetFB.restype = ctypes.POINTER(Fb)
DRM_IOCTL_MODE_MAP_DUMB = 0xC01064B3

fd = os.open(dev, os.O_RDWR)
res = lib.drmModeGetResources(fd)
if not res:
    sys.exit("drmModeGetResources a échoué")
fb = None
for i in range(res.contents.count_crtcs):
    c = lib.drmModeGetCrtc(fd, res.contents.crtcs[i])
    if c and c.contents.buffer_id:
        f = lib.drmModeGetFB(fd, c.contents.buffer_id)
        if f:
            fb = f.contents
            print(f"crtc {c.contents.crtc_id} fb {fb.fb_id} {fb.width}x{fb.height} pitch {fb.pitch} bpp {fb.bpp} depth {fb.depth} handle {fb.handle}")
            break
if fb is None:
    sys.exit("aucun CRTC actif avec framebuffer")
m = MapDumb(fb.handle, 0, 0)
fcntl.ioctl(fd, DRM_IOCTL_MODE_MAP_DUMB, m)
size = fb.pitch * fb.height
mm = mmap.mmap(fd, size, mmap.MAP_SHARED, mmap.PROT_READ, offset=m.offset)
raw = bytearray()
row = fb.width * 4
for y in range(fb.height):
    raw += mm[y * fb.pitch : y * fb.pitch + row]
fmt = "bgra" if fb.bpp == 32 else "bgr"
subprocess.run(["convert", "-size", f"{fb.width}x{fb.height}", "-depth", "8", f"{fmt}:-", "-alpha", "off", out], input=bytes(raw), check=True)
print("écrit", out, os.path.getsize(out), "octets")
