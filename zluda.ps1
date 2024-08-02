Set-ExecutionPolicy Bypass -Scope Process
$filepath = ".\cuda_malloc.py"

# Stara funkcja do zamiany
$old_function = @"
def cuda_malloc_supported():
    try:
        names = get_gpu_names()
    except:
        names = set()
    for x in names:
        if "NVIDIA" in x:
            for b in blacklist:
                if b in x:
                    return False
    return True
"@

# Nowa funkcja
$new_function = @"
def cuda_malloc_supported():
    try:
        names = get_gpu_names()
    except:
        names = set()
    for x in names:
        if "AMD" in x:
            return False
        elif "NVIDIA" in x:
            for b in blacklist:
                if b in x:
                    return False
    return False
#We don't need malloc at all with amd gpu's. So disabling all together
"@

(Get-Content -Raw -Path $filepath) -replace [regex]::Escape($old_function), $new_function | Set-Content -Path $filepath


$filepath2 = ".\comfy\model_management.py"

# Stara funkcja do zamiany
$old_function2 = @"
def get_torch_device_name(device):
    if hasattr(device, 'type'):
        if device.type == "cuda":
            try:
                allocator_backend = torch.cuda.get_allocator_backend()
            except:
                allocator_backend = ""
            return "{} {} : {}".format(device, torch.cuda.get_device_name(device), allocator_backend)
        else:
            return "{}".format(device.type)
    elif is_intel_xpu():
        return "{} {}".format(device, torch.xpu.get_device_name(device))
    else:
        return "CUDA {}: {}".format(device, torch.cuda.get_device_name(device))

try:
    logging.info("Device: {}".format(get_torch_device_name(get_torch_device())))
except:
    logging.warning("Could not pick default device.")
"@

# Nowa funkcja
$new_function2 = @"
def get_torch_device_name(device):
    if hasattr(device, 'type'):
        if device.type == "cuda":
            try:
                allocator_backend = torch.cuda.get_allocator_backend()
            except:
                allocator_backend = ""
            return "{} {} : {}".format(device, torch.cuda.get_device_name(device), allocator_backend)
        else:
            return "{}".format(device.type)
    elif is_intel_xpu():
        return "{} {}".format(device, torch.xpu.get_device_name(device))
    else:
        return "CUDA {}: {}".format(device, torch.cuda.get_device_name(device))

try:
    torch_device_name = get_torch_device_name(get_torch_device())

    if "[ZLUDA]" in torch_device_name:
        print("***--------------------------------ZLUDA------------------------------------***")
        print("Detected ZLUDA, support for it is experimental and comfy may not work properly.")

        if torch.backends.cudnn.enabled:
            torch.backends.cudnn.enabled = False
            print("Disabling cuDNN because ZLUDA does currently not support it.")

        torch.backends.cuda.enable_flash_sdp(False)
        print("Disabling flash because ZLUDA does currently not support it.")
        torch.backends.cuda.enable_math_sdp(True)
        print("Enabling math_sdp.")
        torch.backends.cuda.enable_mem_efficient_sdp(False)
        print("Disabling mem_efficient_sdp because ZLUDA does currently not support it.")
        print("***-------------------------------------------------------------------------***")

    print("Device:", torch_device_name)
except:
    print("Could not pick default device.")
"@

(Get-Content -Raw -Path $filepath2) -replace [regex]::Escape($old_function2), $new_function2 | Set-Content -Path $filepath2
Read-Host -Prompt "ZLUDA is patched, press ENTER to close this window, now run ComfyUI via start.bat"