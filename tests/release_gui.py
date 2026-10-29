"""Target only the isolated release test PID; screenshot its client area."""
import ctypes as C, ctypes.wintypes as W, json, pathlib, sys, time
from PIL import ImageGrab

root = pathlib.Path(__file__).resolve().parents[1]
out = root/'.local_test/release/exe_qa'
out.mkdir(parents=True, exist_ok=True)
pid = int((root/'.local_test/release/exe_pid.txt').read_text(encoding='utf-8-sig'))
u = C.windll.user32
u.SetProcessDPIAware()
u.GetWindowThreadProcessId.argtypes = [W.HWND,C.POINTER(W.DWORD)]
u.GetClientRect.argtypes = [W.HWND,C.POINTER(W.RECT)]
u.ClientToScreen.argtypes = [W.HWND,C.POINTER(W.POINT)]
u.PostMessageW.argtypes = [W.HWND,W.UINT,W.WPARAM,W.LPARAM]
u.SetForegroundWindow.argtypes = [W.HWND]
u.ShowWindow.argtypes = [W.HWND,C.c_int]
windows = []
@C.WINFUNCTYPE(W.BOOL,W.HWND,W.LPARAM)
def visit(hwnd,_):
    owner = W.DWORD()
    u.GetWindowThreadProcessId(hwnd,C.byref(owner))
    name = C.create_unicode_buffer(256)
    u.GetWindowTextW(hwnd,name,256)
    if owner.value == pid and 'WordRogue' in name.value: windows.append(hwnd)
    return True
for attempt in range(30):
    windows.clear()
    u.EnumWindows(visit,0)
    if windows: break
    time.sleep(.2)
if len(windows) != 1: raise SystemExit('Expected exactly one release test game window: '+str(windows))
hwnd = windows[0]
u.ShowWindow(hwnd,9)
u.SetForegroundWindow(hwnd)
time.sleep(.3)

def rect():
    r = W.RECT()
    u.GetClientRect(hwnd,C.byref(r))
    p = W.POINT(0,0)
    u.ClientToScreen(hwnd,C.byref(p))
    return p.x,p.y,r.right,r.bottom

def shot(name):
    x,y,w,h = rect()
    ImageGrab.grab(bbox=(x,y,x+w,y+h),all_screens=True).save(out/(name+'.png'))
    print(name,w,h,flush=True)

def key(vk):
    scan = u.MapVirtualKeyW(vk,0)
    flags = 1 | (scan << 16)
    u.PostMessageW(hwnd,0x100,vk,flags)
    u.PostMessageW(hwnd,0x101,vk,flags | (3 << 30))
    time.sleep(.7)

def click(nx,ny):
    _,_,w,h=rect()
    x,y=int(nx*w),int(ny*h)
    packed=(y<<16)|x
    u.PostMessageW(hwnd,0x200,0,packed)
    u.PostMessageW(hwnd,0x201,1,packed)
    u.PostMessageW(hwnd,0x202,0,packed)
    time.sleep(.8)

mode = sys.argv[1] if len(sys.argv)>1 else 'start'
if mode == 'start':
    shot('01_title')
    click(.28,.69)
    shot('02_difficulty')
    key(0x0D) # Default recommended difficulty
    shot('03_map')
    key(0x0D) # Focused available entry node
    shot('04_battle')
elif mode == 'battle':
    click(.48,.435) # Guard spell
    click(.40,.65)  # A, settled exactly once
    time.sleep(1.6)
    shot('05_answer_result')
    key(0x1B)
    shot('06_pause')
    click(.50,.411)
    shot('07_settings')
elif mode == 'close':
    u.PostMessageW(hwnd,0x10,0,0)
elif mode == 'pause':
    click(.91,.12)
    shot('06_pause')
elif mode == 'settings':
    click(.50,.398)
    shot('07_settings')
else: raise SystemExit('Unknown mode')
(out/(mode+'_actions.json')).write_text(json.dumps({'pid':pid,'window':int(hwnd),'action':mode,'client_size':list(rect()[2:]),'verification':'External native GUI actions; screenshots must be visually checked.'},indent=2),encoding='utf-8')
